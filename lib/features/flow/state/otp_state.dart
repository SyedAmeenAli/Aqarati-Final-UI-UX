import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/api/account_api.dart';

/// notSent -> sending -> sent (code entered) -> verifying -> verified;
/// invalid / expired / rateLimited / error are recoverable.
enum OtpPhase { notSent, sending, sent, verifying, verified, invalid, expired, rateLimited, error }

class OtpState {
  final OtpPhase phase;
  /// Seconds until a new code may be requested. Seeded by the SERVER cooldown
  /// (or Retry-After); the local timer only counts it down for display.
  final int cooldown;
  final DateTime? expiresAt;
  final String? errorKey;
  const OtpState({this.phase = OtpPhase.notSent, this.cooldown = 0, this.expiresAt, this.errorKey});

  bool get canResend => cooldown == 0 && phase != OtpPhase.sending && phase != OtpPhase.verifying && phase != OtpPhase.verified;
  bool get canType => phase == OtpPhase.sent || phase == OtpPhase.invalid || phase == OtpPhase.error;

  OtpState copyWith({OtpPhase? phase, int? cooldown, DateTime? expiresAt, String? errorKey, bool clearError = false}) => OtpState(
        phase: phase ?? this.phase,
        cooldown: cooldown ?? this.cooldown,
        expiresAt: expiresAt ?? this.expiresAt,
        errorKey: clearError ? null : (errorKey ?? this.errorKey),
      );
}

class OtpController extends StateNotifier<OtpState> {
  final AccountApi api;
  Timer? _timer;
  OtpController(this.api) : super(const OtpState());

  void _tick(int seconds) {
    _timer?.cancel();
    state = state.copyWith(cooldown: seconds);
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      final left = state.cooldown - 1;
      if (left <= 0) t.cancel();
      state = state.copyWith(cooldown: left < 0 ? 0 : left);
    });
  }

  Future<void> send() async {
    if (!state.canResend && state.phase != OtpPhase.notSent) return;
    state = state.copyWith(phase: OtpPhase.sending, clearError: true);
    try {
      final issued = await api.startPhoneVerification();
      if (!mounted) return;
      state = state.copyWith(phase: OtpPhase.sent, expiresAt: issued.expiresAt, clearError: true);
      _tick(issued.cooldownSeconds);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == ApiErrorCode.rateLimited || e.code == ApiErrorCode.otpLimitReached) {
        state = state.copyWith(phase: OtpPhase.rateLimited, errorKey: 'otp.rateLimited');
        _tick(e.retryAfterSeconds ?? 30);
      } else {
        state = state.copyWith(phase: OtpPhase.error, errorKey: e.code == ApiErrorCode.network ? 'common.networkError' : 'otp.error');
      }
    } catch (_) {
      if (mounted) state = state.copyWith(phase: OtpPhase.error, errorKey: 'otp.error');
    }
  }

  Future<void> verify(String code) async {
    if (state.phase == OtpPhase.verifying || state.phase == OtpPhase.verified) return;
    state = state.copyWith(phase: OtpPhase.verifying, clearError: true);
    try {
      final r = await api.verifyPhone(code);
      if (!mounted) return;
      state = switch (r) {
        OtpVerifyResult.verified => state.copyWith(phase: OtpPhase.verified),
        OtpVerifyResult.invalid => state.copyWith(phase: OtpPhase.invalid, errorKey: 'otp.invalid'),
        OtpVerifyResult.expired => state.copyWith(phase: OtpPhase.expired, errorKey: 'otp.expired'),
        OtpVerifyResult.rateLimited => state.copyWith(phase: OtpPhase.rateLimited, errorKey: 'otp.rateLimited'),
        OtpVerifyResult.serverError => state.copyWith(phase: OtpPhase.error, errorKey: 'otp.error'),
      };
    } on ApiException catch (e) {
      if (mounted) state = state.copyWith(phase: OtpPhase.error, errorKey: e.code == ApiErrorCode.network ? 'common.networkError' : 'otp.error');
    } catch (_) {
      if (mounted) state = state.copyWith(phase: OtpPhase.error, errorKey: 'otp.error');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final otpControllerProvider = StateNotifierProvider.autoDispose<OtpController, OtpState>((ref) => OtpController(ref.read(accountApiProvider)));
