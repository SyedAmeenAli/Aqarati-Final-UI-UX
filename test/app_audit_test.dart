import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/core/router/app_router.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/data/demo/demo_backend.dart';
import 'package:aqarati_app/data/repositories/app_state_providers.dart';
import 'package:aqarati_app/data/repositories/local_persistence.dart';
import 'package:aqarati_app/features/workspace/aq_app_shell.dart' show AccountTab;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/flow/screens/verification_status_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regression guards for the whole-app audit (docs/readiness).
void main() {
  test('every route uses the shared page-transition family (no platform-default transitions)', () {
    final builderOnly = <String>[];
    void walk(List<RouteBase> routes) {
      for (final r in routes) {
        if (r is GoRoute && r.builder != null && r.pageBuilder == null) builderOnly.add(r.path);
        walk(r.routes);
      }
    }

    walk(appRouter.configuration.routes);
    expect(builderOnly, isEmpty, reason: 'use pageBuilder with AQRoute so every push and pop moves the same way');
  });

  test('Compare is a real route (shared transition, back stack), not a raw platform route', () {
    final paths = <String>[];
    void walk(List<RouteBase> routes) {
      for (final r in routes) {
        if (r is GoRoute) paths.add(r.path);
        walk(r.routes);
      }
    }

    walk(appRouter.configuration.routes);
    expect(paths, contains('/compare'));
  });

  group('buyer never sees a business verification status', () {
    Future<void> pump(WidgetTester t, SignupPurpose purpose, GrantState? grant) async {
      final state = DemoBackendState()
        ..purpose = purpose
        ..account = AccountState.active
        ..grant = grant
        ..phone = '91234567'
        ..signedIn = true;
      final router = GoRouter(initialLocation: '/verification', routes: [
        GoRoute(path: '/verification', builder: (c, s) => const VerificationStatusScreen()),
        GoRoute(path: '/app/home', builder: (c, s) => const Scaffold(body: Text('HOME PAGE'))),
      ]);
      await t.pumpWidget(ProviderScope(
        overrides: [accountApiProvider.overrideWithValue(DemoAccountApi(state))],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
          supportedLocales: const [Locale('en'), Locale('ar')],
        ),
      ));
      for (var i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 300));
      }
    }

    testWidgets('a buyer is sent home from /verification', (t) async {
      await pump(t, SignupPurpose.userToShop, null);
      expect(find.text('HOME PAGE'), findsOneWidget);
      expect(find.textContaining('Add your documents'), findsNothing);
    });

    testWidgets('a business applicant still sees their real status', (t) async {
      await pump(t, SignupPurpose.constructionCompany, GrantState.pendingVerification);
      expect(find.text('HOME PAGE'), findsNothing);
      expect(find.byType(VerificationStatusScreen), findsOneWidget);
    });
  });

  group('local persistence (saved properties and recent searches)', () {
    Widget host(Widget probe) => ProviderScope(child: AQLocalPersistence(child: MaterialApp(home: probe)));

    testWidgets('a fresh install starts with no saved properties and no invented recent searches', (t) async {
      SharedPreferences.setMockInitialValues({});
      late WidgetRef r;
      await t.pumpWidget(host(Consumer(builder: (c, ref, _) {
        r = ref;
        return const SizedBox();
      })));
      await t.pump(const Duration(milliseconds: 50));
      expect(r.read(savedPropertyIdsProvider), isEmpty);
      expect(r.read(recentSearchesProvider), isEmpty);
    });

    testWidgets('saved properties and recent searches survive a restart', (t) async {
      SharedPreferences.setMockInitialValues({});
      late WidgetRef r;
      Widget app() => host(Consumer(builder: (c, ref, _) {
            r = ref;
            return const SizedBox();
          }));
      await t.pumpWidget(app());
      await t.pump(const Duration(milliseconds: 50));
      r.read(savedPropertyIdsProvider.notifier).state = {'p1', 'p4'};
      r.read(recentSearchesProvider.notifier).state = ['villa muscat'];
      await t.pump(const Duration(milliseconds: 50));
      // "Restart": a brand new app tree reads the stored values.
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(app());
      await t.pump(const Duration(milliseconds: 100));
      expect(r.read(savedPropertyIdsProvider), {'p1', 'p4'});
      expect(r.read(recentSearchesProvider), ['villa muscat']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(kSavedIdsKey)!.toSet(), {'p1', 'p4'});
    });

    testWidgets('removing a saved property is remembered too', (t) async {
      SharedPreferences.setMockInitialValues({kSavedIdsKey: ['p1', 'p2']});
      late WidgetRef r;
      await t.pumpWidget(host(Consumer(builder: (c, ref, _) {
        r = ref;
        return const SizedBox();
      })));
      await t.pump(const Duration(milliseconds: 100));
      expect(r.read(savedPropertyIdsProvider), {'p1', 'p2'});
      r.read(savedPropertyIdsProvider.notifier).state = {'p2'};
      await t.pump(const Duration(milliseconds: 100));
      expect((await SharedPreferences.getInstance()).getStringList(kSavedIdsKey), ['p2']);
    });
  });

  testWidgets('the Account tab states plainly that this build is a demo', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.binding.setSurfaceSize(const Size(393, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(ProviderScope(
      overrides: [meProvider.overrideWith((ref) async => throw const ApiException(ApiErrorCode.network))],
      child: MaterialApp(
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        home: const Scaffold(body: AccountTab()),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
    expect(find.text('DEMO DATA'), findsOneWidget);
    expect(find.textContaining('simulated in this build'), findsOneWidget);
  });
}
