import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/demo/demo_backend.dart';
import 'package:aqarati_app/data/demo/demo_providers.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/entry/screens/purpose_selection_screen.dart';
import 'package:aqarati_app/features/role_home/role_home_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The demo "Skip" chips on the purpose screen: each opens that role's home page for a presenter,
/// and only when the demo backend is active.
void main() {
  Widget app(DemoBackendState? state, List<String> visited) {
    final router = GoRouter(
      initialLocation: '/onboarding/purpose',
      routes: [
        GoRoute(
          path: '/onboarding/purpose',
          builder: (_, _) => const PurposeSelectionScreen(),
        ),
        GoRoute(
          path: '/app/home',
          builder: (_, _) {
            visited.add('/app/home');
            return const Scaffold(body: Text('home'));
          },
        ),
      ],
    );
    return ProviderScope(
      overrides: [demoBackendStateProvider.overrideWithValue(state)],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('every one of the six cards has a Skip chip in demo mode', (
    t,
  ) async {
    t.view.physicalSize = const Size(393, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(DemoBackendState(), []));
    await t.pump(const Duration(milliseconds: 1200));
    expect(find.text('Skip'), findsNWidgets(6));
  });

  testWidgets('no Skip chips when there is no demo backend', (t) async {
    t.view.physicalSize = const Size(393, 1400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(app(null, []));
    await t.pump(const Duration(milliseconds: 1200));
    expect(find.text('Skip'), findsNothing);
  });

  for (var i = 0; i < signupPurposeOptions.length; i++) {
    final option = signupPurposeOptions[i];
    testWidgets(
      'Skip on ${option.id.name} signs in as that role and opens home',
      (t) async {
        t.view.physicalSize = const Size(393, 1400);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final state = DemoBackendState();
        final visited = <String>[];
        await t.pumpWidget(app(state, visited));
        await t.pump(const Duration(milliseconds: 1200));
        await t.tap(find.text('Skip').at(i));
        await t.pump(const Duration(milliseconds: 600));
        expect(visited, contains('/app/home'));
        expect(state.signedIn, isTrue);
        expect(state.purpose, option.id);
        expect(state.account, AccountState.active);
        if (option.id == SignupPurpose.userToShop) {
          expect(state.grant, isNull);
        } else {
          expect(state.grant, GrantState.approved);
        }
      },
    );
  }

  for (final cfg in const [
    (320.0, 1.0, false),
    (393.0, 2.0, false),
    (360.0, 1.0, true),
    (430.0, 2.0, true),
  ]) {
    testWidgets(
      'Skip chips do not overflow at ${cfg.$1.toInt()} wide, ${cfg.$2}x text, ${cfg.$3 ? 'Arabic' : 'English'}',
      (t) async {
        t.view.physicalSize = Size(cfg.$1, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final router = GoRouter(
          initialLocation: '/p',
          routes: [
            GoRoute(
              path: '/p',
              builder: (_, _) => const PurposeSelectionScreen(),
            ),
          ],
        );
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              demoBackendStateProvider.overrideWithValue(DemoBackendState()),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              locale: Locale(cfg.$3 ? 'ar' : 'en'),
              supportedLocales: const [Locale('en'), Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              ],
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(cfg.$2)),
                child: child!,
              ),
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 1200));
        expect(t.takeException(), isNull);
        expect(find.text(cfg.$3 ? 'تخطي' : 'Skip'), findsNWidgets(6));
      },
    );
  }

  test('each skipped session resolves to its own role home', () async {
    const expected = {
      SignupPurpose.userToShop: HomeRole.buyer,
      SignupPurpose.realEstateAgent: HomeRole.agent,
      SignupPurpose.constructionCompany: HomeRole.construction,
      SignupPurpose.propertyDevelopmentCompany: HomeRole.developer,
      SignupPurpose.buildingArchitecture: HomeRole.architecture,
      SignupPurpose.interiorExteriorDesign: HomeRole.interiorExterior,
    };
    for (final e in expected.entries) {
      final state = DemoBackendState();
      demoEnterAs(state, e.key);
      final me = await DemoAccountApi(state).getMe();
      expect(resolveHome(me).role, e.value, reason: e.key.name);
    }
  });
}
