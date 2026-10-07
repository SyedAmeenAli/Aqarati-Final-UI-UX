import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/aq/aq_auth_scaffold.dart';
import '../../../core/aq/aq_forms.dart';
import '../../../core/aq/aq_primitives.dart';
import '../../../core/aq/aq_scene.dart';
import '../../../core/aq/aq_tokens.dart';
import '../../../core/aq/aq_typography.dart';
import '../../../core/domain/account_models.dart';
import '../../../core/localization/flow_strings.dart';
import '../../entry/models/signup_purpose.dart';
import '../state/signup_state.dart';

/// ONE form for all six public sign-up paths, driven by [RoleFormConfig].
/// Built only from AQ system components.
class SignupFormScreen extends ConsumerStatefulWidget {
  final SignupPurpose purpose;
  const SignupFormScreen({super.key, required this.purpose});
  @override
  ConsumerState<SignupFormScreen> createState() => _SignupFormScreenState();
}

class _SignupFormScreenState extends ConsumerState<SignupFormScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _business = TextEditingController();
  final _agency = TextEditingController();
  // Passwords live only in these controllers: never in state, drafts or logs.
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _seeded = false;

  RoleFormConfig get cfg => roleConfigs[widget.purpose]!;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _email, _business, _agency, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  void _seed(SignupFormValues v) {
    _seeded = true;
    _first.text = v.firstName;
    _last.text = v.lastName;
    _phone.text = v.phone;
    _email.text = v.email;
    _business.text = v.businessName;
    _agency.text = v.agencyName;
  }

  void _push() {
    final ctl = ref.read(signupControllerProvider(widget.purpose).notifier);
    ctl.update(ref.read(signupControllerProvider(widget.purpose)).values.copyWith(
          firstName: _first.text,
          lastName: _last.text,
          phone: _phone.text.replaceAll(' ', ''),
          email: _email.text,
          businessName: _business.text,
          agencyName: _agency.text,
        ));
  }

  Future<void> _primary() async {
    final ctl = ref.read(signupControllerProvider(widget.purpose).notifier);
    FocusScope.of(context).unfocus();
    if (ctl.isLast) {
      final ok = await ctl.submit(password: _password.text, confirm: _confirm.text);
      if (ok && mounted) context.go('/otp');
    } else {
      ctl.next();
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final st = ref.watch(signupControllerProvider(widget.purpose));
    final ctl = ref.read(signupControllerProvider(widget.purpose).notifier);
    if (st.loaded && !_seeded) _seed(st.values);
    final c = AQColors.of(context);

    if (!st.loaded) {
      return AQAuthScaffold(
        title: f.t('signup.t.${widget.purpose.name}'),
        children: [Center(child: Semantics(label: f.t('common.loading'), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: c.accent))))],
      );
    }

    final steps = stepsFor(cfg);
    final step = steps[st.stepIndex];
    String? err(String field) => st.errors[field] == null ? null : f.t(st.errors[field]!);
    final stepName = switch (step) { SignupStep.you => 'signup.stepYou', SignupStep.business => 'signup.stepBusiness', SignupStep.account => 'signup.stepAccount' };

    final Widget body;
    switch (step) {
      case SignupStep.you:
        body = Column(children: [
          AQTextField(label: f.t('field.firstName'), controller: _first, autofill: const [AutofillHints.givenName], error: err('firstName'), onChanged: (_) => _push()),
          AQTextField(label: f.t('field.lastName'), controller: _last, autofill: const [AutofillHints.familyName], error: err('lastName'), onChanged: (_) => _push()),
          AQPhoneField(label: f.t('field.phone'), hint: f.t('field.phoneHint'), controller: _phone, error: err('phone'), onChanged: (_) => _push()),
          AQTextField(label: f.t('field.email'), controller: _email, keyboardType: TextInputType.emailAddress, autofill: const [AutofillHints.email], error: err('email'), action: TextInputAction.done, onChanged: (_) => _push()),
        ]);
      case SignupStep.business:
        body = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (cfg.hasAgencyName) AQTextField(label: f.t('field.agencyName'), controller: _agency, error: err('agencyName'), onChanged: (_) => _push()),
          if (cfg.hasBusinessName) AQTextField(label: f.t('field.businessName'), controller: _business, error: err('businessName'), onChanged: (_) => _push()),
          if (cfg.hasServiceType)
            AQSegmented<InteriorExteriorServiceType>(
              label: f.t('field.serviceType'),
              selected: st.values.serviceType,
              error: err('serviceType'),
              options: [for (final t in InteriorExteriorServiceType.values) (value: t, label: f.t('service.${t.name}'))],
              onChanged: (v) => ctl.update(st.values.copyWith(serviceType: v)),
            ),
          if (cfg.needsDocuments) AQErrorBanner(tone: AQBannerTone.info, text: f.t('signup.docsLater')),
        ]);
      case SignupStep.account:
        body = ListenableBuilder(
          listenable: _password,
          builder: (context, _) {
            final p = _password.text;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AQPasswordField(label: f.t('field.password'), controller: _password, showLabel: f.t('field.show'), hideLabel: f.t('field.hide'), newPassword: true, error: err('password')),
              AQRequirementList(items: [
                (label: f.t('pw.req.length'), met: p.length >= kMinPasswordLength),
                (label: f.t('pw.req.upper'), met: RegExp(r'[A-Z]').hasMatch(p)),
                (label: f.t('pw.req.number'), met: RegExp(r'\d').hasMatch(p)),
              ]),
              AQPasswordField(label: f.t('field.confirmPassword'), controller: _confirm, showLabel: f.t('field.show'), hideLabel: f.t('field.hide'), action: TextInputAction.done, error: err('confirm')),
              AQCheckRow(value: st.values.consent, label: f.t('signup.consent'), error: err('consent'), onChanged: (v) => ctl.update(st.values.copyWith(consent: v))),
              AQErrorBanner(tone: AQBannerTone.info, text: cfg.needsDocuments ? f.t('signup.docsLater') : f.t('signup.noDocs')),
            ]);
          },
        );
    }

    return AQAuthScaffold(
      title: f.t('signup.t.${widget.purpose.name}'),
      onBack: () {
        if (!ctl.back()) aqBack(context, '/onboarding/purpose');
      },
      backLabel: f.t('common.back'),
      progress: AQProgressStepper(step: st.stepIndex + 1, total: steps.length, label: '${f.t('signup.step', {'a': '${st.stepIndex + 1}', 'b': '${steps.length}'})} · ${f.t(stepName)}'),
      children: [body],
      bottom: Column(mainAxisSize: MainAxisSize.min, children: [
        if (st.bannerKey != null) AQErrorBanner(text: f.t(st.bannerKey!)),
        AQPrimaryButton(label: ctl.isLast ? f.t('signup.create') : f.t('common.next'), loading: st.submitting, onPressed: _primary),
        const SizedBox(height: AQSpacing.x2),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          AQIcon('lock', size: AQIconSize.small, color: c.inkFaint),
          const SizedBox(width: AQSpacing.x2),
          Flexible(child: Text(f.t('signup.draftSaved'), textAlign: TextAlign.center, style: AQTypography.of(context, AQText.bodySmall, color: c.inkFaint).copyWith(fontSize: 11.5))),
        ]),
      ]),
    );
  }
}
