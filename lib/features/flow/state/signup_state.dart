import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/domain/account_models.dart';
import '../../../data/api/account_api.dart';
import '../../entry/models/signup_purpose.dart';

/// Architecture password policy: at least 8 characters, one uppercase letter,
/// one number; NO special-character requirement. Firebase stays the authority.
const int kMinPasswordLength = 8;

bool passwordMeetsPolicy(String p) => p.length >= kMinPasswordLength && RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'\d').hasMatch(p);

enum SignupStep { you, contact, business, account }

List<SignupStep> stepsFor(RoleFormConfig cfg) => [SignupStep.you, SignupStep.contact, if (cfg.hasBusinessStep) SignupStep.business, SignupStep.account];

class SignupState {
  final SignupFormValues values;
  final int stepIndex;
  /// field -> localization key (with optional args handled by the screen)
  final Map<String, String> errors;
  final bool submitting;
  final String? bannerKey;
  final bool loaded;
  const SignupState({this.values = const SignupFormValues(), this.stepIndex = 0, this.errors = const {}, this.submitting = false, this.bannerKey, this.loaded = false});

  SignupState copyWith({SignupFormValues? values, int? stepIndex, Map<String, String>? errors, bool? submitting, String? bannerKey, bool clearBanner = false, bool? loaded}) => SignupState(
        values: values ?? this.values,
        stepIndex: stepIndex ?? this.stepIndex,
        errors: errors ?? this.errors,
        submitting: submitting ?? this.submitting,
        bannerKey: clearBanner ? null : (bannerKey ?? this.bannerKey),
        loaded: loaded ?? this.loaded,
      );
}

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
// Oman mobile numbers: 8 digits starting 7 or 9 (landlines 2 are not valid for SMS OTP).
final _omanMobileRe = RegExp(r'^[79]\d{7}$');

bool isValidOmanMobile(String v) => _omanMobileRe.hasMatch(v.replaceAll(' ', ''));
bool isValidEmail(String v) => _emailRe.hasMatch(v.trim());

/// Pure validation so it can be unit-tested.
Map<String, String> validateStep(RoleFormConfig cfg, SignupStep step, SignupFormValues v, {String password = '', String confirm = ''}) {
  final e = <String, String>{};
  switch (step) {
    case SignupStep.you:
      if (v.firstName.trim().isEmpty) e['firstName'] = 'common.required';
      if (v.lastName.trim().isEmpty) e['lastName'] = 'common.required';
    case SignupStep.contact:
      if (!isValidOmanMobile(v.phone)) e['phone'] = 'err.phone';
      if (!isValidEmail(v.email)) e['email'] = 'err.email';
    case SignupStep.business:
      if (cfg.hasBusinessName && v.businessName.trim().isEmpty) e['businessName'] = 'common.required';
      if (cfg.hasAgencyName && v.agencyName.trim().isEmpty) e['agencyName'] = 'common.required';
      if (cfg.hasServiceType && v.serviceType == null) e['serviceType'] = 'common.required';
    case SignupStep.account:
      if (!passwordMeetsPolicy(password)) e['password'] = 'err.passwordRules';
      if (confirm != password || confirm.isEmpty) e['confirm'] = 'err.passwordMismatch';
      if (!v.consent) e['consent'] = 'err.consent';
  }
  return e;
}

/// Local draft of ORDINARY field values only. Never passwords, never documents.
class SignupDraftStore {
  static String _key(SignupPurpose p) => 'signupDraft.${p.name}';

  Future<({SignupFormValues values, int step})?> load(SignupPurpose p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(p));
      if (raw == null) return null;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return (values: SignupFormValues.fromJson(j['values'] as Map<String, dynamic>), step: j['step'] as int? ?? 0);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(SignupPurpose p, SignupFormValues v, int step) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(p), jsonEncode({'values': v.toJson(), 'step': step}));
    } catch (_) {}
  }

  Future<void> clear(SignupPurpose p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(p));
    } catch (_) {}
  }
}

final signupDraftStoreProvider = Provider<SignupDraftStore>((ref) => SignupDraftStore());

class SignupController extends StateNotifier<SignupState> {
  final Ref ref;
  final SignupPurpose purpose;
  RoleFormConfig get cfg => roleConfigs[purpose]!;

  SignupController(this.ref, this.purpose) : super(const SignupState()) {
    _load();
  }

  Future<void> _load() async {
    final d = await ref.read(signupDraftStoreProvider).load(purpose);
    if (!mounted) return;
    final steps = stepsFor(cfg);
    state = state.copyWith(values: d?.values, stepIndex: (d?.step ?? 0).clamp(0, steps.length - 1), loaded: true);
  }

  void update(SignupFormValues v) {
    state = state.copyWith(values: v, errors: const {}, clearBanner: true);
    ref.read(signupDraftStoreProvider).save(purpose, v, state.stepIndex);
  }

  SignupStep get step => stepsFor(cfg)[state.stepIndex];
  bool get isLast => state.stepIndex == stepsFor(cfg).length - 1;

  bool next({String password = '', String confirm = ''}) {
    final errs = validateStep(cfg, step, state.values, password: password, confirm: confirm);
    if (errs.isNotEmpty) {
      state = state.copyWith(errors: errs);
      return false;
    }
    if (!isLast) {
      state = state.copyWith(stepIndex: state.stepIndex + 1, errors: const {}, clearBanner: true);
      ref.read(signupDraftStoreProvider).save(purpose, state.values, state.stepIndex);
    }
    return true;
  }

  /// Jump to a step (used by recovery surfaces, e.g. "Use another email").
  void goToStep(SignupStep target) {
    final i = stepsFor(cfg).indexOf(target);
    if (i >= 0) state = state.copyWith(stepIndex: i, errors: const {}, clearBanner: true);
  }

  bool back() {
    if (state.stepIndex == 0) return false;
    state = state.copyWith(stepIndex: state.stepIndex - 1, errors: const {}, clearBanner: true);
    return true;
  }

  /// Firebase user first, then POST /auth/sign-up with the form fields.
  /// Returns true when the account is created (otp_pending). On failure the
  /// form state is kept so nothing has to be re-entered.
  Future<bool> submit({required String password, required String confirm}) async {
    final errs = validateStep(cfg, SignupStep.account, state.values, password: password, confirm: confirm);
    if (errs.isNotEmpty) {
      state = state.copyWith(errors: errs);
      return false;
    }
    state = state.copyWith(submitting: true, clearBanner: true, errors: const {});
    try {
      await ref.read(authRepositoryProvider).createUserWithEmail(state.values.email.trim(), password);
      await ref.read(accountApiProvider).signUp(purpose, state.values);
      await ref.read(signupDraftStoreProvider).clear(purpose);
      if (mounted) state = state.copyWith(submitting: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(submitting: false, bannerKey: switch (e.error) { AuthError.weakPassword => 'signup.validation', AuthError.network => 'common.networkError', AuthError.unavailable => 'login.unavailable', _ => 'signup.conflict' });
    } on ApiException catch (e) {
      state = state.copyWith(submitting: false, bannerKey: switch (e.code) { ApiErrorCode.conflict => 'signup.conflict', ApiErrorCode.validationFailed => 'signup.validation', ApiErrorCode.network => 'common.networkError', _ => 'common.genericError' });
    } catch (_) {
      state = state.copyWith(submitting: false, bannerKey: 'common.genericError');
    }
    return false;
  }
}

final signupControllerProvider = StateNotifierProvider.autoDispose.family<SignupController, SignupState, SignupPurpose>((ref, p) => SignupController(ref, p));
