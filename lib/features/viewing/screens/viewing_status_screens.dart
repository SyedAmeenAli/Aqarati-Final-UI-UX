import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/aq/aq_forms.dart';
import '../../../core/aq/aq_primitives.dart';
import '../../../core/aq/aq_scene.dart';
import '../../../core/aq/aq_tokens.dart';
import '../../../core/aq/aq_typography.dart';
import '../../../core/config/backend_mode.dart';
import '../../../core/localization/viewing_strings.dart';
import '../../../data/models/property.dart';
import '../data/viewing_repository.dart';
import '../domain/viewing_models.dart';
import '../domain/viewing_presentation.dart';
import '../widgets/viewing_components.dart';
import '../widgets/viewing_format.dart';
import '../widgets/viewing_scaffold.dart';
import 'viewing_kit.dart';

typedef ViewingBuilder = Widget Function(BuildContext context, WidgetRef ref, Viewing viewing, AsyncValue<Property?> property);

/// Loads one viewing (and its property). If [leaf] is given and the viewing's
/// current state belongs to a different moment screen, replaces the route so a
/// stale deep link never shows the wrong status.
class ViewingLoader extends ConsumerWidget {
  final String id;
  final String? leaf;
  final String? title;
  final VoidCallback? onBack;
  final ViewingBuilder builder;
  const ViewingLoader({super.key, required this.id, this.leaf, this.title, this.onBack, required this.builder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(viewingProvider(id));
    return async.when(
      loading: () => viewingLoadingFrame(context, title: title, onBack: onBack),
      error: (_, _) => viewingErrorFrame(context, title: title, onBack: onBack, onRetry: () => ref.invalidate(viewingProvider(id))),
      data: (v) {
        if (v == null) return viewingErrorFrame(context, title: title, onBack: onBack, onRetry: () {}, notFound: true);
        if (leaf != null) {
          final path = ViewingPresentation.momentPath(v);
          if (!path.endsWith('/$leaf')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.go(path);
            });
            return viewingLoadingFrame(context, title: title, onBack: onBack);
          }
        }
        return builder(context, ref, v, ref.watch(viewingPropertyProvider(v.propertyId)));
      },
    );
  }
}

Widget _summary(AsyncValue<Property?> property, {AQViewingDensity density = AQViewingDensity.medium, String? badge}) => property.when(
      loading: () => AQViewingSkeleton(height: density == AQViewingDensity.compact ? 96 : 150),
      error: (_, _) => const SizedBox.shrink(),
      data: (p) => p == null ? const SizedBox.shrink() : AQViewingPropertySummary(property: p, density: density, badge: badge),
    );

Widget _placeNote(BuildContext context, AsyncValue<Property?> property, String noteKey) {
  final v = ViewingStrings.of(context);
  final p = property.valueOrNull;
  return AQViewingLocationCard(place: p?.locationLabel.split(',').take(2).join(',').trim() ?? '', note: v.t(noteKey));
}

/// Simulated host, available only in review builds (REVIEW_TOOLS).
class AQDemoHostControls extends ConsumerWidget {
  final Viewing viewing;
  const AQDemoHostControls({super.key, required this.viewing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kShowReviewTools) return const SizedBox.shrink();
    final repo = ref.watch(viewingRepositoryProvider);
    if (repo is! DemoViewingRepository) return const SizedBox.shrink();
    final v = ViewingStrings.of(context);
    final c = AQColors.of(context);
    void apply(Viewing Function() f) {
      final next = f();
      ref.invalidate(viewingsProvider);
      ref.invalidate(viewingProvider(viewing.id));
      context.go(ViewingPresentation.momentPath(next));
    }

    final options = <(String, VoidCallback)>[
      if (viewing.status == ViewingStatus.requested) (v.t('vw.demo.confirm'), () => apply(() => repo.hostConfirm(viewing.id))),
      if (viewing.status == ViewingStatus.requested) (v.t('vw.demo.decline'), () => apply(() => repo.hostDecline(viewing.id))),
      if (viewing.isActive && viewing.suggestions.isEmpty) (v.t('vw.demo.suggest'), () => apply(() => repo.hostSuggest(viewing.id))),
      if (viewing.status == ViewingStatus.confirmed) (v.t('vw.demo.complete'), () => apply(() => repo.hostComplete(viewing.id))),
    ];
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AQSpacing.x5),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: c.hairline), borderRadius: BorderRadius.circular(AQRadius.medium)),
        child: Padding(
          padding: const EdgeInsets.all(AQSpacing.x3),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(v.t('vw.demo.title'), style: AQTypography.of(context, AQText.labelSmall, color: c.inkFaint)),
            const SizedBox(height: AQSpacing.x2),
            for (final o in options) Padding(padding: const EdgeInsets.only(bottom: AQSpacing.x2), child: AQSecondaryButton(label: o.$1, compact: true, trailingChevron: false, onPressed: o.$2)),
          ]),
        ),
      ),
    );
  }
}

