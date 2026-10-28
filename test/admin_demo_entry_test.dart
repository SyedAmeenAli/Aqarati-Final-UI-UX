import 'package:aqarati_app/admin/admin_app.dart';
import 'package:aqarati_app/admin/admin_repository.dart';
import 'package:aqarati_app/core/config/demo_mode.dart';
import 'package:aqarati_app/features/ads/ad_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app() => ProviderScope(
  overrides: adminOverrides(
    DemoAdminStore(latency: Duration.zero, ads: DemoAdRepository(latency: Duration.zero)),
  ),
  child: const AdminApp(),
);

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  testWidgets('the one-tap demo console entry exists only when demo mode is on', (t) async {
    t.view.physicalSize = const Size(1300, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app());
    await settle(t);
    expect(find.text('Sign in'), findsWidgets);
    if (!kDemoMode) {
      expect(find.text('Open the demo console'), findsNothing, reason: 'normal builds have no shortcut');
      return;
    }
    await t.tap(find.text('Open the demo console'));
    await settle(t);
    await settle(t);
    expect(find.text('Accounts under review'), findsOneWidget, reason: 'lands on the Overview');
    expect(find.text('Demo Super Admin'), findsWidgets);
  });
}
