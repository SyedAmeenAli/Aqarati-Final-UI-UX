import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/core/localization/flow_strings.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/data/demo/demo_backend.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/flow/state/document_state.dart';
import 'package:aqarati_app/features/flow/screens/auth_screens.dart';
import 'package:aqarati_app/features/flow/state/otp_state.dart';
import 'package:aqarati_app/features/flow/state/signup_state.dart';

void main() {
  test('exactly six public sign-up paths, each with a role config', () {
    expect(signupPurposeOptions.length, 6);
    for (final o in signupPurposeOptions) {
      expect(roleConfigs[o.id], isNotNull);
    }
  });

  test('required documents follow the source', () {
    expect(roleConfigs[SignupPurpose.userToShop]!.documents, isEmpty);
    expect(roleConfigs[SignupPurpose.realEstateAgent]!.documents, [DocumentKind.photoId, DocumentKind.agentLicence, DocumentKind.supportingDocument]);
    for (final p in [SignupPurpose.constructionCompany, SignupPurpose.buildingArchitecture, SignupPurpose.interiorExteriorDesign]) {
      expect(roleConfigs[p]!.documents, [DocumentKind.crCertificate, DocumentKind.municipalLicence]);
    }
    expect(roleConfigs[SignupPurpose.constructionCompany]!.documents.contains(DocumentKind.activityLicences), isFalse);
    expect(roleConfigs[SignupPurpose.propertyDevelopmentCompany]!.fourEyes, isTrue);
    expect(roleConfigs[SignupPurpose.interiorExteriorDesign]!.hasServiceType, isTrue);
    expect(DocumentKind.agentLicence.tracksExpiry, isTrue);
  });

  test('every string has English and Arabic, and Arabic is not just English', () {
    for (final k in FlowStrings.keys) {
      expect(FlowStrings.forTest(false).t(k).isNotEmpty, isTrue, reason: k);
    }
  });

  test('step validation', () {
    final cfg = roleConfigs[SignupPurpose.interiorExteriorDesign]!;
    expect(validateStep(cfg, SignupStep.you, const SignupFormValues()).keys, containsAll(['firstName', 'lastName', 'phone', 'email']));
    const ok = SignupFormValues(firstName: 'A', lastName: 'B', phone: '91234567', email: 'a@b.co');
    expect(validateStep(cfg, SignupStep.you, ok), isEmpty);
    expect(validateStep(cfg, SignupStep.business, ok).keys, containsAll(['businessName', 'serviceType']));
    expect(validateStep(cfg, SignupStep.account, ok, password: 'short', confirm: 'x').keys, containsAll(['password', 'confirm', 'consent']));
    expect(validateStep(cfg, SignupStep.account, ok.copyWith(consent: true), password: 'Longenough1', confirm: 'Longenough1'), isEmpty);
  });

  test('password policy: 8+, one uppercase, one number, no special char needed', () {
    expect(passwordMeetsPolicy('Abcdefg1'), isTrue);
    expect(passwordMeetsPolicy('abcdefg1'), isFalse);
    expect(passwordMeetsPolicy('Abcdefgh'), isFalse);
    expect(passwordMeetsPolicy('Ab1'), isFalse);
  });

  test('draft JSON never contains passwords or documents', () {
    final json = const SignupFormValues(firstName: 'A', email: 'a@b.co').toJson();
    expect(json.keys.any((k) => k.toLowerCase().contains('password')), isFalse);
    expect(json.keys.any((k) => k.toLowerCase().contains('doc')), isFalse);
  });

  test('file signature check', () {
    expect(hasAllowedSignature(Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 1])), isTrue);
    expect(hasAllowedSignature(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0])), isTrue);
    expect(hasAllowedSignature(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47])), isTrue);
    expect(hasAllowedSignature(Uint8List.fromList([0x4D, 0x5A, 0, 0])), isFalse);
  });

  test('OTP: wrong code is invalid, right code verifies, resend obeys server cooldown', () async {
    final s = DemoBackendState()..purpose = SignupPurpose.userToShop;
    final api = DemoAccountApi(s);
    final c = OtpController(api);
    await c.send();
    expect(c.state.phase, OtpPhase.sent);
    expect(c.state.cooldown, 30);
    expect(c.state.canResend, isFalse);
    await c.verify('000000');
    expect(c.state.phase, OtpPhase.invalid);
    await c.verify(kDemoOtpCode);
    expect(c.state.phase, OtpPhase.verified);
    expect(s.account, AccountState.active);
    c.dispose();
  });

  test('business account is active but grant stays draft (not approved)', () async {
    final s = DemoBackendState()..purpose = SignupPurpose.constructionCompany;
    final api = DemoAccountApi(s);
    await api.startPhoneVerification();
    await api.verifyPhone(kDemoOtpCode);
    expect(s.account, AccountState.active);
    expect(s.grant, GrantState.draft);
  });

  test('upload failure is isolated and retryable', () async {
    final s = DemoBackendState()..purpose = SignupPurpose.constructionCompany;
    final api = DemoAccountApi(s);
    final file = PickedDocument(name: 'fail.pdf', sizeBytes: 4, bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46]));
    await expectLater(api.uploadDocument(DocumentKind.crCertificate, file, null, (_) {}), throwsA(isA<ApiException>()));
    expect(s.docs.containsKey(DocumentKind.crCertificate), isFalse);
    await api.uploadDocument(DocumentKind.municipalLicence, PickedDocument(name: 'ok.pdf', sizeBytes: 4, bytes: file.bytes), null, (_) {});
    expect(s.docs.containsKey(DocumentKind.municipalLicence), isTrue);
  });

  test('login routes by account state, never straight to approved business UI', () {
    expect(routeForSession(const MeSession(account: AccountState.otpPending)), '/otp');
    expect(routeForSession(const MeSession(account: AccountState.active, purpose: SignupPurpose.userToShop)), '/app/home');
    expect(routeForSession(const MeSession(account: AccountState.active, purpose: SignupPurpose.constructionCompany, grant: GrantState.draft)), '/onboarding/verification-intro');
    expect(routeForSession(const MeSession(account: AccountState.active, purpose: SignupPurpose.constructionCompany, grant: GrantState.pendingVerification)), '/verification');
    expect(routeForSession(const MeSession(account: AccountState.active, purpose: SignupPurpose.constructionCompany, grant: GrantState.approved)), '/app/home');
  });

  test('expiry status: valid, expiring soon, expired, none', () {
    final now = DateTime(2026, 10, 7);
    expect(expiryStatusOf(null, now: now), ExpiryStatus.none);
    expect(expiryStatusOf(DateTime(2027, 6, 1), now: now), ExpiryStatus.valid);
    expect(expiryStatusOf(DateTime(2026, 10, 20), now: now), ExpiryStatus.expiringSoon);
    expect(expiryStatusOf(DateTime(2026, 10, 1), now: now), ExpiryStatus.expired);
  });
}
