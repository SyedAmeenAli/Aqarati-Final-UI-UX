import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/aq/aq_auth_scaffold.dart';
import '../../../core/aq/aq_documents.dart';
import '../../../core/aq/aq_forms.dart';
import '../../../core/aq/aq_primitives.dart';
import '../../../core/aq/aq_tokens.dart';
import '../../../core/aq/aq_typography.dart';
import '../../../core/domain/account_models.dart';
import '../../../core/localization/flow_strings.dart';
import '../../../core/config/backend_mode.dart';
import '../../../data/api/account_api.dart';
import '../../../data/demo/demo_backend.dart';
import '../state/document_state.dart';
import '../widgets/document_upload_tile.dart';
import '../widgets/flow_common.dart';

/// Role-specific explanation of why and what we verify, before any upload.
class VerificationIntroScreen extends ConsumerWidget {
  const VerificationIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final me = ref.watch(meProvider);
    return me.when(
      loading: () => aqLoadingFrame(context, title: f.t('vintro.title')),
      error: (_, _) => aqErrorFrame(context, ref, title: f.t('vintro.title'), onRetry: () => ref.invalidate(meProvider)),
      data: (m) {
        final cfg = m.purpose == null ? null : roleConfigs[m.purpose];
        if (cfg == null || !cfg.needsDocuments) {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/app/home'));
          return const SizedBox.shrink();
        }
        Widget bullet(String key) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 2), child: AQIcon('check', size: AQIconSize.small, color: c.accent)),
                const SizedBox(width: AQSpacing.x3),
                Expanded(child: Text(f.t(key), style: AQTypography.of(context, AQText.bodyMedium))),
              ]),
            );
        return AQAuthScaffold(
          title: f.t('vintro.title'),
          subtitle: '${roleTitle(context, m.purpose!)} · ${f.t('vintro.sub')}',
          onBack: () => context.go('/account/active'),
          backLabel: f.t('common.back'),
          bottom: AQPrimaryButton(label: f.t('vintro.cta'), onPressed: () => context.go('/onboarding/documents')),
          children: [
            AQReviewSection(title: f.t('vintro.why.title'), children: [Padding(padding: const EdgeInsets.only(top: AQSpacing.x2), child: Text(f.t('vintro.why.body'), style: AQTypography.of(context, AQText.bodyMedium, soft: true)))]),
            AQReviewSection(title: f.t('vintro.what.title'), children: [const SizedBox(height: 4), for (final k in ['vintro.what.1', 'vintro.what.2', 'vintro.what.3', 'vintro.what.4']) bullet(k)]),
            AQReviewSection(
              title: f.t('vintro.yours'),
              children: [
                const SizedBox(height: 4),
                for (final d in cfg.documents) bullet(documentLabelKey(d)),
                if (cfg.fourEyes) Padding(padding: const EdgeInsets.only(top: AQSpacing.x3), child: Text(f.t('docs.fourEyes'), style: AQTypography.of(context, AQText.bodySmall, soft: true))),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Initial package: one independent tile per required document.
class DocumentOnboardingScreen extends ConsumerWidget {
  const DocumentOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final me = ref.watch(meProvider);
    final ver = ref.watch(verificationProvider);
    return me.when(
      loading: () => aqLoadingFrame(context, title: f.t('docs.title')),
      error: (_, _) => aqErrorFrame(context, ref, title: f.t('docs.title'), onRetry: () => ref.invalidate(meProvider)),
      data: (m) {
        final cfg = m.purpose == null ? null : roleConfigs[m.purpose];
        if (cfg == null || !cfg.needsDocuments) {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/app/home'));
          return const SizedBox.shrink();
        }
        final server = {for (final d in ver.valueOrNull?.documents ?? const <DocumentStatus>[]) d.kind: d};
        final allDone = cfg.documents.every((k) => ref.watch(documentControllerProvider(k)).phase == DocPhase.success);
        final anyBusy = cfg.documents.any((k) => ref.watch(documentControllerProvider(k)).busy);
        return AQAuthScaffold(
          showLogo: false,
          title: f.t('docs.title'),
          subtitle: f.t('docs.sub'),
          onBack: () => aqBackTo(context, '/onboarding/verification-intro'),
          backLabel: f.t('common.back'),
          bottom: Column(mainAxisSize: MainAxisSize.min, children: [
            if (!allDone) Padding(padding: const EdgeInsets.only(bottom: AQSpacing.x2), child: Text(f.t('review.incomplete'), style: AQTypography.of(context, AQText.bodySmall, color: AQColors.of(context).inkFaint))),
            AQPrimaryButton(label: f.t('docs.review'), onPressed: allDone && !anyBusy ? () => context.go('/onboarding/review') : null),
          ]),
          children: [
            if (cfg.fourEyes) AQErrorBanner(tone: AQBannerTone.info, text: f.t('docs.fourEyes')),
            if (kShowReviewTools && ref.read(accountApiProvider) is DemoAccountApi)
              AQTextButton(
                label: 'DEMO: mark all documents received',
                onPressed: () {
                  (ref.read(accountApiProvider) as DemoAccountApi).demoAttachAll();
                  ref.invalidate(verificationProvider);
                  context.go('/onboarding/review');
                },
              ),
            for (final k in cfg.documents) DocumentUploadTile(key: ValueKey(k), kind: k, seed: initialFromStatus(server[k])),
          ],
        );
      },
    );
  }
}

void aqBackTo(BuildContext context, String route) => context.go(route);

/// Everything in one place before submitting. Each section can be corrected.
class ApplicationReviewScreen extends ConsumerStatefulWidget {
  const ApplicationReviewScreen({super.key});
  @override
  ConsumerState<ApplicationReviewScreen> createState() => _ApplicationReviewScreenState();
}

class _ApplicationReviewScreenState extends ConsumerState<ApplicationReviewScreen> {
  bool _submitting = false;
  String? _bannerKey;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _bannerKey = null;
    });
    try {
      await ref.read(accountApiProvider).submitVerification();
      ref.invalidate(meProvider);
      ref.invalidate(verificationProvider);
      AQHaptics.success();
      if (mounted) context.go('/onboarding/submitted');
    } catch (e) {
      if (mounted) setState(() => _bannerKey = apiErrorKey(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final ver = ref.watch(verificationProvider);
    return ver.when(
      loading: () => aqLoadingFrame(context, title: f.t('review.title')),
      error: (_, _) => aqErrorFrame(context, ref, title: f.t('review.title'), onRetry: () => ref.invalidate(verificationProvider)),
      data: (v) {
        final complete = v.documents.every((d) => d.outcome != DocumentOutcome.notSubmitted);
        return AQAuthScaffold(
          showLogo: false,
          title: f.t('review.title'),
          subtitle: f.t('review.sub'),
          onBack: () => context.go('/onboarding/documents'),
          backLabel: f.t('common.back'),
          bottom: Column(mainAxisSize: MainAxisSize.min, children: [
            if (_bannerKey != null) AQErrorBanner(text: f.t(_bannerKey!)),
            AQPrimaryButton(label: f.t('review.submit'), loading: _submitting, onPressed: complete ? _submit : null),
          ]),
          children: [
            AQReviewSection(title: f.t('review.business'), children: [
              if (v.businessName != null) AQKeyValue(f.t('review.name'), v.businessName!),
              AQKeyValue(f.t('review.role'), roleTitle(context, v.purpose)),
            ]),
            AQReviewSection(
              title: f.t('review.documents'),
              editLabel: f.t('review.edit'),
              onEdit: () => context.go('/onboarding/documents'),
              children: [for (final d in v.documents) AQDocumentRow(title: f.t(documentLabelKey(d.kind)), status: d)],
            ),
            AQReviewSection(title: f.t('review.consent'), children: [Padding(padding: const EdgeInsets.only(top: AQSpacing.x2), child: Text(f.t('review.consentBody'), style: AQTypography.of(context, AQText.bodySmall, soft: true)))]),
          ],
        );
      },
    );
  }
}

/// Submission is never approval: this screen says "submitted for verification".
class ApplicationSubmittedScreen extends ConsumerWidget {
  const ApplicationSubmittedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final ref0 = ref.watch(verificationProvider).valueOrNull?.reference;
    return AQAuthScaffold(
      showLogo: false,
      centered: true,
      title: f.t('submitted.title'),
      subtitle: f.t('submitted.body'),
      onBack: () => context.go('/verification'),
      backLabel: f.t('common.back'),
      bottom: AQPrimaryButton(label: f.t('submitted.cta'), onPressed: () => context.go('/verification')),
      children: [
        const SizedBox(height: AQSpacing.x6),
        const AQAnimatedCheck(size: 104),
        if (ref0 != null) ...[const SizedBox(height: AQSpacing.x6), Text('${f.t('submitted.ref')}: $ref0', style: AQTypography.of(context, AQText.labelMedium, soft: true))],
      ],
    );
  }
}
