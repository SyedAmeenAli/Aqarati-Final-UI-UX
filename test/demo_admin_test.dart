import 'package:aqarati_app/core/config/demo_mode.dart';
import 'package:aqarati_app/core/domain/account_models.dart' show MeSession;
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/data/demo/demo_providers.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/flow/screens/auth_screens.dart';
import 'package:aqarati_app/features/flow/screens/signup_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

late ProviderContainer _box;

Widget _app(String start) => ProviderScope(
  overrides: demoOverrides(),
  child: Consumer(
    builder: (context, ref, _) {
      _box = ProviderScope.containerOf(context);
      return MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: start,
          routes: [
            GoRoute(
              path: '/login',
              builder: (_, s) =>
                  LoginScreen(experience: s.uri.queryParameters['as']),
            ),
            GoRoute(
              path: '/signup/:r',
              builder: (_, s) => SignupFormScreen(
                purpose: switch (s.pathParameters['r']) {
                  'agent' => SignupPurpose.realEstateAgent,
                  'construction' => SignupPurpose.constructionCompany,
                  _ => SignupPurpose.userToShop,
                },
              ),
            ),
            GoRoute(path: '/admin', builder: (_, _) => const Scaffold(body: Text('AT /admin'))),
            GoRoute(
              path: '/agent',
              builder: (_, _) => const Scaffold(body: Text('AGENT WORKSPACE')),
            ),
            GoRoute(
              path: '/app/home',
              builder: (_, _) => const Scaffold(body: Text('HOME')),
            ),
          ],
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
      );
    },
  ),
);

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

void _phone(WidgetTester t) {
  t.view.physicalSize = const Size(393, 852);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('demo mode is off unless a build turns it on explicitly', () {
    const asked = bool.fromEnvironment('AQARATI_DEMO_MODE');
    expect(kDemoMode, asked);
  });

  group('Skip for Demo', () {
    testWidgets('User to Shop signup offers it and opens Home as a buyer', (
      t,
    ) async {
      _phone(t);
      await t.pumpWidget(_app('/signup/user'));
      await _settle(t);
      expect(find.text('Skip for Demo'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget, reason: 'real path stays');
      await t.tap(find.text('Skip for Demo'));
      await _settle(t);
      expect(find.text('HOME'), findsOneWidget);
      expect(
        find.textContaining('no account was created'),
        findsOneWidget,
        reason: 'says plainly that nothing was registered',
      );
      expect(find.textContaining('registered successfully'), findsNothing);
      final me = await t.runAsync(() => _box.read(meProvider.future)) as MeSession;
      expect(me.purpose, SignupPurpose.userToShop);
      expect(me.grant, isNull, reason: 'a buyer gets no business grant');
    });

    testWidgets(
      'Real Estate Agent signup offers it and opens the agent session',
      (t) async {
        _phone(t);
        await t.pumpWidget(_app('/signup/agent'));
        await _settle(t);
        expect(find.text('Skip for Demo'), findsOneWidget);
        await t.tap(find.text('Skip for Demo'));
        await _settle(t);
        expect(find.text('AGENT WORKSPACE'), findsOneWidget);
        expect(find.text('HOME'), findsNothing);
        expect(find.textContaining('no account was created'), findsOneWidget);
        final me = await t.runAsync(() => _box.read(meProvider.future)) as MeSession;
        expect(me.purpose, SignupPurpose.realEstateAgent);
      },
    );

    testWidgets('other roles do not get it', (t) async {
      _phone(t);
      await t.pumpWidget(_app('/signup/construction'));
      await _settle(t);
      expect(find.text('Skip for Demo'), findsNothing);
    });

    testWidgets('the real form is untouched: empty Next still validates', (
      t,
    ) async {
      _phone(t);
      await t.pumpWidget(_app('/signup/user'));
      await _settle(t);
      await t.tap(find.text('Next'));
      await _settle(t);
      expect(find.text('HOME'), findsNothing);
      expect(find.text('Skip for Demo'), findsOneWidget);
    });
  }, skip: !kDemoMode);

  group('without demo mode (the normal build)', () {
    testWidgets('no Skip for Demo on any signup path, real flow intact', (
      t,
    ) async {
      for (final r in ['user', 'agent', 'construction']) {
        _phone(t);
        await t.pumpWidget(_app('/signup/$r'));
        await _settle(t);
        expect(find.text('Skip for Demo'), findsNothing, reason: r);
        expect(find.text('Next'), findsOneWidget, reason: r);
      }
    });
  }, skip: kDemoMode);

  group('Admin Console link', () {
    testWidgets('sits under Login on both login variants', (t) async {
      for (final x in ['user', 'agent']) {
        _phone(t);
        await t.pumpWidget(_app('/login?as=$x'));
        await _settle(t);
        expect(find.text('Admin Console →'), findsOneWidget);
        final login = t.getRect(find.text('Log in').last);
        final admin = t.getRect(find.text('Admin Console →'));
        expect(admin.top, greaterThan(login.bottom), reason: x);
      }
    });

    testWidgets(
      'with no external address it opens the console hosted inside the app at /admin',
      (t) async {
        _phone(t);
        await t.pumpWidget(_app('/login'));
        await _settle(t);
        expect(adminConsoleUrl(), isNull);
        await t.tap(find.text('Admin Console →'));
        await _settle(t);
        expect(find.text('AT /admin'), findsOneWidget);
      },
    );

    test(
      'it is not a signup role and the customer app never imports the console',
      () {
        expect(signupPurposeOptions.length, 6);
      },
    );
  });
}
