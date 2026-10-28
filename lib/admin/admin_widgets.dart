import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/aq/aq_demo.dart';
import '../core/aq/aq_forms.dart';
import '../core/aq/aq_primitives.dart';
import '../core/aq/aq_status.dart';
import '../core/aq/aq_tokens.dart';
import '../core/aq/aq_typography.dart';
import '../core/config/backend_mode.dart';
import '../data/api/account_api.dart' show ApiException;
import '../features/devbuild/db_widgets.dart'
    show DbPillRow, DbSelectField, showDbChoiceSheet;
import '../features/entry/widgets/entry_common.dart' show MasterLogo;
import '../features/viewing/domain/viewing_presentation.dart' show AQTone;
import '../features/viewing/widgets/viewing_format.dart';
import 'admin_auth.dart';
import 'admin_models.dart';
import 'admin_repository.dart';

// ------------------------------------------------------------------ copy for error and reason keys

String adminMsg(String key) => switch (key) {
  'adm.err.sponsor' => 'Enter the sponsor name.',
  'adm.err.headline' => 'Enter a headline.',
  'adm.err.cta' => 'Enter the button label.',
  'adm.err.destination' =>
    'Use a secure https address, or an app path that starts with /.',
  'adm.err.image' => 'Choose a banner image.',
  'adm.err.imageType' => 'The banner image must be a JPG or PNG file.',
  'adm.err.imageSize' => 'The banner image must be 5 MB or smaller.',
  'adm.err.schedule' => 'The start date must be before the end date.',
  'adm.err.audience' => 'Choose at least one Home screen for this banner.',
  _ => key,
};

String reasonLabel(ReasonCode c) => switch (c) {
  ReasonCode.docUnreadable => 'Document unreadable',
  ReasonCode.docWrongType => 'Wrong document type',
  ReasonCode.nameMismatch => 'Name does not match',
  ReasonCode.expired => 'Document expired',
  ReasonCode.notOnRegistry => 'Not found on the registry',
  ReasonCode.licenceCategoryMismatch => 'Licence category does not match',
  ReasonCode.ownerMismatch => 'Owner does not match',
  ReasonCode.duplicateListing => 'Duplicate listing',
  ReasonCode.photosMismatch => 'Photos do not match the property',
  ReasonCode.callFailed => 'Call-back failed',
  ReasonCode.incompleteSubmission => 'Incomplete submission',
  ReasonCode.other => 'Other (note required)',
};

String kindLabel(ApplicantKind k) => switch (k) {
  ApplicantKind.agent => 'Real estate agent',
  ApplicantKind.developer => 'Development company',
  ApplicantKind.construction => 'Construction company',
  ApplicantKind.architecture => 'Building architecture',
  ApplicantKind.interiorExterior => 'Interior & exterior design',
};

String roleLabel(AdminRole r) => switch (r) {
  AdminRole.reviewer => 'Reviewer',
  AdminRole.seniorReviewer => 'Senior reviewer',
  AdminRole.superAdmin => 'Super admin',
  AdminRole.auditor => 'Auditor',
};

String queueStatusLabel(QueueStatus s) => switch (s) {
  QueueStatus.pending => 'Waiting for review',
  QueueStatus.awaitingSecondApproval => 'Awaiting second approval',
  QueueStatus.resubmissionRequired => 'Resubmission requested',
  QueueStatus.approved => 'Approved',
  QueueStatus.rejected => 'Rejected',
};

(AQTone, String) queueStatusLook(QueueStatus s) => switch (s) {
  QueueStatus.pending => (AQTone.pending, 'clock'),
  QueueStatus.awaitingSecondApproval => (AQTone.warning, 'user'),
  QueueStatus.resubmissionRequired => (AQTone.warning, 'refresh'),
  QueueStatus.approved => (AQTone.success, 'check'),
  QueueStatus.rejected => (AQTone.danger, 'close'),
};