/// Screen 42: the request is safely in motion; the host has not decided.
class ViewingRequestedScreen extends StatelessWidget {
  final String id;
  const ViewingRequestedScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final v = ViewingStrings.of(context);
    return ViewingLoader(
      id: id,
      leaf: 'requested',
      title: v.t('vw.requested.title'),
      onBack: () => context.go('/app/activity'),
      builder: (context, ref, viewing, property) {
        final pres = ViewingPresentation.of(viewing);
        return AQViewingScaffold(
          emotional: true,
          washImage: property.valueOrNull?.imageUrls.firstOrNull,
          hero: const AQConfirmationState(icon: 'send', tone: AQTone.pending),
          title: v.t('vw.requested.title'),
          subtitle: v.t('vw.requested.sub'),
          backLabel: v.t('vw.back'),
          onBack: () => context.go('/app/activity'),
          bottom: AQBottomActionBar(
            stack: true,
            primary: AQPrimaryButton(label: v.t('vw.viewMy'), onPressed: () => context.go('/app/activity')),
            secondary: AQBarSecondaryButton(label: v.t('vw.backToProperty'), onPressed: () => context.go('/property/${viewing.propertyId}')),
          ),
          children: [
            _summary(property, density: AQViewingDensity.compact),
            const SizedBox(height: AQSpacing.x3),
            AQViewingDetailCard(slot: viewing.slot, showType: false, trailing: Align(alignment: AlignmentDirectional.centerEnd, child: AQViewingStatus(presentation: pres, dense: true))),
            const SizedBox(height: AQSpacing.x3),
            AQViewingHostCard(host: viewing.host),
            AQViewingSectionTitle(v.t('vw.timeline')),
            AQSurface(padding: const EdgeInsets.symmetric(horizontal: AQSpacing.x3, vertical: AQSpacing.x4), child: AQViewingTimeline(current: pres.stage ?? ViewingStage.underReview)),
            const SizedBox(height: AQSpacing.x4),
            AQNoticeCard(icon: 'info', title: v.t('vw.next'), body: v.t('vw.next.requested')),
            AQDemoHostControls(viewing: viewing),
          ],
        );
      },
    );
  }
}

/// Screen 43: the appointment is real.
class ViewingConfirmedScreen extends StatelessWidget {
  final String id;
  const ViewingConfirmedScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final v = ViewingStrings.of(context);
    return ViewingLoader(
      id: id,
      leaf: 'confirmed',
      title: v.t('vw.confirmed.title'),
      onBack: () => aqBack(context, '/app/activity'),
      builder: (context, ref, viewing, property) {
        final pres = ViewingPresentation.of(viewing);
        return AQViewingScaffold(
          emotional: true,
          washImage: property.valueOrNull?.imageUrls.firstOrNull,
          hero: const AQConfirmationState(icon: 'check', tone: AQTone.success),
          title: v.t('vw.confirmed.title'),
          subtitle: v.t('vw.confirmed.sub'),
          backLabel: v.t('vw.back'),
          onBack: () => aqBack(context, '/app/activity'),
          bottom: AQBottomActionBar(
            stack: true,
            primary: AQPrimaryButton(label: v.t('vw.viewDetails'), onPressed: () => context.push('/viewings/${viewing.id}')),
            secondary: AQBarSecondaryButton(label: v.t('vw.viewMy'), onPressed: () => context.go('/app/activity')),
          ),
          children: [
            _summary(property),
            const SizedBox(height: AQSpacing.x3),
            AQViewingDetailCard(slot: viewing.slot, tone: AQTone.success, title: v.t('vw.yourViewing'), trailing: Align(alignment: AlignmentDirectional.centerEnd, child: AQViewingStatus(presentation: pres, dense: true))),
            AQViewingSectionTitle(v.t('vw.meeting'), icon: 'pin'),
            _placeNote(context, property, 'vw.meeting.confirmed'),
            AQViewingSectionTitle(v.t('vw.host'), icon: 'user'),
            AQViewingHostCard(host: viewing.host, showContactNote: false),
          ],
        );
      },
    );
  }
}

