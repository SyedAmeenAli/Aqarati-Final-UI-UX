import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/features/ads/ad_models.dart';
import 'package:aqarati_app/features/ads/ad_repository.dart';
import 'package:aqarati_app/features/ads/sponsored_banner.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _me = MeSession(
  account: AccountState.active,
  purpose: SignupPurpose.userToShop,
);

AdDraft draft(
  String sponsor, {
  String headline = 'Headline',
  DateTime? starts,
  DateTime? ends,
}) => AdDraft(
  sponsor: sponsor,
  headline: headline,
  body: 'Body',
  cta: 'Visit',
  destination: 'https://example.test/offer',
  imageRef: 'assets/location/11_Muscat_skyline_and_mountains.jpg',
  startsAt: starts,
  endsAt: ends,
);

Widget host(Widget child, {AdRepository? repo, MeSession? me = _me}) =>
    ProviderScope(
      overrides: [
        meProvider.overrideWith((ref) async {
          if (me == null) throw const ApiException(ApiErrorCode.network);
          return me;
        }),
        if (repo != null) adRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: child),
      ),
    );

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

DemoAdRepository repo() => DemoAdRepository(latency: Duration.zero);

void main() {
  group('what the customer app is served', () {
    test('only approved ads inside their schedule, in order', () async {
      final r = repo();
      final now = DateTime(2026, 10, 20);
      final r2 = DemoAdRepository(latency: Duration.zero, clock: () => now);
      r2.debugAdd(draft('Live A'));
      r2.debugAdd(draft('Paused'), status: AdStatus.paused);
      r2.debugAdd(draft('Pending'), status: AdStatus.pendingVerification);
      r2.debugAdd(draft('Draft'), status: AdStatus.draft);
      r2.debugAdd(draft('Rejected'), status: AdStatus.rejected);
      r2.debugAdd(draft('Future', starts: DateTime(2026, 11, 1)));
      r2.debugAdd(draft('Past', ends: DateTime(2026, 10, 1)));
      r2.debugAdd(
        draft(
          'Live B',
          starts: DateTime(2026, 10, 1),
          ends: DateTime(2026, 12, 1),
        ),
      );
      final served = await r2.served(AdPlacement.homeTop);
      expect(served.map((a) => a.sponsor), ['Live A', 'Live B']);
      expect(await r.served(AdPlacement.homeTop), isEmpty);
    });

    test(
      'the rotation interval is five seconds',
      () => expect(kAdRotation, const Duration(seconds: 5)),
    );
  });

  group('the banner slot', () {
    testWidgets('shows nothing when there are no eligible ads', (t) async {
      await t.pumpWidget(host(const SponsoredBannerSlot(), repo: repo()));
      await settle(t);
      expect(find.byType(SponsoredBannerView), findsNothing);
    });

    testWidgets(
      'shows nothing, and no error, when the service is unreachable',
      (t) async {
        await t.pumpWidget(
          host(
            const SponsoredBannerSlot(),
            repo: const UnavailableAdRepository(),
          ),
        );
        await settle(t);
        expect(find.byType(SponsoredBannerView), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets('never shows to a signed-out visitor', (t) async {
      final r = repo()..debugAdd(draft('Acme'));
      await t.pumpWidget(host(const SponsoredBannerSlot(), repo: r, me: null));
      await settle(t);
      expect(find.byType(SponsoredBannerView), findsNothing);
    });

    testWidgets('is the existing banner component, labelled Sponsored', (
      t,
    ) async {
      final r = repo()..debugAdd(draft('Acme', headline: 'Spring offer'));
      await t.pumpWidget(host(const SponsoredBannerSlot(), repo: r));
      await settle(t);
      expect(find.byType(SponsoredBannerView), findsOneWidget);
      expect(find.text('SPONSORED · Acme'), findsOneWidget);
      expect(find.text('Spring offer'), findsOneWidget);
      expect(find.text('Visit'), findsOneWidget);
    });

    testWidgets('rotates to the next ad every five seconds and wraps around', (
      t,
    ) async {
      final r = repo()
        ..debugAdd(draft('First', headline: 'One'))
        ..debugAdd(draft('Second', headline: 'Two'));
      await t.pumpWidget(host(const SponsoredBannerSlot(), repo: r));
      await settle(t);
      expect(find.text('One'), findsOneWidget);
      await t.pump(const Duration(seconds: 4));
      expect(find.text('One'), findsOneWidget);
      await t.pump(const Duration(seconds: 1, milliseconds: 600));
      expect(find.text('Two'), findsOneWidget);
      await t.pump(const Duration(seconds: 5, milliseconds: 600));
      expect(find.text('One'), findsOneWidget);
    });

    testWidgets('a single ad does not rotate', (t) async {
      final r = repo()..debugAdd(draft('Only', headline: 'Alone'));
      await t.pumpWidget(host(const SponsoredBannerSlot(), repo: r));
      await settle(t);
      await t.pump(const Duration(seconds: 12));
      expect(find.text('Alone'), findsOneWidget);
    });

    testWidgets(
      'the admin preview uses the very same widget as the live slot',
      (t) async {
        final ad = DemoAdRepository(latency: Duration.zero)
            .debugAdd(draft('Acme'));
        await t.pumpWidget(host(SponsoredBannerView(ads: [ad], onTap: (_) {})));
        await settle(t);
        expect(find.byType(SponsoredBannerView), findsOneWidget);
        expect(find.text('SPONSORED · Acme'), findsOneWidget);
      },
    );
  });
}
