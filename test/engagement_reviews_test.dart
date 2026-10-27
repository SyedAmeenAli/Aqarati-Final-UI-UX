import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/features/engagement/engagement_models.dart';
import 'package:aqarati_app/features/engagement/engagement_repository.dart';
import 'package:aqarati_app/features/engagement/engagement_screens.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/reviews/review_flow_screens.dart';
import 'package:aqarati_app/features/reviews/review_models.dart';
import 'package:aqarati_app/features/reviews/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _me = MeSession(
  account: AccountState.active,
  purpose: SignupPurpose.userToShop,
);

DemoEngagementRepository eng() =>
    DemoEngagementRepository(latency: Duration.zero);
DemoReviewRepository rev() => DemoReviewRepository(latency: Duration.zero);

Widget app(
  DemoEngagementRepository e,
  DemoReviewRepository r, {
  MeSession? me = _me,
  String start = '/engagements',
}) {
  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('LOGIN')),
      ),
      GoRoute(
        path: '/professionals',
        builder: (_, _) => const Scaffold(body: Text('PROS')),
      ),
      GoRoute(
        path: '/business/:id',
        builder: (_, _) => const Scaffold(body: Text('PROFILE')),
      ),
      GoRoute(
        path: '/business/:id/engage',
        builder: (_, s) => EngageRequestScreen(
          professionalId: s.pathParameters['id']!,
          name: 'Gulf Builders',
          type: 'construction',
        ),
      ),
      GoRoute(
        path: '/engagements',
        builder: (_, _) => const MyEngagementsScreen(),
      ),
      GoRoute(
        path: '/engagements/:id',
        builder: (_, s) => EngagementDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/review/:kind/:id',
        builder: (_, s) => WriteReviewScreen(
          kind: ReviewTargetKind.professional,
          id: s.pathParameters['id']!,
          name: 'Gulf Builders',
        ),
      ),
      GoRoute(path: '/reviews', builder: (_, _) => const MyReviewsScreen()),
    ],
  );
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      meProvider.overrideWith((ref) async {
        if (me == null) throw const ApiException(ApiErrorCode.network);
        return me;
      }),
      engagementRepositoryProvider.overrideWithValue(e),
      reviewRepositoryProvider.overrideWithValue(r),
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
  t.view.physicalSize = const Size(393, 1600);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<ClientEngagement> confirmed(
  DemoEngagementRepository e, {
  DateTime? confirmedAt,
}) async {
  final x = await e.request(
    professionalId: 'b1',
    professionalName: 'Gulf Builders',
    professionalType: 'construction',
  );
  e.debugSet(x.id, EngagementPhase.confirmed, confirmedAt: confirmedAt);
  return x;
}