String moderationStatusLabel(ModerationStatus s) => switch (s) {
  ModerationStatus.pending => 'Waiting for review',
  ModerationStatus.resubmissionRequired => 'Corrections requested',
  ModerationStatus.approved => 'Approved',
  ModerationStatus.rejected => 'Rejected',
};

(AQTone, String) moderationStatusLook(ModerationStatus s) => switch (s) {
  ModerationStatus.pending => (AQTone.pending, 'clock'),
  ModerationStatus.resubmissionRequired => (AQTone.warning, 'refresh'),
  ModerationStatus.approved => (AQTone.success, 'check'),
  ModerationStatus.rejected => (AQTone.danger, 'close'),
};

String decisionLabel(Decision d) => switch (d) {
  Decision.approve => 'Approve',
  Decision.requestResubmission => 'Request resubmission',
  Decision.reject => 'Reject',
};

String sourceLabel(ListingSource s) =>
    s == ListingSource.eBroker ? 'Aqary e-Broker' : 'Agent submission';

/// The message for something that went wrong, in the console's own words. Session expiry is
/// handled by the caller (it ends the session); everything else becomes plain text.
String adminErrorText(Object e) {
  if (e is AdminForbiddenException) {
    return 'Your role cannot do this. Nothing was changed.';
  }
  if (e is AdminLockedException) {
    return '${e.by.isEmpty ? 'Another reviewer' : e.by} is reviewing this item. Nothing was changed.';
  }
  if (e is AdminSameApproverException) {
    return 'A developer application needs two different approvers. A different senior reviewer must give the second approval.';
  }
  if (e is AdminConflictException) {
    return 'This item was already decided. Refresh to see its current status.';
  }
  if (e is ApiException) {
    return 'We could not complete this. Nothing was changed.';
  }
  return 'We could not complete this. Nothing was changed.';
}

/// Ends the session when the service says it ended. Returns true when it did.
bool endSessionIfExpired(WidgetRef ref, Object e) {
  if (e is AdminSessionExpiredException) {
    ref.read(adminAuthProvider.notifier).expire();
    return true;
  }
  return false;
}

// ------------------------------------------------------------------ frame

class _NavItem {
  final String label, icon, route;
  const _NavItem(this.label, this.icon, this.route);
}

const _nav = [
  _NavItem('Overview', 'home', '/overview'),
  _NavItem('Accounts', 'account', '/accounts'),
  _NavItem('Verification', 'verified', '/verification'),
  _NavItem('Listing moderation', 'development', '/moderation'),
  _NavItem('Property listings', 'home', '/m/listings'),
  _NavItem('Agents and brokers', 'agent', '/m/brokers'),
  _NavItem('Development projects', 'development', '/m/projects'),
  _NavItem('Construction', 'construction', '/m/construction'),
  _NavItem('Architecture and design', 'architecture', '/m/design'),
  _NavItem('Maintenance', 'construction', '/m/maintenance'),
  _NavItem('Viewings and requests', 'calendar', '/m/viewings'),
  _NavItem('Ads & Sponsors', 'star', '/ads'),
  _NavItem('Categories and content', 'globe', '/m/content'),
  _NavItem('Announcements', 'alert', '/m/announcements'),
  _NavItem('Analytics', 'activity', '/analytics'),
  _NavItem('Reports', 'alert', '/reports'),
  _NavItem('Activity log', 'clock', '/audit'),
  _NavItem('Profile and settings', 'account', '/settings'),
];