/// Screen 44: the request will not happen; there is always a next step.
class ViewingDeclinedScreen extends StatelessWidget {
  final String id;
  const ViewingDeclinedScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final v = ViewingStrings.of(context);
    return ViewingLoader(
      id: id,
      leaf: 'declined',
      title: v.t('vw.declined.title'),
      onBack: () => aqBack(context, '/app/activity'),
      builder: (context, ref, viewing, property) => AQViewingScaffold(
        emotional: true,
        washImage: property.valueOrNull?.imageUrls.firstOrNull,
        hero: const AQConfirmationState(icon: 'calendar-x', tone: AQTone.warning, haptic: false),
        title: v.t('vw.declined.title'),
        subtitle: v.t('vw.declined.sub'),
        backLabel: v.t('vw.back'),
        onBack: () => aqBack(context, '/app/activity'),
        bottom: AQBottomActionBar(
            stack: true,
          primary: AQPrimaryButton(label: v.t('vw.tryOther'), leadingIcon: 'calendar', trailingChevron: false, onPressed: () => context.push('/property/${viewing.propertyId}/viewing')),
          secondary: AQBarSecondaryButton(label: v.t('vw.browseSimilar'), leadingIcon: 'search', onPressed: () => aqBrowseSimilar(context, property.valueOrNull)),
        ),
        children: [
          _summary(property),
          if (viewing.declineReason != null) ...[const SizedBox(height: AQSpacing.x3), AQNoticeCard(icon: 'info', title: v.t('vw.declined.reason'), body: viewing.declineReason!)],
          const SizedBox(height: AQSpacing.x3),
          AQViewingDetailCard(slot: viewing.slot, title: v.t('vw.requestedSlot'), showType: false),
          const SizedBox(height: AQSpacing.x3),
          AQNoticeCard(icon: 'info', tone: AQTone.warning, title: v.t('vw.whatYouCanDo'), body: v.t('vw.declined.tip')),
        ],
      ),
    );
  }
}

/// Screen 45: the host offered other times. Only host-provided slots can be chosen.
class ViewingRescheduleScreen extends ConsumerStatefulWidget {
  final String id;
  const ViewingRescheduleScreen({super.key, required this.id});
  @override
  ConsumerState<ViewingRescheduleScreen> createState() => _ViewingRescheduleScreenState();
}

class _ViewingRescheduleScreenState extends ConsumerState<ViewingRescheduleScreen> {
  ViewingSlot? _choice;
  bool _busy = false;
  bool _failed = false;

