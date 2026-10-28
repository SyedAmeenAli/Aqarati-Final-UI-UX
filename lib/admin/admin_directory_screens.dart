import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/aq/aq_forms.dart';
import '../core/aq/aq_primitives.dart';
import '../core/aq/aq_tokens.dart';
import '../core/aq/aq_typography.dart';
import '../features/viewing/domain/viewing_presentation.dart' show AQTone;
import '../features/viewing/widgets/viewing_format.dart';
import 'admin_auth.dart';
import 'admin_directory.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'admin_widgets.dart';

String _actor(WidgetRef ref) => ref.read(adminAuthProvider).session?.name ?? 'Admin';
bool _canDecide(WidgetRef ref) => ref.watch(adminAuthProvider).session?.role.canDecide ?? false;

String _date(BuildContext c, DateTime d) => '${VFmt.shortDate(c, d)}, ${VFmt.time(c, d)}';

(AQTone, String) _acctLook(AcctStatus s) => switch (s) {
  AcctStatus.active => (AQTone.success, 'check'),
  AcctStatus.underReview => (AQTone.pending, 'clock'),
  AcctStatus.suspended => (AQTone.danger, 'lock'),
  AcctStatus.rejected => (AQTone.neutral, 'close'),
};

(AQTone, String) _reportLook(ReportStatus s) => switch (s) {
  ReportStatus.open => (AQTone.warning, 'alert'),
  ReportStatus.inReview => (AQTone.pending, 'clock'),
  ReportStatus.resolved => (AQTone.success, 'check'),
  ReportStatus.dismissed => (AQTone.neutral, 'close'),
};

Future<bool> adminConfirm(BuildContext context, {required String title, required String body, required String action}) async {
  final yes = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        AQTextButton(label: 'Cancel', color: AQColors.of(context).inkSoft, onPressed: () => Navigator.of(d).pop(false)),
        AQTextButton(label: action, color: AQColors.of(context).accent, onPressed: () => Navigator.of(d).pop(true)),
      ],
    ),
  );
  return yes == true;
}

// ------------------------------------------------------------------ overview

class AdminOverviewScreen extends ConsumerWidget {
  const AdminOverviewScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AQColors.of(context);
    final dir = ref.watch(adminDirectoryProvider);
    final verif = ref.watch(verificationListProvider).valueOrNull;
    final listings = ref.watch(moderationListProvider).valueOrNull;
    final ads = ref.watch(adminAdsProvider).valueOrNull;
    int count(AcctStatus s) => dir.accounts.where((a) => a.status == s).length;
    final openReports = dir.reports.where((r) => r.status == ReportStatus.open || r.status == ReportStatus.inReview).length;
    final pendingListings = listings?.where((l) => l.status == ModerationStatus.pending).length;