/// One frame for every console page: a sidebar on wide screens, a top bar and tabs on narrow ones.
class AdminFrame extends ConsumerWidget {
  final String section;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final String? backLabel;
  final List<Widget> children;
  const AdminFrame({
    super.key,
    required this.section,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    this.backLabel,
    required this.children,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AQColors.of(context);
    final auth = ref.watch(adminAuthProvider);
    final s = auth.session;
    final wide = MediaQuery.sizeOf(context).width >= 960;

    Widget body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            wide ? 40 : AQSpacing.gutter,
            wide ? 32 : AQSpacing.x4,
            wide ? 40 : AQSpacing.gutter,
            64,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onBack != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AQSpacing.x3),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AQTextButton(
                      label: backLabel ?? 'Back',
                      color: c.accent,
                      onPressed: onBack,
                    ),
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: AQSpacing.x3,
                spacing: AQSpacing.x4,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: AQTypography.of(
                              context,
                              AQText.displaySmall,
                            ),
                          ),
                        ),
                        if (subtitle != null)
                          Padding(
                            padding: const EdgeInsets.only(top: AQSpacing.x1),
                            child: Text(
                              subtitle!,
                              style: AQTypography.of(
                                context,
                                AQText.bodyMedium,
                                soft: true,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Wrap(
                      spacing: AQSpacing.x2,
                      runSpacing: AQSpacing.x2,
                      children: [
                        for (final a in actions) SizedBox(width: 190, child: a),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AQSpacing.x5),
              ...children,
            ],
          ),
        ),
      ),
    );

    Widget account() => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(s?.name ?? '', style: AQTypography.of(context, AQText.titleSmall)),
        Text(
          s == null ? '' : roleLabel(s.role),
          style: AQTypography.of(context, AQText.bodySmall, soft: true),
        ),
        const SizedBox(height: AQSpacing.x2),
        AQTextButton(
          label: 'Sign out',
          color: c.accent,
          onPressed: () => ref.read(adminAuthProvider.notifier).signOut(),
        ),
      ],
    );

    if (wide) {
      return Scaffold(
        backgroundColor: c.background,
        body: Row(
          children: [
            Container(
              width: 264,
              decoration: BoxDecoration(
                color: c.surfaceRaised,
                border: BorderDirectional(end: BorderSide(color: c.hairline)),
              ),
              padding: const EdgeInsets.all(AQSpacing.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MasterLogo(width: 120),
                  ),
                  const SizedBox(height: AQSpacing.x2),
                  Text(
                    'Admin console',
                    style: AQTypography.of(
                      context,
                      AQText.labelMedium,
                      color: c.accentDeep,
                    ),
                  ),
                  const SizedBox(height: AQSpacing.x6),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final n in _nav)
                            _SideItem(item: n, selected: section == n.route),
                        ],
                      ),
                    ),
                  ),
                  account(),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AQSpacing.gutter,
                AQSpacing.x3,
                AQSpacing.gutter,
                AQSpacing.x2,
              ),
              child: Row(
                children: [
                  MasterLogo(width: 84),
                  const SizedBox(width: AQSpacing.x3),
                  Expanded(
                    child: Text(
                      'Admin console',
                      style: AQTypography.of(
                        context,
                        AQText.labelMedium,
                        color: c.accentDeep,
                      ),
                    ),
                  ),
                  AQTextButton(
                    label: 'Sign out',
                    color: c.accent,
                    onPressed: () =>
                        ref.read(adminAuthProvider.notifier).signOut(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AQSpacing.gutter),
              child: DbPillRow(
                scroll: true,
                pills: [
                  for (final n in _nav)
                    (n.label, section == n.route, () => context.go(n.route)),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  const _SideItem({required this.item, required this.selected});
  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AQSpacing.x1),
      child: Semantics(
        button: true,
        focusable: true,
        onFocus: () {},
        selected: selected,
        label: item.label,
        excludeSemantics: true,
      onTap: () => context.go(item.route),
        child: AQPressable(
          onTap: () => context.go(item.route),
          child: AnimatedContainer(
            duration: AQMotion.scaled(context, AQMotion.fast),
            constraints: const BoxConstraints(minHeight: AQControl.tap),
            padding: const EdgeInsets.symmetric(horizontal: AQSpacing.x3),
            decoration: BoxDecoration(
              color: selected ? c.surfaceSelected : Colors.transparent,
              borderRadius: BorderRadius.circular(AQRadius.medium),
            ),
            child: Row(
              children: [
                AQIcon(
                  item.icon,
                  size: 20,
                  color: selected ? c.accentDeep : c.inkSoft,
                ),
                const SizedBox(width: AQSpacing.x3),
                Expanded(
                  child: Text(
                    item.label,
                    style: AQTypography.of(
                      context,
                      AQText.labelLarge,
                      color: selected ? c.accentDeep : c.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ table

class AdminTableRow {
  final String key;
  final List<Widget> cells;
  final String semantics;
  final VoidCallback? onTap;

  /// Indexes of cells that hold their own buttons. Those keep their own accessibility nodes, so a
  /// screen reader can reach "Pause" or "Move up" instead of only hearing the row as one button.
  final Set<int> actionCells;
  const AdminTableRow({
    required this.key,
    required this.cells,
    required this.semantics,
    this.onTap,
    this.actionCells = const {},
  });
}

/// A table on a wide page, and one card per record on a narrow page, so nothing is squeezed until it
/// stops being readable. [flex] sets the relative column widths.
// Each row (and, in the Ads list, each action) has a stable key, so when a row changes from
// Pause to Resume the accessibility node of its button is rebuilt instead of reusing the old one.
Widget _rowSemantics(AdminTableRow r, Widget child) => KeyedSubtree(
  key: ValueKey('row-${r.key}'),
  child: Semantics(
    container: true,
    explicitChildNodes: r.actionCells.isNotEmpty,
    button: r.onTap != null,
    focusable: r.onTap != null,
    onFocus: r.onTap == null ? null : () {},
    onTap: r.onTap,
    label: r.semantics,
    excludeSemantics: r.actionCells.isEmpty,
    child: child,
  ),
);

Widget _cell(AdminTableRow r, int i) =>
    r.actionCells.isEmpty || r.actionCells.contains(i)
    ? r.cells[i]
    : ExcludeSemantics(child: r.cells[i]);

class AdminTable extends StatelessWidget {
  final List<String> headers;
  final List<int> flex;
  final List<AdminTableRow> rows;
  const AdminTable({
    super.key,
    required this.headers,
    required this.flex,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 720;
    if (!wide) {
      return Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: AQSpacing.x3),
              child: _rowSemantics(
                r,
                AQPressable(
                  onTap: r.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(AQSpacing.x4),
                    decoration: BoxDecoration(
                      color: c.surfaceRaised,
                      borderRadius: BorderRadius.circular(AQRadius.large),
                      border: Border.all(color: c.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < r.cells.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: i == 0
                                ? _cell(r, i)
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 104,
                                        child: Text(
                                          headers[i],
                                          style: AQTypography.of(
                                            context,
                                            AQText.bodySmall,
                                            soft: true,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: _cell(r, i),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(AQRadius.large),
        border: Border.all(color: c.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: c.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AQSpacing.x4,
              vertical: AQSpacing.x3,
            ),
            child: Row(
              children: [
                for (var i = 0; i < headers.length; i++)
                  Expanded(
                    flex: flex[i],
                    child: Text(
                      headers[i],
                      style: AQTypography.of(
                        context,
                        AQText.labelMedium,
                        color: c.inkSoft,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final r in rows)
            _rowSemantics(
              r,
              AQPressable(
                onTap: r.onTap,
                pressedScale: 1,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.hairline)),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AQSpacing.x4,
                    vertical: AQSpacing.x3,
                  ),
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      for (var i = 0; i < r.cells.length; i++)
                        Expanded(
                          flex: flex[i],
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _cell(r, i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget adminStatusPill(String label, (AQTone, String) look) =>
    AQStatusPill(label: label, tone: look.$1, icon: look.$2, dense: true);

// ------------------------------------------------------------------ async + states

/// Loading skeleton, an error with Retry, or the data. A session that ended sends the person to
/// sign-in; a role that is not allowed sees a plain "not allowed" instead of an empty screen.
class AdminAsyncView<T> extends ConsumerWidget {
  final AsyncValue<T> value;
  final VoidCallback onRetry;
  final Widget Function(T data) builder;
  final double skeletonHeight;
  const AdminAsyncView({
    super.key,
    required this.value,
    required this.onRetry,
    required this.builder,
    this.skeletonHeight = 72,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AQColors.of(context);
    if (value.hasValue) return builder(value.requireValue);
    if (value.hasError) {
      final e = value.error!;
      if (e is AdminSessionExpiredException) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(adminAuthProvider.notifier).expire(),
        );
        return const SizedBox.shrink();
      }
      if (e is AdminForbiddenException) {
        return AdminNotice(
          icon: 'lock',
          title: 'Not allowed',
          body: adminErrorText(e),
        );
      }
      return AQErrorBanner(
        text: 'We could not load this. Check the connection and try again.',
        action: AQTextButton(
          label: 'Try again',
          color: c.accent,
          onPressed: onRetry,
        ),
      );
    }
    return Column(
      children: [for (var i = 0; i < 3; i++) _Skeleton(height: skeletonHeight)],
    );
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return ExcludeSemantics(
      child: Container(
        height: height,
        margin: const EdgeInsets.only(bottom: AQSpacing.x3),
        decoration: BoxDecoration(
          color: c.ink.withValues(alpha: c.isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(AQRadius.medium),
        ),
      ),
    );
  }
}

class AdminNotice extends StatelessWidget {
  final String icon, title, body;
  final Widget? action;
  const AdminNotice({
    super.key,
    this.icon = 'info',
    required this.title,
    this.body = '',
    this.action,
  });
  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AQSpacing.x5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AQRadius.large),
        border: Border.all(color: c.hairline),
      ),
      child: Column(
        children: [
          AQIcon(icon, size: 28, color: c.accent),
          const SizedBox(height: AQSpacing.x3),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AQTypography.of(context, AQText.headlineSmall),
            ),
          ),
          if (body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AQSpacing.x2),
              child: Text(
                body,
                textAlign: TextAlign.center,
                style: AQTypography.of(context, AQText.bodyMedium, soft: true),
              ),
            ),
          if (action != null)
            Padding(
              padding: const EdgeInsets.only(top: AQSpacing.x4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: action!,
              ),
            ),
        ],
      ),
    );
  }
}

class AdminKeyValues extends StatelessWidget {
  final List<(String, String)> rows;
  const AdminKeyValues(this.rows, {super.key});
  @override
  Widget build(BuildContext context) {
    return AQSurface(
      padding: const EdgeInsets.all(AQSpacing.x4),
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AQSpacing.x1),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      r.$1,
                      style: AQTypography.of(
                        context,
                        AQText.bodySmall,
                        soft: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      VFmt.iso(r.$2),
                      style: AQTypography.of(context, AQText.bodyMedium),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Widget adminSection(BuildContext context, String title, {Widget? trailing}) =>
    Padding(
      padding: const EdgeInsets.only(top: AQSpacing.x6, bottom: AQSpacing.x3),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: AQTypography.of(context, AQText.headlineSmall),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );

Widget adminDemoNotice() => kUseDemoBackend
    ? const Padding(
        padding: EdgeInsets.only(top: AQSpacing.x4),
        child: AQDemoNotice(),
      )
    : const SizedBox.shrink();

// ------------------------------------------------------------------ document viewer

/// Shows a document the service streams. Documents are never downloaded or stored here: the viewer
/// only displays the stream, with a watermark of who is looking and when. There is no real file in
/// the demo, and the dialog says so.
Future<void> showDocumentViewer(
  BuildContext context,
  WidgetRef ref,
  AdminDocument doc,
) {
  final session = ref.read(adminAuthProvider).session;
  return showDialog<void>(
    context: context,
    builder: (d) {
      final c = AQColors.of(d);
      final stamp =
          '${session?.name ?? 'Admin'} · ${session?.id ?? ''} · ${DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' ')}';
      return _AdminDialog(
        backgroundColor: c.surfaceRaised,
        insetPadding: const EdgeInsets.all(AQSpacing.x4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AQRadius.large),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.all(AQSpacing.x5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          doc.label,
                          style: AQTypography.of(d, AQText.headlineSmall),
                        ),
                      ),
                    ),
                    AQIconButton(
                      icon: 'close',
                      semanticsLabel: 'Close',
                      onPressed: () => Navigator.of(d).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AQSpacing.x3),
                Flexible(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AQRadius.medium),
                    child: Container(
                      height: 320,
                      color: c.surface,
                      child: doc.available
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(AQSpacing.x5),
                                  child: Text(
                                    'Demo document. There is no real file behind this preview.',
                                    textAlign: TextAlign.center,
                                    style: AQTypography.of(
                                      d,
                                      AQText.bodyMedium,
                                      soft: true,
                                    ),
                                  ),
                                ),
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Center(
                                      child: Transform.rotate(
                                        angle: -0.35,
                                        child: Text(
                                          '$stamp\n$stamp\n$stamp',
                                          textAlign: TextAlign.center,
                                          style: AQTypography.of(
                                            d,
                                            AQText.labelMedium,
                                            color: c.ink.withValues(
                                              alpha: 0.16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(AQSpacing.x5),
                              child: Center(
                                child: AdminNotice(
                                  icon: 'alert',
                                  title: 'This document is not available',
                                  body: 'The service could not stream it. It may be missing, expired or removed. Ask the applicant to resubmit it.',
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: AQSpacing.x3),
                Text(
                  'Viewing is recorded. The file cannot be downloaded or saved from this screen.',
                  style: AQTypography.of(
                    d,
                    AQText.bodySmall,
                    color: c.inkFaint,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

// ------------------------------------------------------------------ step-up and decisions

/// Asks for a fresh one-time code before a decision (step-up re-authentication). Returns true only
/// when the service accepted it.
Future<bool> showStepUp(BuildContext context, WidgetRef ref) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (d) => _StepUpDialog(ref: ref),
  );
  return ok == true;
}

class _StepUpDialog extends StatefulWidget {
  final WidgetRef ref;
  const _StepUpDialog({required this.ref});
  @override
  State<_StepUpDialog> createState() => _StepUpDialogState();
}

class _StepUpDialogState extends State<_StepUpDialog> {
  AQOtpState _state = AQOtpState.idle;
  String? _error;
  final _key = GlobalKey<AQOtpFieldState>();

  Future<void> _submit(String code) async {
    setState(() {
      _state = AQOtpState.verifying;
      _error = null;
    });
    try {
      await widget.ref.read(adminAuthRepositoryProvider).reauthenticate(code);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (endSessionIfExpired(widget.ref, e)) {
        if (mounted) Navigator.of(context).pop(false);
        return;
      }
      if (mounted) {
        setState(() {
          _state = AQOtpState.error;
          _error = e is AdminTotpException
              ? 'That code is not right. Try the current code.'
              : 'We could not check the code. Try again.';
        });
        _key.currentState?.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return _AdminDialog(
      backgroundColor: c.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AQRadius.large),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AQSpacing.x5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  'Confirm it is you',
                  style: AQTypography.of(context, AQText.headlineSmall),
                ),
              ),
              const SizedBox(height: AQSpacing.x2),
              Text(
                'Enter the current code from your authenticator app to record this decision.',
                style: AQTypography.of(context, AQText.bodyMedium, soft: true),
              ),
              const SizedBox(height: AQSpacing.x4),
              AQOtpField(
                key: _key,
                label: 'One-time code',
                state: _state,
                enabled: _state != AQOtpState.verifying,
                onCompleted: _submit,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: AQSpacing.x3),
                  child: AQErrorBanner(text: _error!),
                ),
              const SizedBox(height: AQSpacing.x4),
              AQSecondaryButton(
                label: 'Cancel',
                trailingChevron: false,
                onPressed: _state == AQOtpState.verifying
                    ? null
                    : () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The decision form shared by verification and moderation: choose Approve, Request resubmission or
/// Reject; a reason code (and a note for "Other") is required for the last two; a fresh one-time
/// code confirms it. Nothing is sent until every required part is there, and a failure leaves the
/// item exactly as it was.
class DecisionPanel extends ConsumerStatefulWidget {
  final List<ReasonCode> reasons;

  /// Null when approving is allowed; otherwise the reason it is not.
  final String? approveBlockedReason;
  final bool canDecide;
  final bool open;
  final Future<void> Function(Decision d, ReasonCode? reason, String note)
  onDecide;
  const DecisionPanel({
    super.key,
    required this.reasons,
    this.approveBlockedReason,
    required this.canDecide,
    required this.open,
    required this.onDecide,
  });
  @override
  ConsumerState<DecisionPanel> createState() => _DecisionPanelState();
}

class _DecisionPanelState extends ConsumerState<DecisionPanel> {
  Decision? _decision;
  ReasonCode? _reason;
  final _note = TextEditingController();
  bool _tried = false, _busy = false;
  String? _error, _done;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _needsReason => _decision != null && _decision != Decision.approve;

  String? get _reasonError =>
      _tried && _needsReason && _reason == null ? 'Choose a reason.' : null;
  String? get _noteError =>
      _tried &&
          _needsReason &&
          _reason == ReasonCode.other &&
          _note.text.trim().isEmpty
      ? 'Add a note for "Other".'
      : null;

  Future<void> _submit() async {
    setState(() => _tried = true);
    final d = _decision;
    if (d == null || _busy) return;
    if (d == Decision.approve && widget.approveBlockedReason != null) return;
    if (_needsReason &&
        (_reason == null ||
            (_reason == ReasonCode.other && _note.text.trim().isEmpty))) {
      return;
    }
    final ok = await showStepUp(context, ref);
    if (!ok || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _done = null;
    });
    try {
      await widget.onDecide(
        d,
        _needsReason ? _reason : null,
        _note.text.trim(),
      );
      if (mounted) {
        setState(() {
          _done = switch (d) {
            Decision.approve => 'Decision recorded: approved.',
            Decision.requestResubmission =>
              'Decision recorded: resubmission requested.',
            Decision.reject => 'Decision recorded: rejected.',
          };
          _decision = null;
          _reason = null;
          _note.clear();
          _tried = false;
        });
      }
    } catch (e) {
      if (!endSessionIfExpired(ref, e) && mounted) {
        setState(() => _error = adminErrorText(e));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    if (!widget.canDecide) {
      return const AdminNotice(
        icon: 'lock',
        title: 'Read-only',
        body: 'Your role can view this item but not decide it.',
      );
    }
    if (!widget.open) {
      return Column(
        children: [
          if (_done != null)
            AQErrorBanner(tone: AQBannerTone.success, text: _done!),
          const AdminNotice(
            icon: 'check',
            title: 'Decided',
            body: 'This item has been decided. Its status is shown above.',
          ),
        ],
      );
    }
    final blocked = _decision == Decision.approve
        ? widget.approveBlockedReason
        : null;
    return AQSurface(
      padding: const EdgeInsets.all(AQSpacing.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Decision',
              style: AQTypography.of(context, AQText.titleMedium),
            ),
          ),
          const SizedBox(height: AQSpacing.x3),
          DbPillRow(
            pills: [
              for (final d in Decision.values)
                (
                  decisionLabel(d),
                  _decision == d,
                  () => setState(() => _decision = d),
                ),
            ],
          ),
          AnimatedSize(
            duration: AQMotion.scaled(context, AQMotion.fast),
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (blocked != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AQSpacing.x3),
                    child: AQErrorBanner(
                      tone: AQBannerTone.info,
                      text: blocked,
                    ),
                  ),
                if (_needsReason) ...[
                  const SizedBox(height: AQSpacing.x4),
                  DbSelectField<ReasonCode>(
                    label: 'Reason code',
                    valueLabel: _reason == null ? null : reasonLabel(_reason!),
                    hint: 'Choose a reason',
                    required: true,
                    error: null,
                    onTap: () async {
                      final r = await showDbChoiceSheet<ReasonCode>(
                        context,
                        title: 'Reason code',
                        options: [
                          for (final x in widget.reasons) (x, reasonLabel(x)),
                        ],
                        selected: _reason,
                      );
                      if (r != null) setState(() => _reason = r);
                    },
                  ),
                  if (_reasonError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AQSpacing.x1),
                      child: Text(
                        _reasonError!,
                        style: AQTypography.of(
                          context,
                          AQText.bodySmall,
                          color: c.danger,
                        ),
                      ),
                    ),
                  const SizedBox(height: AQSpacing.x3),
                  AQTextField(
                    label: _reason == ReasonCode.other
                        ? 'Note (required)'
                        : 'Note for the applicant (optional)',
                    controller: _note,
                    minLines: 2,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    action: TextInputAction.newline,
                    error: _noteError,
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AQSpacing.x3),
              child: AQErrorBanner(text: _error!),
            ),
          if (_done != null)
            Padding(
              padding: const EdgeInsets.only(top: AQSpacing.x3),
              child: AQErrorBanner(tone: AQBannerTone.success, text: _done!),
            ),
          const SizedBox(height: AQSpacing.x4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SizedBox(
              width: 260,
              child: AQPrimaryButton(
                label: _decision == null
                    ? 'Choose a decision'
                    : decisionLabel(_decision!),
                trailingChevron: false,
                loading: _busy,
                onPressed: _decision == null || _busy || blocked != null
                    ? null
                    : _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Wraps a pending claim: takes the lock when the page opens and gives it back when it closes.
class ClaimBanner extends StatelessWidget {
  final String? lockedBy;
  const ClaimBanner({super.key, this.lockedBy});
  @override
  Widget build(BuildContext context) {
    if (lockedBy == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AQSpacing.x4),
      child: AQErrorBanner(
        tone: AQBannerTone.info,
        text:
            '$lockedBy is reviewing this item. You can read it, but decisions are locked until they finish or 30 minutes pass.',
      ),
    );
  }
}

String shortDate(BuildContext context, DateTime d) =>
    '${VFmt.shortDate(context, d)} · ${VFmt.time(context, d)}';

/// Used by the queue pages: a simple text filter field.
class AdminSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => AQTextField(
    label: hint,
    controller: controller,
    hint: hint,
    action: TextInputAction.search,
    prefix: Padding(
      padding: const EdgeInsets.only(left: AQSpacing.x3),
      child: AQIcon('search', size: 20, color: AQColors.of(context).inkSoft),
    ),
    onChanged: onChanged,
  );
}

/// Label above a group of filter pills.
Widget adminFilterRow(
  BuildContext context,
  String label,
  List<(String, bool, VoidCallback)> pills,
) => Padding(
  padding: const EdgeInsets.only(bottom: AQSpacing.x3),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: AQSpacing.x2),
        child: Text(
          label,
          style: AQTypography.of(context, AQText.labelMedium, soft: true),
        ),
      ),
      DbPillRow(scroll: true, pills: pills),
    ],
  ),
);

/// A dialog whose children keep their own accessibility nodes (so the close button and the code field
/// can be reached with a screen reader or by label), not merged into one "dialog" node.
class _AdminDialog extends StatelessWidget {
  final Color backgroundColor;
  final EdgeInsets insetPadding;
  final ShapeBorder shape;
  final Widget child;
  const _AdminDialog({
    required this.backgroundColor,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 40,
      vertical: 24,
    ),
    required this.shape,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: backgroundColor,
    insetPadding: insetPadding,
    shape: shape,
    child: Semantics(container: true, explicitChildNodes: true, child: child),
  );
}