  Future<void> _run(Future<Viewing> Function(ViewingRepository) call, String then) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await call(ref.read(viewingRepositoryProvider));
      ref.invalidate(viewingsProvider);
      ref.invalidate(viewingProvider(widget.id));
      if (!mounted) return;
      AQHaptics.confirm();
      context.go(then);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ViewingStrings.of(context);
    final c = AQColors.of(context);
    final id = widget.id;
    return ViewingLoader(
      id: id,
      leaf: 'reschedule',
      title: v.t('vw.resched.title'),
      onBack: () => aqBack(context, '/viewings/$id'),
      builder: (context, ref, viewing, property) {
        final choice = _choice ?? viewing.suggestions.first;
        return AQViewingScaffold(
          emotional: true,
          washImage: property.valueOrNull?.imageUrls.firstOrNull,
          hero: const AQConfirmationState(icon: 'refresh', tone: AQTone.warning, haptic: false),
          title: v.t('vw.resched.title'),
          subtitle: v.t('vw.resched.sub'),
          backLabel: v.t('vw.back'),
          onBack: _busy ? () {} : () => aqBack(context, '/viewings/$id'),
          bottom: AQBottomActionBar(
            primary: AQPrimaryButton(label: v.t('vw.confirmNew'), leadingIcon: 'calendar-check', trailingChevron: false, loading: _busy, onPressed: () => _run((r) => r.acceptSuggestion(id, choice), '/viewings/$id/confirmed')),
            secondary: AQBarSecondaryButton(label: v.t('vw.declineNew'), leadingIcon: 'close', onPressed: _busy ? null : () => _run((r) => r.declineSuggestion(id), '/viewings/$id')),
          ),
          children: [
            if (_failed) AQErrorBanner(text: v.t('vw.resched.error')),
            _summary(property, density: AQViewingDensity.compact),
            const SizedBox(height: AQSpacing.x3),
            AQViewingHostCard(host: viewing.host),
            const SizedBox(height: AQSpacing.x3),
            AQSurface(
              padding: const EdgeInsets.all(AQSpacing.x4),
              child: Row(children: [
                AQIcon('calendar-x', size: AQIconSize.medium, color: c.inkFaint),
                const SizedBox(width: AQSpacing.x3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(v.t('vw.original'), style: AQTypography.of(context, AQText.bodySmall, soft: true)),
                    Text(VFmt.dateTime(context, viewing.slot), style: AQTypography.of(context, AQText.titleSmall, color: c.inkSoft).copyWith(decoration: TextDecoration.lineThrough, decorationColor: c.inkFaint)),
                  ]),
                ),
              ]),
            ),
            AQViewingSectionTitle(v.t('vw.suggested'), icon: 'clock'),
            for (final s in viewing.suggestions)
              Padding(
                padding: const EdgeInsets.only(bottom: AQSpacing.x2),
                child: _SuggestionTile(slot: s, selected: s == choice, onTap: () => setState(() => _choice = s)),
              ),
          ],
        );
      },
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final ViewingSlot slot;
  final bool selected;
  final VoidCallback onTap;
  const _SuggestionTile({required this.slot, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final v = ViewingStrings.of(context);
    final text = '${VFmt.fullDate(context, slot.start)}, ${VFmt.range(context, slot)}';
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? '$text, ${v.t('vw.a11y.selected')}' : text,
      excludeSemantics: true,
      child: AQPressable(
        onTap: () {
          AQHaptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: AQMotion.scaled(context, AQMotion.fast),
          constraints: const BoxConstraints(minHeight: AQControl.tap + 8),
          padding: const EdgeInsets.all(AQSpacing.x3 + 2),
          decoration: BoxDecoration(color: selected ? c.surfaceSelected : c.surface, borderRadius: BorderRadius.circular(AQRadius.medium), border: Border.all(color: selected ? c.accent : Colors.transparent, width: 1.5)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(VFmt.fullDate(context, slot.start), style: AQTypography.of(context, AQText.titleSmall)),
                Text(VFmt.range(context, slot), style: AQTypography.of(context, AQText.bodyMedium, soft: true)),
              ]),
            ),
            AnimatedContainer(
              duration: AQMotion.scaled(context, AQMotion.fast),
              width: 24,
              height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? c.accent : Colors.transparent, border: selected ? null : Border.all(color: c.hairline, width: 1.5)),
              child: selected ? Center(child: AQIcon('check', size: 14, color: c.onAccent)) : null,
            ),
          ]),
        ),
      ),
    );
  }
}

/// Screen 46 (before): destructive action asks first, calmly.
class ViewingCancelScreen extends ConsumerStatefulWidget {
  final String id;
  const ViewingCancelScreen({super.key, required this.id});
  @override
  ConsumerState<ViewingCancelScreen> createState() => _ViewingCancelScreenState();
}

