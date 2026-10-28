import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/data/models/enums.dart';
import 'package:aqarati_app/features/ads/ad_repository.dart';
import 'package:aqarati_app/features/entry/models/entry_experience.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/flow/screens/auth_screens.dart';
import 'package:aqarati_app/core/aq/aq_forms.dart' show AQTextField;
import 'package:aqarati_app/features/search/aq_property_types.dart';
import 'package:aqarati_app/features/workspace/aq_action_card.dart';
import 'package:aqarati_app/features/viewing/widgets/viewing_components.dart'
    show AQNoticeCard;
import 'package:aqarati_app/features/search/browse_taxonomy.dart';
import 'package:aqarati_app/features/workspace/aq_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Where the last stub screen was reached, so the tests can read the route the app chose.
String reached = '';

GoRouter _router({String start = '/'}) => GoRouter(
  initialLocation: start,
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const Scaffold(body: AQHomeScreen()),
    ),
    GoRoute(
      path: '/properties/categories',
      builder: (_, s) => AQCategoryStepScreen(tx: s.uri.queryParameters['tx']),
    ),
    GoRoute(
      path: '/properties/types',
      builder: (_, s) => AQTypeStepScreen(
        tx: s.uri.queryParameters['tx'],
        cat: s.uri.queryParameters['cat'],
      ),
    ),
    GoRoute(
      path: '/properties/all',
      builder: (_, s) {
        reached = s.uri.toString();
        return Scaffold(body: Text('RESULTS ${s.uri.query}'));
      },
    ),
    GoRoute(
      path: '/sell',
      builder: (_, _) => const Scaffold(body: Text('SELL')),
    ),
    GoRoute(
      path: '/saved',
      builder: (_, _) => const Scaffold(body: Text('SAVED')),
    ),
  ],
);

Widget _app(GoRouter r, {double scale = 1}) => ProviderScope(
  overrides: [
    meProvider.overrideWith(
      (ref) async => const MeSession(
        account: AccountState.active,
        purpose: SignupPurpose.userToShop,
      ),
    ),
    adRepositoryProvider.overrideWithValue(
      DemoAdRepository(latency: Duration.zero),
    ),
  ],
  child: MaterialApp.router(
    routerConfig: r,
    builder: (c, child) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en'), Locale('ar')],
  ),
);

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

