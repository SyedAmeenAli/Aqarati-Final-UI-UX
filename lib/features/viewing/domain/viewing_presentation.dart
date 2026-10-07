import 'viewing_models.dart';

/// Semantic tone. Colours are resolved once, in the status component, from AQ tokens.
enum AQTone { pending, success, warning, danger, neutral }

/// Every action a viewing can offer, ordered [primary, secondary]. Screens render only what the mapping lists.
enum ViewingAction { cancel, reschedule, tryAnotherSlot, scheduleAnother, browseSimilar, writeReview, backToProperty, viewMyViewings }

/// Stages of the visit timeline, in order.
enum ViewingStage { requestSent, underReview, confirmed, visit, completed }

/// Centralised state presentation: copy keys, icon, tone, timeline position and
/// available actions per viewing state. Screens must not re-derive this.
class ViewingPresentation {
  /// Key of the short status label (shared by badges, rows and details).
  final String labelKey;
  final String icon;
  final AQTone tone;
  /// Detail-page supporting line.
  final String summaryKey;
  /// Current timeline stage; null when a timeline does not apply (declined / cancelled).
  final ViewingStage? stage;
  final List<ViewingAction> actions;
  /// Where the viewing sits in My Viewings filters.
  final bool upcoming, past, cancelled;

  const ViewingPresentation({
    required this.labelKey,
    required this.icon,
    required this.tone,
    required this.summaryKey,
    required this.stage,
    required this.actions,
    this.upcoming = false,
    this.past = false,
    this.cancelled = false,
  });

  static ViewingPresentation of(Viewing v) {
    if (v.rescheduleOffered) {
      return ViewingPresentation(
        labelKey: 'vw.status.reschedule',
        icon: 'refresh',
        tone: AQTone.warning,
        summaryKey: 'vw.sum.reschedule',
        stage: v.status == ViewingStatus.confirmed ? ViewingStage.confirmed : ViewingStage.underReview,
        actions: const [ViewingAction.reschedule, ViewingAction.cancel],
        upcoming: true,
      );
    }
    return switch (v.status) {
      ViewingStatus.requested => const ViewingPresentation(
          labelKey: 'vw.status.requested',
          icon: 'clock',
          tone: AQTone.pending,
          summaryKey: 'vw.sum.requested',
          stage: ViewingStage.underReview,
          actions: [ViewingAction.backToProperty, ViewingAction.cancel],
          upcoming: true,
        ),
      ViewingStatus.confirmed => const ViewingPresentation(
          labelKey: 'vw.status.confirmed',
          icon: 'calendar-check',
          tone: AQTone.success,
          summaryKey: 'vw.sum.confirmed',
          stage: ViewingStage.visit,
          actions: [ViewingAction.backToProperty, ViewingAction.cancel],
          upcoming: true,
        ),
      ViewingStatus.declined => const ViewingPresentation(
          labelKey: 'vw.status.declined',
          icon: 'calendar-x',
          tone: AQTone.danger,
          summaryKey: 'vw.sum.declined',
          stage: null,
          actions: [ViewingAction.tryAnotherSlot, ViewingAction.browseSimilar],
          past: true,
        ),
      ViewingStatus.cancelled => const ViewingPresentation(
          labelKey: 'vw.status.cancelled',
          icon: 'close',
          tone: AQTone.neutral,
          summaryKey: 'vw.sum.cancelled',
          stage: null,
          actions: [ViewingAction.scheduleAnother, ViewingAction.browseSimilar],
          cancelled: true,
        ),
      ViewingStatus.completed => const ViewingPresentation(
          labelKey: 'vw.status.completed',
          icon: 'check',
          tone: AQTone.success,
          summaryKey: 'vw.sum.completed',
          stage: ViewingStage.completed,
          actions: [ViewingAction.writeReview, ViewingAction.backToProperty],
          past: true,
        ),
    };
  }

  /// The "moment" screen a status change opens (notification / deep-link target).
  static String momentPath(Viewing v) {
    final base = '/viewings/${v.id}';
    if (v.rescheduleOffered) return '$base/reschedule';
    return switch (v.status) {
      ViewingStatus.requested => '$base/requested',
      ViewingStatus.confirmed => '$base/confirmed',
      ViewingStatus.declined => '$base/declined',
      ViewingStatus.cancelled => '$base/cancelled',
      ViewingStatus.completed => '$base/completed',
    };
  }
}

/// My Viewings filters.
enum ViewingFilter { all, upcoming, past, cancelled }

extension ViewingFilterX on ViewingFilter {
  bool matches(Viewing v) {
    final p = ViewingPresentation.of(v);
    return switch (this) {
      ViewingFilter.all => true,
      ViewingFilter.upcoming => p.upcoming,
      ViewingFilter.past => p.past,
      ViewingFilter.cancelled => p.cancelled,
    };
  }
}