class _ViewingCancelScreenState extends ConsumerState<ViewingCancelScreen> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _cancel() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await ref.read(viewingRepositoryProvider).cancel(widget.id);
      ref.invalidate(viewingsProvider);
      ref.invalidate(viewingProvider(widget.id));
      if (!mounted) return;
      AQHaptics.confirm();
      context.go('/viewings/${widget.id}/cancelled');
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = ViewingStrings.of(context);
    final c = AQColors.of(context);
    final id = widget.id;
    return ViewingLoader(
      id: id,
      title: v.t('vw.cancel.title'),
      onBack: () => aqBack(context, '/viewings/$id'),
      builder: (context, ref, viewing, property) {
        if (!viewing.isActive) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go('/viewings/$id');
          });
        }
        return AQViewingScaffold(
          emotional: true,
          washImage: property.valueOrNull?.imageUrls.firstOrNull,
          hero: const AQConfirmationState(icon: 'calendar-x', tone: AQTone.warning, haptic: false, size: 88),
          title: v.t('vw.cancel.title'),
          subtitle: v.t('vw.cancel.sub'),
          backLabel: v.t('vw.back'),
          onBack: _busy ? () {} : () => aqBack(context, '/viewings/$id'),
          bottom: AQBottomActionBar(
            primary: AQPrimaryButton(label: v.t('vw.cancel.yes'), trailingChevron: false, loading: _busy, background: c.danger, foreground: c.isDark ? c.onAccent : Colors.white, onPressed: _cancel),
            secondary: AQBarSecondaryButton(label: v.t('vw.cancel.keep'), onPressed: _busy ? null : () => aqBack(context, '/viewings/$id')),
          ),
          children: [
            if (_failed) AQErrorBanner(text: v.t('vw.cancel.error')),
            _summary(property),
            AQViewingSectionTitle(v.t('vw.yourViewing'), icon: 'calendar'),
            AQViewingDetailCard(slot: viewing.slot),
          ],
        );
      },
    );
  }
}

/// Screen 46 (after): cancelled, with a clear way forward.
class ViewingCancelledScreen extends StatelessWidget {
  final String id;
  const ViewingCancelledScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final v = ViewingStrings.of(context);
    return ViewingLoader(
      id: id,
      leaf: 'cancelled',
      title: v.t('vw.cancelled.title'),
      onBack: () => aqBack(context, '/app/activity'),
      builder: (context, ref, viewing, property) {
        final pres = ViewingPresentation.of(viewing);
        return AQViewingScaffold(
          emotional: true,
          washImage: property.valueOrNull?.imageUrls.firstOrNull,
          hero: const AQConfirmationState(icon: 'close', tone: AQTone.neutral, haptic: false),
          title: v.t('vw.cancelled.title'),
          subtitle: viewing.cancelledByHost ? v.t('vw.cancelled.byHost') : v.t('vw.cancelled.sub'),
          backLabel: v.t('vw.back'),
          onBack: () => aqBack(context, '/app/activity'),
          bottom: AQBottomActionBar(
            stack: true,
            primary: AQPrimaryButton(label: v.t('vw.scheduleNew'), leadingIcon: 'calendar', trailingChevron: false, onPressed: () => context.push('/property/${viewing.propertyId}/viewing')),
            secondary: AQBarSecondaryButton(label: v.t('vw.browseSimilar'), leadingIcon: 'search', onPressed: () => aqBrowseSimilar(context, property.valueOrNull)),
          ),
          children: [
            _summary(property, density: AQViewingDensity.compact),
            const SizedBox(height: AQSpacing.x3),
            AQViewingDetailCard(slot: viewing.slot, showType: false, trailing: Align(alignment: AlignmentDirectional.centerEnd, child: AQViewingStatus(presentation: pres, dense: true))),
            const SizedBox(height: AQSpacing.x3),
            AQNoticeCard(icon: 'info', title: v.t('vw.next'), body: v.t('vw.cancelled.next')),
          ],
        );
      },
    );
  }
}

