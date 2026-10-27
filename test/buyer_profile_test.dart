import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/features/account/buyer_profile.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _me = MeSession(
  account: AccountState.active,
  purpose: SignupPurpose.userToShop,
  phoneLast4: '1234',
);

DemoBuyerProfileRepository repo({BuyerProfile? initial}) =>
    DemoBuyerProfileRepository(
      latency: Duration.zero,
      initial: initial ?? const BuyerProfile(),
    );

Widget app(
  BuyerProfileRepository r, {
  MeSession? me = _me,
  String start = '/app/account/profile',
}) {
  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: '/app/account',
        builder: (_, _) => const Scaffold(body: Text('ACCOUNT')),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('LOGIN')),
      ),
      GoRoute(
        path: '/app/account/profile',
        builder: (_, _) => const BuyerProfileScreen(),
      ),
      GoRoute(
        path: '/app/account/profile/edit',
        builder: (_, _) => const BuyerProfileScreen(edit: true),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      meProvider.overrideWith((ref) async {
        if (me == null) throw const ApiException(ApiErrorCode.network);
        return me;
      }),
      buyerProfileRepositoryProvider.overrideWithValue(r),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

void big(WidgetTester t) {
  t.view.physicalSize = const Size(393, 1200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  test('name rules', () {
    expect(nameError('', 'k'), 'k');
    expect(nameError('Aïsha', 'k'), isNull);
    expect(nameError('محمد', 'k'), isNull);
    expect(nameError("O'Neil-Smith", 'k'), isNull);
    expect(nameError('Al3x', 'k'), 'pf.err.chars');
    expect(nameError('x' * 41, 'k'), 'pf.err.chars');
  });

  testWidgets('empty profile: no name invented, phone masked and read-only', (
    t,
  ) async {
    big(t);
    await t.pumpWidget(app(repo()));
    await settle(t);
    expect(find.text('No name added yet'), findsOneWidget);
    expect(find.text('•••• 1234'), findsOneWidget);
    expect(
      find.textContaining('Changing it needs a new verification'),
      findsOneWidget,
    );
  });

  testWidgets('edit prefills, validates, saves, and says it is demo only', (
    t,
  ) async {
    big(t);
    final r = repo(
      initial: const BuyerProfile(firstName: 'Sara', lastName: 'Ali'),
    );
    await t.pumpWidget(app(r));
    await settle(t);
    expect(find.text('Sara Ali'), findsOneWidget);
    await t.tap(find.text('Edit'));
    await settle(t);
    expect(find.widgetWithText(TextField, 'First name'), findsOneWidget);
    expect(find.text('Sara'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextField, 'First name'), '');
    await t.tap(find.text('Save changes'));
    await settle(t);
    expect(find.text('Enter your first name.'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextField, 'First name'), 'Al3x');
    await t.tap(find.text('Save changes'));
    await settle(t);
    expect(find.text('Use letters only.'), findsOneWidget);
    expect((await r.profile()).firstName, 'Sara');
    await t.enterText(find.widgetWithText(TextField, 'First name'), 'Salma');
    await t.tap(find.text('Save changes'));
    await settle(t);
    expect((await r.profile()).fullName, 'Salma Ali');
    expect(find.text('Salma Ali'), findsOneWidget);
    expect(
      find.textContaining('kept on this device and sent nowhere'),
      findsOneWidget,
    );
  });

  testWidgets('a failed save keeps what was typed and changes nothing', (
    t,
  ) async {
    big(t);
    final r = repo(
      initial: const BuyerProfile(firstName: 'Sara', lastName: 'Ali'),
    );
    await t.pumpWidget(app(r, start: '/app/account/profile/edit'));
    await settle(t);
    await t.enterText(find.widgetWithText(TextField, 'First name'), 'Salma');
    r.debugNextError = const ApiException(ApiErrorCode.network);
    await t.tap(find.text('Save changes'));
    await settle(t);
    expect(find.textContaining('Nothing was changed'), findsOneWidget);
    expect(find.text('Salma'), findsOneWidget);
    expect((await r.profile()).firstName, 'Sara');
    await t.tap(find.text('Save changes'));
    await settle(t);
    expect((await r.profile()).firstName, 'Salma');
  });

  testWidgets(
    'cancel with changes asks first; Keep editing stays; Leave discards',
    (t) async {
      big(t);
      final r = repo(
        initial: const BuyerProfile(firstName: 'Sara', lastName: 'Ali'),
      );
      await t.pumpWidget(app(r, start: '/app/account/profile/edit'));
      await settle(t);
      await t.enterText(find.widgetWithText(TextField, 'First name'), 'Salma');
      await t.tap(find.text('Cancel').first);
      await settle(t);
      expect(find.text('Leave without saving?'), findsOneWidget);
      await t.tap(find.text('Keep editing'));
      await settle(t);
      expect(find.text('Salma'), findsOneWidget);
      await t.tap(find.text('Cancel').first);
      await settle(t);
      await t.tap(find.text('Leave'));
      await settle(t);
      expect(find.text('Sara Ali'), findsOneWidget);
      expect((await r.profile()).firstName, 'Sara');
    },
  );

  testWidgets('cancel without changes leaves at once', (t) async {
    big(t);
    await t.pumpWidget(app(repo(), start: '/app/account/profile/edit'));
    await settle(t);
    await t.tap(find.text('Cancel').first);
    await settle(t);
    expect(find.text('Leave without saving?'), findsNothing);
    expect(find.text('Your profile'), findsOneWidget);
  });

  testWidgets('service unavailable: error with Try again', (t) async {
    big(t);
    await t.pumpWidget(app(const UnavailableBuyerProfileRepository()));
    await settle(t);
    expect(find.text('Try again'), findsWidgets);
  });

  testWidgets('signed out: asks to log in', (t) async {
    big(t);
    await t.pumpWidget(app(repo(), me: null));
    await settle(t);
    expect(find.text('Log in to see your profile'), findsOneWidget);
  });
}
