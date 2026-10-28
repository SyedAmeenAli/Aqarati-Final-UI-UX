import 'package:aqarati_app/admin/admin_app.dart';
import 'package:aqarati_app/admin/admin_directory.dart';
import 'package:aqarati_app/admin/admin_repository.dart';
import 'package:aqarati_app/features/ads/ad_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

late ProviderContainer box;

DemoAdminStore store() => DemoAdminStore(
  latency: Duration.zero,
  ads: DemoAdRepository(latency: Duration.zero),
);

Widget app() => ProviderScope(
  overrides: adminOverrides(store()),
  child: Consumer(
    builder: (context, ref, _) {
      box = ProviderScope.containerOf(context);
      return const AdminApp();
    },
  ),
);

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

void screen(WidgetTester t, {double w = 1300, double h = 1000}) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> login(WidgetTester t, String who) async {
  await t.enterText(find.widgetWithText(TextField, 'Email'), '$who@demo.test');
  await t.enterText(find.widgetWithText(TextField, 'Password'), DemoAdminStore.demoPassword);
  await t.tap(find.text('Continue'));
  await settle(t);
  await t.enterText(find.byType(TextField).first, DemoAdminStore.demoCode);
  await settle(t);
}

void go(WidgetTester t, String path) {
  GoRouter.of(t.element(find.byType(Scaffold).first)).go(path);
}

void main() {
  group('directory rules (pure)', () {
    final now = DateTime(2026, 10, 29, 12);
    test('seed has every role and status and is deterministic', () {
      final s = seedDirectory(now);
      expect(s.accounts.map((a) => a.role).toSet(), AcctRole.values.toSet());
      expect(s.accounts.map((a) => a.status).toSet(), AcctStatus.values.toSet());
      expect(seedDirectory(now).accounts.map((a) => a.id), s.accounts.map((a) => a.id));
    });

    test('account and report filters narrow the lists', () {
      final s = seedDirectory(now);
      expect(filterAccounts(s.accounts, role: AcctRole.agent).length, 3);
      expect(filterAccounts(s.accounts, status: AcctStatus.suspended).length, 2);
      expect(filterAccounts(s.accounts, query: 'studio').single.id, 'A1');
      expect(filterAccounts(s.accounts, query: 'zzz'), isEmpty);
      expect(filterReports(s.reports, status: ReportStatus.open).length, 2);
      expect(filterReports(s.reports, kind: ReportKind.ad).length, 1);
      expect(filterReports(s.reports, query: 'photos').single.id, 'R1');
    });

    test('changes update the record and add an activity entry', () {
      final d = AdminDirectory(now);
      final before = d.state.audit.length;
      d.setAccountStatus('G2', AcctStatus.active, 'Test Admin');
      expect(d.account('G2')!.status, AcctStatus.active);
      expect(d.state.audit.length, before + 1);
      expect(d.state.audit.first.actor, 'Test Admin');
      d.setAccountStatus('G2', AcctStatus.active, 'Test Admin');
      expect(d.state.audit.length, before + 1, reason: 'no change, no entry');
      d.setReportStatus('R1', ReportStatus.resolved, 'Test Admin', note: 'Photos corrected');
      expect(d.report('R1')!.status, ReportStatus.resolved);
      expect(d.report('R1')!.notes.first.text, 'Photos corrected');
    });
  });

  group('console pages', () {
    testWidgets('sign-in lands on the overview, and the sidebar lists every section', (t) async {
      screen(t);
      await t.pumpWidget(app());
      await settle(t);
      await login(t, 'reviewer');
      expect(find.text('Overview'), findsWidgets);
      for (final s in ['Accounts', 'Verification', 'Listing moderation', 'Ads & Sponsors', 'Reports', 'Activity log']) {
        expect(find.text(s), findsWidgets, reason: s);
      }
      expect(find.text('Explore'), findsNothing, reason: 'not the customer navigation');
      expect(find.text('Accounts under review'), findsOneWidget);
      expect(find.text('Open reports and complaints'), findsOneWidget);
    });

    testWidgets('accounts: search and open an account, then change its status', (t) async {
      screen(t);
      await t.pumpWidget(app());
      await settle(t);
      await login(t, 'reviewer');
      go(t, '/accounts');
      await settle(t);
      expect(find.text('Showing 14 of 14'), findsOneWidget);
      await t.enterText(find.byType(TextField).first, 'Rana');
      await settle(t);
      expect(find.text('Showing 1 of 14'), findsOneWidget);
      await t.tap(find.text('Rana Agent Example'));
      await settle(t);
      expect(find.text('Mark under review'), findsNothing, reason: 'already under review');
      await t.tap(find.text('Set active'));
      await settle(t);
      expect(find.text('Set active Rana Agent Example?'), findsOneWidget, reason: 'asks first');
      await t.tap(find.text('Cancel'));
      await settle(t);
      expect(box.read(adminDirectoryProvider).accounts.firstWhere((a) => a.id == 'G2').status, AcctStatus.underReview,
          reason: 'Cancel changes nothing');
      await t.tap(find.text('Set active'));
      await settle(t);
      await t.tap(find.text('Set active').last);
      await settle(t);
      expect(box.read(adminDirectoryProvider).accounts.firstWhere((a) => a.id == 'G2').status, AcctStatus.active);
      expect(box.read(adminDirectoryProvider).audit.first.target, 'Rana Agent Example');
    });

    testWidgets('reports: filter, open, resolve with a note; the activity log shows it', (t) async {
      screen(t);
      await t.pumpWidget(app());
      await settle(t);
      await login(t, 'reviewer');
      go(t, '/reports');
      await settle(t);
      expect(find.text('Showing 5 of 5'), findsOneWidget);
      go(t, '/reports/R1');
      await settle(t);
      await t.enterText(find.byType(TextField).first, 'Photos replaced by the owner');
      await t.tap(find.text('Resolve'));
      await settle(t);
      await t.tap(find.text('Resolved').last);
      await settle(t);
      final r = box.read(adminDirectoryProvider).reports.firstWhere((x) => x.id == 'R1');
      expect(r.status, ReportStatus.resolved);
      expect(r.notes.first.text, 'Photos replaced by the owner');
      go(t, '/audit');
      await settle(t);
      expect(find.text('Resolved report'), findsWidgets);
    });

    testWidgets('an auditor can read accounts but not change them', (t) async {
      screen(t);
      await t.pumpWidget(app());
      await settle(t);
      await login(t, 'auditor');
      go(t, '/accounts/G2');
      await settle(t);
      expect(find.text('Read-only'), findsOneWidget);
      expect(find.text('Set active'), findsNothing);
    });

    for (final w in [320.0, 390.0, 768.0, 1300.0]) {
      testWidgets('every new page fits at ${w.toInt()} px', (t) async {
        screen(t, w: w, h: 900);
        await t.pumpWidget(app());
        await settle(t);
        await login(t, 'reviewer');
        for (final p in ['/overview', '/accounts', '/accounts/G1', '/reports', '/reports/R2', '/audit']) {
          go(t, p);
          await settle(t);
          expect(t.takeException(), isNull, reason: '$p @ $w');
        }
      });
    }
  });
}
