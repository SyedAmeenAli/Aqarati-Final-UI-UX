import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/aq/aq_auth_scaffold.dart';
import '../../../core/aq/aq_forms.dart';
import '../../../core/aq/aq_primitives.dart';
import '../../../core/aq/aq_scene.dart';
import '../../../core/aq/aq_tokens.dart';
import '../../../core/aq/aq_typography.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/localization/flow_strings.dart';
import '../state/signup_state.dart' show isValidEmail;

/// a••••@example.com
String maskEmail(String email) {
  final at = email.indexOf('@');
  if (at <= 0) return email;
  return '${email[0]}••••${email.substring(at)}';
}

enum EmailPhase { sending, sent, verified, failed }

/// Firebase email verification, as a calm stateful surface (not a heavy flow).
/// Reached from Account active; it never blocks the journey.
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});
  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  static const _cooldown = 30; // display pacing only
  EmailPhase _phase = EmailPhase.sending;
  String? _email;
  String? _note;
  bool _checking = false;
  int _left = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _email = await ref.read(authRepositoryProvider).currentEmail();
    if (mounted) setState(() {});
    await _send();
  }

  void _startCooldown() {
    _timer?.cancel();
    _left = _cooldown;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _left = _left - 1);
      if (_left <= 0) t.cancel();
    });
  }

  Future<void> _send() async {
    setState(() {
      _phase = EmailPhase.sending;
      _note = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      if (!mounted) return;
      setState(() => _phase = EmailPhase.sent);
      _startCooldown();
    } catch (_) {
      if (mounted) setState(() => _phase = EmailPhase.failed);
    }
  }

  Future<void> _check() async {
    if (_checking) return;
    final f = FlowStrings.of(context);
    setState(() {
      _checking = true;
      _note = null;
    });
    try {
      final ok = await ref.read(authRepositoryProvider).isEmailVerified();
      if (!mounted) return;
      if (ok) AQHaptics.success();
      setState(() {
        _phase = ok ? EmailPhase.verified : EmailPhase.sent;
        _note = ok ? null : f.t('ev.notYet');
      });
    } catch (_) {
      if (mounted) setState(() => _note = f.t('ev.failure'));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _change() async {
    final updated = await showAQSheet<String>(context, builder: (_) => const _ChangeEmailSheet());
    if (updated != null && mounted) {
      setState(() {
        _email = updated;
        _phase = EmailPhase.sent;
        _note = null;
      });
      _startCooldown();
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final verified = _phase == EmailPhase.verified;
    final sending = _phase == EmailPhase.sending;
    return AQAuthScaffold(
      showLogo: false,
      centered: true,
      onBack: () => aqBack(context, '/account/active'),
      backLabel: f.t('common.back'),
      title: verified ? f.t('ev.verified') : f.t('ev.title'),
      subtitle: verified ? f.t('ev.verifiedBody') : f.t('ev.sub'),
      bottom: verified
          ? AQPrimaryButton(label: f.t('ev.continue'), onPressed: () => aqBack(context, '/account/active'))
          : Column(mainAxisSize: MainAxisSize.min, children: [
              AQPrimaryButton(label: f.t('ev.check'), loading: _checking, trailingChevron: false, onPressed: sending ? null : _check),
              const SizedBox(height: AQSpacing.x1),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                AQTextButton(label: _left > 0 ? f.t('ev.resendIn', {'s': '$_left'}) : f.t('ev.resend'), color: _left > 0 ? c.inkFaint : c.accent, onPressed: (_left > 0 || sending) ? null : _send),
                AQTextButton(label: f.t('ev.change'), color: c.accent, onPressed: sending ? null : _change),
              ]),
            ]),
      children: [
        const SizedBox(height: AQSpacing.x4),
        if (verified) const AQAnimatedCheck(size: 96) else Icon(Icons.mail_outline_rounded, size: 64, color: c.accent),
        const SizedBox(height: AQSpacing.x5),
        if (!verified && _email != null) ...[
          Text(f.t('ev.sentTo'), style: AQTypography.of(context, AQText.bodyMedium, soft: true)),
          const SizedBox(height: 2),
          Directionality(textDirection: TextDirection.ltr, child: Text(maskEmail(_email!), style: AQTypography.of(context, AQText.titleLarge))),
          const SizedBox(height: AQSpacing.x5),
        ],
        if (_phase == EmailPhase.failed) AQErrorBanner(text: f.t('ev.failure'), action: AQTextButton(label: f.t('common.retry'), color: c.accent, onPressed: _send)),
        if (_note != null) AQErrorBanner(tone: AQBannerTone.info, text: _note!),
      ],
    );
  }
}

class _ChangeEmailSheet extends ConsumerStatefulWidget {
  const _ChangeEmailSheet();
  @override
  ConsumerState<_ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends ConsumerState<_ChangeEmailSheet> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final f = FlowStrings.of(context);
    final v = _email.text.trim();
    if (!isValidEmail(v)) {
      setState(() => _err = f.t('err.email'));
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await ref.read(authRepositoryProvider).updateEmail(v);
      if (mounted) Navigator.of(context).pop(v);
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _err = f.t('ev.failure');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AQSpacing.x6, AQSpacing.x2, AQSpacing.x6, AQSpacing.x2),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(header: true, child: Text(f.t('ev.changeTitle'), style: AQTypography.of(context, AQText.headlineMedium))),
        const SizedBox(height: AQSpacing.x4),
        AQTextField(label: f.t('field.email'), controller: _email, keyboardType: TextInputType.emailAddress, autofill: const [AutofillHints.email], valid: isValidEmail(_email.text), error: _err, action: TextInputAction.done, onChanged: (_) => setState(() => _err = null), onSubmitted: (_) => _save()),
        AQPrimaryButton(label: f.t('ev.update'), loading: _busy, trailingChevron: false, onPressed: _save),
      ]),
    );
  }
}