void _phone(WidgetTester t, {double w = 393, double h = 1800}) {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  group('taxonomy', () {
    test('the types offered per category are exactly the approved ones', () {
      List<PropertyType> of(PropCategory c) => [
        for (final e in kBrowseTypes[c]!) e.$1,
      ];
      expect(of(PropCategory.residential), [
        PropertyType.villa,
        PropertyType.apartment,
        PropertyType.residentialLand,
      ]);
      expect(of(PropCategory.commercial), [
        PropertyType.shop,
        PropertyType.office,
        PropertyType.commercialBuilding,
        PropertyType.warehouse,
        PropertyType.commercialLand,
      ]);
      expect(of(PropCategory.industrial), [
        PropertyType.investmentLand,
        PropertyType.industrial,
      ]);
      expect(of(PropCategory.agriculture), [
        PropertyType.agriculturalLand,
        PropertyType.farm,
      ]);
    });

    test('every offered type belongs to its category', () {
      for (final c in PropCategory.values) {
        for (final e in kBrowseTypes[c]!) {
          expect(c.matches(e.$1), isTrue, reason: '${e.$1} in $c');
        }
      }
    });

    test('rent hides only Residential Land and Commercial Land', () {
      for (final c in PropCategory.values) {
        final buy = browseTypesFor(c, TransactionType.buy);
        final rent = browseTypesFor(c, TransactionType.rent);
        expect(buy.length, kBrowseTypes[c]!.length);
        for (final e in rent) {
          expect(kSaleOnlyTypes.contains(e.$1), isFalse);
        }
        expect(rent, isNotEmpty, reason: 'every category keeps a rental type');
      }
      expect(isRentable(PropertyType.villa), isTrue);
      expect(isRentable(PropertyType.residentialLand), isFalse);
      expect(isRentable(PropertyType.commercialLand), isFalse);
      expect(isRentable(PropertyType.investmentLand), isTrue);
      expect(isRentable(PropertyType.agriculturalLand), isTrue);
    });
  });

  group('properties flow', () {
    testWidgets('Home itself offers Buy, Rent, Sell and My Favorites first', (
      t,
    ) async {
      _phone(t, h: 2600);
      await t.pumpWidget(_app(_router()));
      await _settle(t);
      final titles = [
        'Buy a property',
        'Rent a property',
        'Sell with Aqary e-Broker',
        'My Favorites',
      ];
      final rects = [for (final x in titles) t.getRect(find.text(x))];
      final search = t.getRect(find.byType(AQSearchEntry));
      for (final r in rects) {
        expect(r.top, lessThan(search.top), reason: 'above the search bar');
      }
      // two by two, each row aligned
      expect(rects[0].top, rects[1].top);
      expect(rects[2].top, rects[3].top);
      expect(rects[2].top, greaterThan(rects[0].top));
      // all four cards are exactly the same size
      final cards = find.byType(AQActionCard);
      expect(cards, findsNWidgets(4));
      final sizes = [for (var i = 0; i < 4; i++) t.getSize(cards.at(i))];
      for (final z in sizes) {
        expect(z, sizes.first, reason: 'equal-size cards');
      }
      // a card shows a photo
      expect(
        find.descendant(of: cards.first, matching: find.byType(Image)),
        findsWidgets,
      );
      // no second page of the same four actions
      expect(find.text('Properties'), findsNothing);
    });

    testWidgets(
      'Buy leads straight to the four categories, then straight to types',
      (t) async {
        _phone(t);
        final r = _router();
        await t.pumpWidget(_app(r));
        await _settle(t);
        await t.tap(find.text('Buy a property'));
        await _settle(t);
        for (final s in [
          'Residential',
          'Commercial',
          'Industrial',
          'Agriculture',
        ]) {
          expect(find.text(s), findsOneWidget, reason: s);
        }
        await t.tap(find.text('Commercial'));
        await _settle(t);
        for (final s in [
          'Shops',
          'Offices',
          'Building',
          'Storage',
          'Commercial Land',
        ]) {
          expect(find.text(s), findsOneWidget, reason: s);
        }
        expect(find.text('Buy a property'), findsNothing);
        await t.tap(find.text('Offices'));
        await _settle(t);
        expect(reached, '/properties/all?tx=buy&cat=commercial&types=office');
      },
    );

    testWidgets('Rent keeps the category step and only offers rentable types', (
      t,
    ) async {
      _phone(t);
      await t.pumpWidget(_app(_router()));
      await _settle(t);
      await t.tap(find.text('Rent a property'));
      await _settle(t);
      expect(find.text('Industrial'), findsOneWidget);
      await t.tap(find.text('Residential'));
      await _settle(t);
      expect(find.text('Villa'), findsOneWidget);
      expect(find.text('Apartment'), findsOneWidget);
      expect(find.text('Residential Land'), findsNothing);
      await t.tap(find.text('Villa'));
      await _settle(t);
      expect(reached, '/properties/all?tx=rent&cat=residential&types=villa');
    });

    testWidgets('going back keeps the transaction and category', (t) async {
      _phone(t);
      final r = _router();
      await t.pumpWidget(_app(r));
      await _settle(t);
      await t.tap(find.text('Rent a property'));
      await _settle(t);
      await t.tap(find.text('Industrial'));
      await _settle(t);
      expect(find.text('Factory'), findsOneWidget);
      expect(
        find.text('Land to invest'),
        findsOneWidget,
        reason: 'has rental ranges',
      );
      r.pop();
      await _settle(t);
      expect(find.text('Rent: choose a category'), findsOneWidget);
      r.pop();
      await _settle(t);
      expect(find.text('My Favorites'), findsOneWidget);
    });

    testWidgets('Sell and My Favorites open their own screens', (t) async {
      _phone(t);
      final r = _router();
      await t.pumpWidget(_app(r));
      await _settle(t);
      await t.tap(find.text('Sell with Aqary e-Broker'));
      await _settle(t);
      expect(find.text('SELL'), findsOneWidget);
      r.pop();
      await _settle(t);
      await t.tap(find.text('My Favorites'));
      await _settle(t);
      expect(find.text('SAVED'), findsOneWidget);
    });

    for (final w in [320.0, 360.0, 412.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('Home, categories and types fit at $w px, scale $scale', (
          t,
        ) async {
          _phone(t, w: w, h: 2400);
          for (final start in [
            '/',
            '/properties/categories?tx=buy',
            '/properties/types?tx=buy&cat=commercial',
            '/properties/types?tx=rent&cat=agriculture',
          ]) {
            await t.pumpWidget(_app(_router(start: start), scale: scale));
            await _settle(t);
            expect(t.takeException(), isNull, reason: '$start @ $w x$scale');
          }
        });
      }
    }
  });

  group('Home module grid', () {
    Widget home() => ProviderScope(
      overrides: [
        meProvider.overrideWith(
          (ref) async => const MeSession(
            account: AccountState.active,
            purpose: SignupPurpose.userToShop,
          ),
        ),
        adRepositoryProvider.overrideWithValue(
          DemoAdRepository(latency: Duration.zero),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(body: AQHomeScreen()),
            ),
            GoRoute(
              path: '/:p(.*)',
              builder: (_, s) => Scaffold(body: Text('AT ${s.uri}')),
            ),
          ],
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('ar')],
      ),
    );

    testWidgets('six services, in order, under Explore more', (t) async {
      _phone(t, h: 2600);
      await t.pumpWidget(home());
      await _settle(t);
      final order = [
        'Development',
        'Architecture',
        'Interior & Exterior Designer',
        'Construction Company',
        'Loan Calculator',
        'Maintenance',
      ];
      final tops = <double>[];
      final lefts = <double>[];
      for (final s in order) {
        final f = find.descendant(
          of: find.byType(AQModuleGrid),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.label == s &&
                w.properties.button == true,
          ),
        );
        expect(f, findsOneWidget, reason: s);
        final r = t.getRect(f);
        tops.add(r.top);
        lefts.add(r.left);
      }
      // reading order: row by row, left to right
      for (var i = 1; i < order.length; i++) {
        final sameRowAfter = tops[i] == tops[i - 1] && lefts[i] > lefts[i - 1];
        final nextRow = tops[i] > tops[i - 1];
        expect(sameRowAfter || nextRow, isTrue, reason: order[i]);
      }
      final more = t.getRect(find.text('Explore more with AQARATI'));
      expect(tops.first, greaterThan(more.bottom - 1));
      expect(
        find.text('Properties'),
        findsNothing,
        reason: 'no generic Properties tile',
      );
    });

    testWidgets('each module opens its own journey', (t) async {
      _phone(t, h: 2600);
      final expected = {
        'Development': '/app/explore/build/results?cat=developer',
        'Architecture': '/app/explore/build/results?cat=architecture',
        'Interior & Exterior Designer':
            '/app/explore/build/results?cat=interiorExterior',
        'Construction Company': '/app/explore/build/results?cat=construction',
        'Loan Calculator': '/calculators',
        'Maintenance': '/professionals?cat=maintenance',
      };
      for (final e in expected.entries) {
        await t.pumpWidget(home());
        await _settle(t);
        await t.tap(
          find.descendant(
            of: find.byType(AQModuleGrid),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Semantics &&
                  w.properties.label == e.key &&
                  w.properties.button == true,
            ),
          ),
        );
        await _settle(t);
        expect(find.text('AT ${e.value}'), findsOneWidget, reason: e.key);
      }
    });

    for (final w in [320.0, 360.0, 412.0]) {
      testWidgets('the grid does not overflow at $w px or at 200% text', (
        t,
      ) async {
        _phone(t, w: w, h: 2600);
        await t.pumpWidget(home());
        await _settle(t);
        expect(t.takeException(), isNull);
      });
    }
  });

  group('entry experience', () {
    test('each experience opens its own signup and login', () {
      expect(EntryExperience.user.signupRoute, '/signup/user');
      expect(EntryExperience.agent.signupRoute, '/signup/agent');
      expect(EntryExperience.user.loginRoute, '/login?as=user');
      expect(EntryExperience.agent.loginRoute, '/login?as=agent');
      expect(entryExperienceFrom('agent'), EntryExperience.agent);
      expect(
        entryExperienceFrom('admin'),
        isNull,
        reason: 'an unknown door grants nothing',
      );
    });

    test('all six public signup roles are still offered', () {
      expect(signupPurposeOptions.length, 6);
      expect(
        {for (final o in signupPurposeOptions) o.id},
        {
          SignupPurpose.userToShop,
          SignupPurpose.realEstateAgent,
          SignupPurpose.propertyDevelopmentCompany,
          SignupPurpose.constructionCompany,
          SignupPurpose.buildingArchitecture,
          SignupPurpose.interiorExteriorDesign,
        },
      );
    });

    test('the account, not the chosen door, decides the destination', () {
      const agent = MeSession(
        account: AccountState.active,
        purpose: SignupPurpose.realEstateAgent,
        grant: GrantState.approved,
      );
      const buyer = MeSession(
        account: AccountState.active,
        purpose: SignupPurpose.userToShop,
      );
      const agentPending = MeSession(
        account: AccountState.active,
        purpose: SignupPurpose.realEstateAgent,
        grant: GrantState.pendingVerification,
      );
      expect(routeForSession(agent), '/app/home');
      expect(routeForSession(buyer), '/app/home');
      expect(routeForSession(agentPending), '/verification');
    });

    for (final x in ['user', 'agent']) {
      for (final w in [320.0, 360.0, 390.0, 412.0, 430.0]) {
        for (final h in [568.0, 852.0]) {
          testWidgets('login ($x) keeps a gap under the role pill at $w x $h', (
            t,
          ) async {
            _phone(t, w: w, h: h);
            await t.pumpWidget(
              ProviderScope(
                child: MaterialApp(
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: const [Locale('en'), Locale('ar')],
                  home: LoginScreen(experience: x),
                ),
              ),
            );
            await _settle(t);
            double gap() {
              final pill = t.getRect(find.byType(AQNoticeCard));
              final email = t.getRect(find.byType(AQTextField).first);
              return email.top - pill.bottom;
            }

            expect(gap(), greaterThanOrEqualTo(12));
            // a validation message must not collapse it
            await t.tap(find.text('Log in').last);
            await _settle(t);
            expect(gap(), greaterThanOrEqualTo(12));
            expect(t.takeException(), isNull);
          });
        }
      }
    }

    testWidgets('login names the experience it was opened for', (t) async {
      _phone(t);
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ar')],
            home: const LoginScreen(experience: 'agent'),
          ),
        ),
      );
      await _settle(t);
      expect(find.textContaining('Real Estate Agent'), findsWidgets);
    });
  });
}