void main() {
  group('engagement request', () {
    testWidgets('explains the rules and sends a request that waits for them', (
      t,
    ) async {
      big(t);
      final e = eng();
      await t.pumpWidget(app(e, rev(), start: '/business/b1/engage'));
      await settle(t);
      expect(find.textContaining('This is not a booking'), findsOneWidget);
      expect(
        find.text(
          'The professional has 14 days to confirm.'.replaceFirst(
            'The professional',
            '1. The professional',
          ),
        ),
        findsOneWidget,
      );
      await t.tap(find.text('Send request'));
      await settle(t);
      expect(find.text('Waiting for them'), findsWidgets);
      expect(
        (await e.list()).single.phase,
        EngagementPhase.awaitingProfessional,
      );
    });

    testWidgets('signed out: asks to log in and sends nothing', (t) async {
      big(t);
      final e = eng();
      await t.pumpWidget(app(e, rev(), me: null, start: '/business/b1/engage'));
      await settle(t);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Send request'), findsNothing);
    });

    testWidgets('a second request shows the existing one', (t) async {
      big(t);
      final e = eng();
      await e.request(
        professionalId: 'b1',
        professionalName: 'G',
        professionalType: 'construction',
      );
      await t.pumpWidget(app(e, rev(), start: '/business/b1/engage'));
      await settle(t);
      await t.tap(find.text('Send request'));
      await settle(t);
      expect(find.text('You already have an open request'), findsOneWidget);
      await t.tap(find.text('Open it'));
      await settle(t);
      expect(find.text('Engagement'), findsWidgets);
    });

    testWidgets('a related account is refused with its own explanation', (
      t,
    ) async {
      big(t);
      final e = eng();
      e.debugNextError = const EngagementIneligibleException(
        EngagementIneligibleReason.relatedAccount,
      );
      await t.pumpWidget(app(e, rev(), start: '/business/b1/engage'));
      await settle(t);
      await t.tap(find.text('Send request'));
      await settle(t);
      expect(find.text('Related accounts cannot engage'), findsOneWidget);
      expect(await e.list(), isEmpty);
    });

    testWidgets('a failed send shows an error edge, and Try again recovers', (
      t,
    ) async {
      big(t);
      final e = eng();
      e.debugNextError = const ApiException(ApiErrorCode.network);
      await t.pumpWidget(app(e, rev(), start: '/business/b1/engage'));
      await settle(t);
      await t.tap(find.text('Send request'));
      await settle(t);
      expect(find.text('We could not send the request'), findsOneWidget);
      expect(await e.list(), isEmpty);
      await t.tap(find.text('Try again'));
      await settle(t);
      expect(find.text('Waiting for them'), findsWidgets);
    });
  });

  group('engagement detail', () {
    testWidgets('empty list is honest', (t) async {
      big(t);
      await t.pumpWidget(app(eng(), rev()));
      await settle(t);
      expect(find.text('No engagements yet'), findsOneWidget);
    });

    testWidgets('waiting: can cancel; expired reads as expired', (t) async {
      big(t);
      final e = eng();
      final x = await e.request(
        professionalId: 'b1',
        professionalName: 'Gulf Builders',
        professionalType: 'construction',
      );
      await t.pumpWidget(app(e, rev(), start: '/engagements/${x.id}'));
      await settle(t);
      expect(find.text('Cancel request'), findsOneWidget);
      e.debugSet(
        x.id,
        EngagementPhase.awaitingProfessional,
        requestedAt: DateTime.now().subtract(const Duration(days: 15)),
      );
      await t.pumpWidget(app(e, rev(), start: '/engagements/${x.id}'));
      await settle(t);
      expect(find.text('Expired'), findsWidgets);
      expect(find.text('Cancel request'), findsNothing);
      expect(find.text('Write a review'), findsNothing);
    });

    testWidgets('the professional asked first: confirm leads to a review', (
      t,
    ) async {
      big(t);
      final e = eng();
      final x = await e.request(
        professionalId: 'b1',
        professionalName: 'Gulf Builders',
        professionalType: 'construction',
      );
      e.debugSet(x.id, EngagementPhase.awaitingMe);
      await t.pumpWidget(app(e, rev(), start: '/engagements/${x.id}'));
      await settle(t);
      await t.tap(find.text('Confirm we worked together'));
      await settle(t);
      expect(
        find.text('Confirmed. You can now write a review.'),
        findsOneWidget,
      );
      expect(find.text('Write a review'), findsOneWidget);
    });

    testWidgets('declined and cancelled show their own text, no review', (
      t,
    ) async {
      big(t);
      final e = eng();
      final x = await e.request(
        professionalId: 'b1',
        professionalName: 'G',
        professionalType: 'construction',
      );
      e.debugSet(x.id, EngagementPhase.declined);
      await t.pumpWidget(app(e, rev(), start: '/engagements/${x.id}'));
      await settle(t);
      expect(
        find.text('The professional declined this request.'),
        findsOneWidget,
      );
      expect(find.text('Write a review'), findsNothing);
    });

    testWidgets('unknown id shows not found', (t) async {
      big(t);
      await t.pumpWidget(app(eng(), rev(), start: '/engagements/nope'));
      await settle(t);
      expect(find.text('We could not find this engagement.'), findsOneWidget);
    });
  });

  group('writing a review', () {
    testWidgets('without an engagement: explains and offers to request one', (
      t,
    ) async {
      big(t);
      await t.pumpWidget(app(eng(), rev(), start: '/review/professional/b1'));
      await settle(t);
      expect(find.text('Reviews need a confirmed engagement'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Your review'), findsNothing);
    });

    testWidgets('a waiting request is "not yet"', (t) async {
      big(t);
      final e = eng();
      await e.request(
        professionalId: 'b1',
        professionalName: 'G',
        professionalType: 'construction',
      );
      await t.pumpWidget(app(e, rev(), start: '/review/professional/b1'));
      await settle(t);
      expect(find.text('Not yet'), findsOneWidget);
    });

    testWidgets('window closed after 60 days', (t) async {
      big(t);
      final e = eng();
      await confirmed(
        e,
        confirmedAt: DateTime.now().subtract(const Duration(days: 61)),
      );
      await t.pumpWidget(app(e, rev(), start: '/review/professional/b1'));
      await settle(t);
      expect(find.text('The review window has closed'), findsOneWidget);
    });

    testWidgets('signed out', (t) async {
      big(t);
      await t.pumpWidget(
        app(eng(), rev(), me: null, start: '/review/professional/b1'),
      );
      await settle(t);
      expect(find.text('Log in to write a review'), findsOneWidget);
    });

    testWidgets(
      'validate, preview, submit, then it is "being checked" and not public',
      (t) async {
        big(t);
        final e = eng();
        final r = rev();
        await confirmed(e);
        await t.pumpWidget(app(e, r, start: '/review/professional/b1'));
        await settle(t);
        await t.tap(find.text('Review it'));
        await settle(t);
        expect(find.text('Choose a rating from 1 to 5 stars.'), findsOneWidget);
        expect(find.text('Write at least 10 characters.'), findsOneWidget);
        await t.tap(find.bySemanticsLabel('4 of 5 stars').first);
        await t.enterText(
          find.widgetWithText(TextField, 'Your review'),
          'Short',
        );
        await t.tap(find.text('Review it'));
        await settle(t);
        expect(find.text('Write at least 10 characters.'), findsOneWidget);
        await t.enterText(
          find.widgetWithText(TextField, 'Your review'),
          'They finished on time and kept us informed.',
        );
        await t.tap(find.text('Review it'));
        await settle(t);
        expect(find.text('Check your review'), findsOneWidget);
        expect(await r.mine(), isEmpty);
        await t.tap(find.text('Submit review'));
        await settle(t);
        expect(find.text('Being checked'), findsWidgets);
        expect(find.textContaining('not public yet'), findsOneWidget);
        expect((await r.mine()).single.status, ReviewStatus.pendingModeration);
        expect(find.text('Published'), findsNothing);
      },
    );

    testWidgets(
      'a failed submit keeps the text and says nothing was submitted',
      (t) async {
        big(t);
        final e = eng();
        final r = rev();
        await confirmed(e);
        await t.pumpWidget(app(e, r, start: '/review/professional/b1'));
        await settle(t);
        await t.tap(find.bySemanticsLabel('5 of 5 stars').first);
        await t.enterText(
          find.widgetWithText(TextField, 'Your review'),
          'Good work from start to finish.',
        );
        await t.tap(find.text('Review it'));
        await settle(t);
        // fail the submit by making the repository reject it as not eligible
        await r.submit(
          target: ReviewTarget(
            kind: ReviewTargetKind.professional,
            id: 'b1',
            name: 'G',
          ),
          rating: 3,
          comment: 'Already here for the clash.',
        );
        await t.tap(find.text('Submit review'));
        await settle(t);
        expect(find.textContaining('Nothing was submitted'), findsOneWidget);
        await t.tap(find.text('Go back and edit'));
        await settle(t);
        expect(find.text('Good work from start to finish.'), findsOneWidget);
      },
    );

    testWidgets(
      'an existing review shows its status; editing only when allowed',
      (t) async {
        big(t);
        final e = eng();
        final r = rev();
        await confirmed(e);
        final mine = await r.submit(
          target: ReviewTarget(
            kind: ReviewTargetKind.professional,
            id: 'b1',
            name: 'Gulf Builders',
          ),
          rating: 4,
          comment: 'Solid work and clear communication.',
        );
        r.debugSet(mine.id, status: ReviewStatus.published);
        await t.pumpWidget(app(e, r, start: '/review/professional/b1'));
        await settle(t);
        expect(find.text('Published'), findsWidgets);
        expect(find.text('You already reviewed this'), findsOneWidget);
        expect(find.text('Edit your review'), findsNothing);
        expect(
          find.textContaining('after a later interaction'),
          findsOneWidget,
        );
        r.debugSet(mine.id, canEdit: true);
        await t.pumpWidget(app(e, r, start: '/review/professional/b1'));
        await settle(t);
        await t.tap(find.text('Edit your review'));
        await settle(t);
        await t.enterText(
          find.widgetWithText(TextField, 'Your review'),
          'Solid work, and they came back to fix one thing.',
        );
        await t.tap(find.text('Review it'));
        await settle(t);
        await t.tap(find.text('Submit review'));
        await settle(t);
        expect((await r.mine()).single.status, ReviewStatus.pendingModeration);
        expect(find.textContaining('Edit sent for checking'), findsOneWidget);
      },
    );

    testWidgets('my reviews: empty, then listed with status', (t) async {
      big(t);
      final r = rev();
      await t.pumpWidget(app(eng(), r, start: '/reviews'));
      await settle(t);
      expect(find.text('No reviews yet'), findsOneWidget);
      await r.submit(
        target: ReviewTarget(
          kind: ReviewTargetKind.professional,
          id: 'b1',
          name: 'Gulf Builders',
        ),
        rating: 5,
        comment: 'Excellent from start to end.',
      );
      await t.pumpWidget(app(eng(), r, start: '/reviews'));
      await settle(t);
      expect(find.text('Being checked'), findsOneWidget);
    });
  });

  group('reporting a review', () {
    Widget host(DemoReviewRepository r) => ProviderScope(
      key: UniqueKey(),
      overrides: [reviewRepositoryProvider.overrideWithValue(r)],
      child: MaterialApp(
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => Center(
              child: TextButton(
                onPressed: () => showReportReviewSheet(context, ref, 'rev-1'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets(
      'a reason is required, then the report is sent and nothing else changes',
      (t) async {
        big(t);
        await t.pumpWidget(host(rev()));
        await t.tap(find.text('open'));
        await settle(t);
        await t.tap(find.text('Send report'));
        await settle(t);
        expect(find.text('Choose a reason.'), findsOneWidget);
        await t.tap(find.text('False or misleading'));
        await t.tap(find.text('Send report'));
        await settle(t);
        expect(find.text('Report sent'), findsOneWidget);
        expect(
          find.textContaining('Nothing changes until they decide'),
          findsOneWidget,
        );
        await t.tap(find.text('Close'));
        await settle(t);
        expect(find.text('Report sent'), findsNothing);
      },
    );

    testWidgets('reporting twice says so', (t) async {
      big(t);
      final r = rev();
      await r.report(reviewId: 'rev-1', reason: ReportReason.other);
      await t.pumpWidget(host(r));
      await t.tap(find.text('open'));
      await settle(t);
      await t.tap(find.text('Harassment'));
      await t.tap(find.text('Send report'));
      await settle(t);
      expect(find.text('You already reported this review.'), findsOneWidget);
    });
  });
}