    Widget metric(String label, String value, String route) => SizedBox(
      width: 240,
      child: Semantics(
        button: true,
        focusable: true,
        onFocus: () {},
        label: '$label: $value',
        excludeSemantics: true,
        onTap: () => context.go(route),
        child: AQPressable(
          onTap: () => context.go(route),
          child: Container(
            padding: const EdgeInsets.all(AQSpacing.x4),
            decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(AQRadius.medium), border: Border.all(color: c.hairline)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: AQTypography.of(context, AQText.displaySmall)),
                Text(label, style: AQTypography.of(context, AQText.bodySmall, soft: true)),
              ],
            ),
          ),
        ),
      ),
    );
    final byRole = {for (final r in AcctRole.values) r: dir.accounts.where((a) => a.role == r).length};
    final maxRole = byRole.values.fold<int>(1, (m, v) => v > m ? v : m);
    return AdminFrame(
      section: '/overview',
      title: 'Overview',
      subtitle: 'What needs attention across AQARATI. Demo data only.',
      children: [
        Wrap(
          spacing: AQSpacing.x3,
          runSpacing: AQSpacing.x3,
          children: [
            metric('Accounts', '${dir.accounts.length}', '/accounts'),
            metric('Accounts under review', '${count(AcctStatus.underReview)}', '/accounts'),
            metric('Applications in the verification queue', verif == null ? '...' : '${verif.length}', '/verification'),
            metric('Listings waiting for moderation', pendingListings == null ? '...' : '$pendingListings', '/moderation'),
            metric('Open reports and complaints', '$openReports', '/reports'),
            metric('Sponsored placements', ads == null ? '...' : '${ads.length}', '/ads'),
          ],
        ),
        adminSection(context, 'Accounts by role'),
        AQSurface(
          padding: const EdgeInsets.all(AQSpacing.x4),
          child: Column(
            children: [
              for (final e in byRole.entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AQSpacing.x1),
                  child: Row(
                    children: [
                      SizedBox(width: 200, child: Text(roleName(e.key), style: AQTypography.of(context, AQText.bodyMedium))),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(value: e.value / maxRole, minHeight: 8, color: c.accent, backgroundColor: c.hairline),
                        ),
                      ),
                      SizedBox(width: 36, child: Text('${e.value}', textAlign: TextAlign.end, style: AQTypography.of(context, AQText.labelMedium))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        adminSection(context, 'Recent administrative activity', trailing: AQTextButton(label: 'Open the log', color: c.accent, onPressed: () => context.go('/audit'))),
        AdminTable(
          headers: const ['When', 'Who', 'Action', 'Record'],
          flex: const [2, 2, 3, 3],
          rows: [
            for (final (i, e) in dir.audit.take(6).indexed)
              AdminTableRow(
                key: 'ov$i',
                semantics: '${e.actor}, ${e.text}, ${e.target ?? ''}',
                cells: [Text(_date(context, e.at)), Text(e.actor), Text(e.text), Text(e.target ?? '')],
              ),
          ],
        ),
        adminDemoNotice(),
      ],
    );
  }
}

// ------------------------------------------------------------------ accounts

class AdminAccountsScreen extends ConsumerStatefulWidget {
  const AdminAccountsScreen({super.key});
  @override
  ConsumerState<AdminAccountsScreen> createState() => _AccountsState();
}

class _AccountsState extends ConsumerState<AdminAccountsScreen> {
  final _q = TextEditingController();
  AcctRole? _role;
  AcctStatus? _status;
  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dir = ref.watch(adminDirectoryProvider);
    final shown = filterAccounts(dir.accounts, query: _q.text, role: _role, status: _status);
    return AdminFrame(
      section: '/accounts',
      title: 'Accounts and professionals',
      subtitle: 'Shoppers, agents, developers, builders, architects and designers.',
      children: [
        AdminSearchField(controller: _q, hint: 'Search name, city or role', onChanged: (_) => setState(() {})),
        const SizedBox(height: AQSpacing.x3),
        adminFilterRow(context, 'Role', [
          ('All', _role == null, () => setState(() => _role = null)),
          for (final r in AcctRole.values) (roleName(r), _role == r, () => setState(() => _role = _role == r ? null : r)),
        ]),
        adminFilterRow(context, 'Status', [
          ('All', _status == null, () => setState(() => _status = null)),
          for (final s in AcctStatus.values) (acctStatusName(s), _status == s, () => setState(() => _status = _status == s ? null : s)),
        ]),
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AQSpacing.x3),
            child: Text('Showing ${shown.length} of ${dir.accounts.length}', style: AQTypography.of(context, AQText.titleSmall)),
          ),
        ),
        if (shown.isEmpty)
          const AdminNotice(title: 'No accounts match', body: 'Change the search or the filters.')
        else
          AdminTable(
            headers: const ['Name', 'Role', 'Status', 'City', 'Joined'],
            flex: const [4, 3, 2, 2, 2],
            rows: [
              for (final a in shown)
                AdminTableRow(
                  key: a.id,
                  semantics: '${a.name}, ${roleName(a.role)}, ${acctStatusName(a.status)}',
                  onTap: () => context.go('/accounts/${a.id}'),
                  cells: [
                    Text(a.name),
                    Text(roleName(a.role)),
                    Align(alignment: AlignmentDirectional.centerStart, child: adminStatusPill(acctStatusName(a.status), _acctLook(a.status))),
                    Text(a.city),
                    Text(VFmt.shortDate(context, a.joined)),
                  ],
                ),
            ],
          ),
        adminDemoNotice(),
      ],
    );
  }
}

class AdminAccountDetailScreen extends ConsumerWidget {
  final String id;
  const AdminAccountDetailScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(adminDirectoryProvider);
    final a = ref.read(adminDirectoryProvider.notifier).account(id);
    final can = _canDecide(ref);
    if (a == null) {
      return AdminFrame(section: '/accounts', title: 'Account', onBack: () => context.go('/accounts'), backLabel: 'Back to accounts', children: const [AdminNotice(title: 'We could not find this account.')]);
    }
    final history = dir.audit.where((e) => e.target == a.name).toList();
    Future<void> change(AcctStatus s, String verb, String body) async {
      final ok = await adminConfirm(context, title: '$verb ${a.name}?', body: body, action: verb);
      if (ok) ref.read(adminDirectoryProvider.notifier).setAccountStatus(a.id, s, _actor(ref));
    }