/// Screen 48: the journey reached a conclusion; reviewing the host is offered, never forced.
class ViewingCompletedScreen extends StatelessWidget {
  final String id;
  const ViewingCompletedScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final v = ViewingStrings.of(context);
    return ViewingLoader(
      id: id,
      leaf: 'completed',
      title: v.t('vw.completed.title'),
      onBack: () => aqBack(context, '/app/activity'),
      builder: (context, ref, viewing, property) {
        final pres = ViewingPresentation.of(viewing);
        void toReview([int? rating]) => context.push('/viewings/${viewing.id}/review${rating == null ? '' : '?rating=$rating'}');
        return AQViewingScaffold(
          emotional: true,
          washImage: property.valueOrNull?.imageUrls.firstOrNull,
          hero: const AQConfirmationState(icon: 'check', tone: AQTone.success),
          title: v.t('vw.completed.title'),
          subtitle: v.t('vw.completed.sub'),
          backLabel: v.t('vw.back'),
          onBack: () => aqBack(context, '/app/activity'),
          bottom: AQBottomActionBar(
            stack: true,
            primary: viewing.reviewEligible
                ? AQPrimaryButton(label: v.t('vw.rate.write'), leadingIcon: 'star', trailingChevron: false, onPressed: toReview)
                : AQPrimaryButton(label: v.t('vw.backToProperty'), onPressed: () => context.go('/property/${viewing.propertyId}')),
            secondary: viewing.reviewEligible ? AQBarSecondaryButton(label: v.t('vw.backToProperty'), onPressed: () => context.go('/property/${viewing.propertyId}')) : null,
          ),
          children: [
            _summary(property, badge: v.t('vw.viewed')),
            const SizedBox(height: AQSpacing.x3),
            AQViewingDetailCard(slot: viewing.slot, tone: AQTone.success, title: v.t('vw.detail.about'), trailing: Align(alignment: AlignmentDirectional.centerEnd, child: AQViewingStatus(presentation: pres, dense: true))),
            AQViewingSectionTitle(v.t('vw.host'), icon: 'user'),
            AQViewingHostCard(host: viewing.host),
            if (viewing.reviewEligible) ...[const SizedBox(height: AQSpacing.x4), AQReviewEligibilityCard(hostName: viewing.host.name, onRate: toReview)],
          ],
        );
      },
    );
  }
}

/// Entry point of the review flow. The review form itself is a later screen: this page
/// states eligibility honestly and never fakes a submission or publication.
class ViewingReviewEntryScreen extends StatelessWidget {
  final String id;
  final int? rating;
  const ViewingReviewEntryScreen({super.key, required this.id, this.rating});

  @override
  Widget build(BuildContext context) {
    final v = ViewingStrings.of(context);
    final c = AQColors.of(context);
    return ViewingLoader(
      id: id,
      title: v.t('vw.review.soon.title'),
      onBack: () => aqBack(context, '/viewings/$id'),
      builder: (context, ref, viewing, property) => AQViewingScaffold(
        title: v.t('vw.review.soon.title'),
        subtitle: v.t('vw.rate.sub', {'host': viewing.host.name}),
        backLabel: v.t('vw.back'),
        onBack: () => aqBack(context, '/viewings/$id'),
        bottom: AQBottomActionBar(primary: AQPrimaryButton(label: v.t('vw.review.close'), trailingChevron: false, onPressed: () => aqBack(context, '/viewings/$id'))),
        children: [
          AQViewingHostCard(host: viewing.host),
          if (rating != null) ...[
            const SizedBox(height: AQSpacing.x4),
            Semantics(
              label: v.t('vw.rate.star', {'n': VFmt.n(context, rating!)}),
              child: ExcludeSemantics(child: Row(children: [for (var i = 1; i <= 5; i++) Padding(padding: const EdgeInsets.only(right: 4), child: AQIcon(i <= rating! ? 'star-fill' : 'star', size: 28, color: c.accent))])),
            ),
          ],
          const SizedBox(height: AQSpacing.x4),
          AQNoticeCard(icon: 'info', title: v.t('vw.review.soon.body'), body: v.t('vw.review.rules')),
        ],
      ),
    );
  }
}