    return AdminFrame(
      section: '/accounts',
      title: a.name,
      subtitle: '${roleName(a.role)} · ${a.city}',
      onBack: () => context.go('/accounts'),
      backLabel: 'Back to accounts',
      actions: [adminStatusPill(acctStatusName(a.status), _acctLook(a.status))],
      children: [
        AdminKeyValues([
          ('Role', roleName(a.role)),
          ('Status', acctStatusName(a.status)),
          ('Contact', a.email),
          ('City', a.city),
          ('Joined', VFmt.fullDate(context, a.joined)),
          ('Listings or projects', '${a.listings}'),
          if (a.note.isNotEmpty) ('Note', a.note),
        ]),
        adminSection(context, 'Review status'),
        if (a.role != AcctRole.shopper)
          Padding(
            padding: const EdgeInsets.only(bottom: AQSpacing.x3),
            child: AQNoticeLineAdmin(a.status == AcctStatus.underReview
                ? 'This business is in the verification queue. Documents are reviewed there.'
                : 'Illustrative review state only. Nothing here verifies a real business.'),
          ),
        if (!can)
          const AdminNotice(icon: 'lock', title: 'Read-only', body: 'Your role can view accounts but not change them.')
        else
          Wrap(
            spacing: AQSpacing.x3,
            runSpacing: AQSpacing.x3,
            children: [
              if (a.status != AcctStatus.active)
                SizedBox(width: 200, child: AQPrimaryButton(label: 'Set active', trailingChevron: false, onPressed: () => change(AcctStatus.active, 'Set active', 'The account would be treated as active in this demo.'))),
              if (a.status != AcctStatus.underReview)
                SizedBox(width: 200, child: AQSecondaryButton(label: 'Mark under review', trailingChevron: false, onPressed: () => change(AcctStatus.underReview, 'Mark under review', 'The account moves back to review in this demo.'))),
              if (a.status != AcctStatus.suspended)
                SizedBox(width: 200, child: AQSecondaryButton(label: 'Suspend', trailingChevron: false, onPressed: () => change(AcctStatus.suspended, 'Suspend', 'Suspending is simulated: no real account is affected.'))),
            ],
          ),
        adminSection(context, 'Activity on this account'),
        if (history.isEmpty)
          const AdminNotice(title: 'No administrative activity yet.')
        else
          AdminTable(
            headers: const ['When', 'Who', 'Action'],
            flex: const [3, 3, 4],
            rows: [
              for (final (i, e) in history.indexed)
                AdminTableRow(key: 'h$i', semantics: '${e.actor}, ${e.text}', cells: [Text(_date(context, e.at)), Text(e.actor), Text(e.text)]),
            ],
          ),
        adminDemoNotice(),
      ],
    );
  }
}

class AQNoticeLineAdmin extends StatelessWidget {
  final String text;
  const AQNoticeLineAdmin(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Text(text, style: AQTypography.of(context, AQText.bodyMedium, soft: true));
}

// ------------------------------------------------------------------ reports

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  ConsumerState<AdminReportsScreen> createState() => _ReportsState();
}

class _ReportsState extends ConsumerState<AdminReportsScreen> {
  final _q = TextEditingController();
  ReportStatus? _status;
  ReportKind? _kind;
  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dir = ref.watch(adminDirectoryProvider);
    final shown = filterReports(dir.reports, query: _q.text, status: _status, kind: _kind);
    return AdminFrame(
      section: '/reports',
      title: 'Reports and complaints',
      subtitle: 'Illustrative reports from shoppers and businesses.',
      children: [
        AdminSearchField(controller: _q, hint: 'Search subject or summary', onChanged: (_) => setState(() {})),
        const SizedBox(height: AQSpacing.x3),
        adminFilterRow(context, 'Status', [
          ('All', _status == null, () => setState(() => _status = null)),
          for (final s in ReportStatus.values) (reportStatusName(s), _status == s, () => setState(() => _status = _status == s ? null : s)),
        ]),
        adminFilterRow(context, 'About', [
          ('All', _kind == null, () => setState(() => _kind = null)),
          for (final k in ReportKind.values) (reportKindName(k), _kind == k, () => setState(() => _kind = _kind == k ? null : k)),
        ]),
        Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AQSpacing.x3),
            child: Text('Showing ${shown.length} of ${dir.reports.length}', style: AQTypography.of(context, AQText.titleSmall)),
          ),
        ),
        if (shown.isEmpty)
          const AdminNotice(title: 'No reports match', body: 'Change the search or the filters.')
        else
          AdminTable(
            headers: const ['Subject', 'About', 'Status', 'Opened'],
            flex: const [5, 2, 2, 2],
            rows: [
              for (final r in shown)
                AdminTableRow(
                  key: r.id,
                  semantics: '${r.subject}, ${reportKindName(r.kind)}, ${reportStatusName(r.status)}',
                  onTap: () => context.go('/reports/${r.id}'),
                  cells: [
                    Text(r.subject),
                    Text(reportKindName(r.kind)),
                    Align(alignment: AlignmentDirectional.centerStart, child: adminStatusPill(reportStatusName(r.status), _reportLook(r.status))),
                    Text(VFmt.shortDate(context, r.createdAt)),
                  ],
                ),
            ],
          ),
        adminDemoNotice(),
      ],
    );
  }
}

class AdminReportDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const AdminReportDetailScreen({super.key, required this.id});
  @override
  ConsumerState<AdminReportDetailScreen> createState() => _ReportDetailState();
}

class _ReportDetailState extends ConsumerState<AdminReportDetailScreen> {
  final _note = TextEditingController();
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _set(AdminReport r, ReportStatus s) async {
    final closing = s == ReportStatus.resolved || s == ReportStatus.dismissed;
    final ok = await adminConfirm(
      context,
      title: '${closing ? (s == ReportStatus.resolved ? 'Resolve' : 'Dismiss') : 'Move to ${reportStatusName(s).toLowerCase()}'} this report?',
      body: 'This is simulated. Nothing is sent to the person who reported it.',
      action: reportStatusName(s),
    );
    if (!ok) return;
    ref.read(adminDirectoryProvider.notifier).setReportStatus(r.id, s, _actor(ref), note: _note.text);
    _note.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(adminDirectoryProvider);
    final r = ref.read(adminDirectoryProvider.notifier).report(widget.id);
    final can = _canDecide(ref);
    if (r == null) {
      return AdminFrame(section: '/reports', title: 'Report', onBack: () => context.go('/reports'), backLabel: 'Back to reports', children: const [AdminNotice(title: 'We could not find this report.')]);
    }
    return AdminFrame(
      section: '/reports',
      title: r.subject,
      subtitle: '${reportKindName(r.kind)} · reported by ${r.reporter}',
      onBack: () => context.go('/reports'),
      backLabel: 'Back to reports',
      actions: [adminStatusPill(reportStatusName(r.status), _reportLook(r.status))],
      children: [
        AdminKeyValues([('Opened', _date(context, r.createdAt)), ('Reported by', r.reporter), ('Summary', r.summary)]),
        adminSection(context, 'Resolution'),
        if (!can)
          const AdminNotice(icon: 'lock', title: 'Read-only', body: 'Your role can read reports but not change them.')
        else ...[
          AQTextField(label: 'Resolution note (optional)', controller: _note, minLines: 2, maxLines: 4, action: TextInputAction.newline),
          const SizedBox(height: AQSpacing.x3),
          Wrap(
            spacing: AQSpacing.x3,
            runSpacing: AQSpacing.x3,
            children: [
              if (r.status == ReportStatus.open) SizedBox(width: 200, child: AQSecondaryButton(label: 'Start review', trailingChevron: false, onPressed: () => _set(r, ReportStatus.inReview))),
              if (r.status != ReportStatus.resolved) SizedBox(width: 200, child: AQPrimaryButton(label: 'Resolve', trailingChevron: false, onPressed: () => _set(r, ReportStatus.resolved))),
              if (r.status != ReportStatus.dismissed) SizedBox(width: 200, child: AQSecondaryButton(label: 'Dismiss', trailingChevron: false, onPressed: () => _set(r, ReportStatus.dismissed))),
              if (r.status == ReportStatus.resolved || r.status == ReportStatus.dismissed) SizedBox(width: 200, child: AQSecondaryButton(label: 'Reopen', trailingChevron: false, onPressed: () => _set(r, ReportStatus.open))),
            ],
          ),
        ],
        adminSection(context, 'Notes'),
        if (r.notes.isEmpty)
          const AdminNotice(title: 'No notes yet.')
        else
          AdminTable(
            headers: const ['When', 'By', 'Note'],
            flex: const [3, 3, 6],
            rows: [
              for (final (i, n) in r.notes.indexed)
                AdminTableRow(key: 'n$i', semantics: '${n.by}: ${n.text}', cells: [Text(_date(context, n.at)), Text(n.by), Text(n.text)]),
            ],
          ),
        adminDemoNotice(),
      ],
    );
  }
}

// ------------------------------------------------------------------ audit log

class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dir = ref.watch(adminDirectoryProvider);
    return AdminFrame(
      section: '/audit',
      title: 'Activity log',
      subtitle: 'Fictional demo events. Changes you make in this session appear at the top; none of them touch a real record.',
      children: [
        AdminTable(
          headers: const ['When', 'Who', 'Action', 'Record'],
          flex: const [3, 3, 4, 4],
          rows: [
            for (final (i, e) in dir.audit.indexed)
              AdminTableRow(key: 'a$i', semantics: '${e.actor}, ${e.text}, ${e.target ?? ''}', cells: [Text(_date(context, e.at)), Text(e.actor), Text(e.text), Text(e.target ?? '')]),
          ],
        ),
        adminDemoNotice(),
      ],
    );
  }
}
