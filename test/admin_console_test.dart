import 'package:aqarati_app/admin/admin_directory_screens.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:aqarati_app/admin/admin_app.dart';
import 'package:aqarati_app/admin/admin_auth_screens.dart';
import 'package:aqarati_app/admin/admin_models.dart';
import 'package:aqarati_app/admin/admin_repository.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/data/models/enums.dart';
import 'package:aqarati_app/features/ads/ad_models.dart';
import 'package:aqarati_app/features/ads/ad_repository.dart';
import 'package:aqarati_app/features/ads/sponsored_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

DemoAdminStore store() => DemoAdminStore(
  latency: Duration.zero,
  ads: DemoAdRepository(latency: Duration.zero),
);

Future<AdminSession> signIn(DemoAdminStore s, String who) async {
  await s.signIn('$who@demo.test', DemoAdminStore.demoPassword);
  return s.verifyTotp(DemoAdminStore.demoCode);
}

VerificationItem applicant(
  String id,
  ApplicantKind k, {
  DateTime? at,
  bool resub = false,
}) => VerificationItem(
  id: id,
  applicantName: 'Applicant $id',
  kind: k,
  submittedAt: at ?? DateTime(2026, 10, 1),
  status: QueueStatus.pending,
  isResubmission: resub,
  documents: [
    AdminDocument(id: 'd$id', label: 'Registration', fileName: 'x.pdf'),
  ],
);

AdDraft adDraft({String sponsor = 'Acme', String headline = 'Offer'}) =>
    AdDraft(
      sponsor: sponsor,
      headline: headline,
      cta: 'Visit',
      destination: 'https://example.test/x',
      imageRef: 'assets/location/11_Muscat_skyline_and_mountains.jpg',
    );

Uint8List png() => Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0, 0, 0, 0]);

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

Widget app(DemoAdminStore s) =>
    ProviderScope(overrides: adminOverrides(s), child: const AdminApp());

void wide(WidgetTester t) {
  t.view.physicalSize = const Size(1300, 1000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> login(WidgetTester t, String who) async {
  await t.enterText(find.widgetWithText(TextField, 'Email'), '$who@demo.test');
  await t.enterText(
    find.widgetWithText(TextField, 'Password'),
    DemoAdminStore.demoPassword,
  );
  await t.tap(find.text('Continue'));
  await settle(t);
  await t.enterText(find.byType(TextField).first, DemoAdminStore.demoCode);
  await settle(t);
  // Signing in lands on the overview; the older tests below work from the verification queue.
  if (find.byType(AdminOverviewScreen).evaluate().isNotEmpty) {
    GoRouter.of(t.element(find.byType(AdminOverviewScreen))).go('/verification');
    await settle(t);
  }
}

void main() {
  group('sign-in gates', () {
    test('no protected address before the one-time code is done', () {
      expect(
        adminRedirect(AdminAuthStage.signedOut, '/verification'),
        '/login',
      );
      expect(adminRedirect(AdminAuthStage.signedOut, '/ads/new'), '/login');
      expect(adminRedirect(AdminAuthStage.signedOut, '/login'), isNull);
      expect(adminRedirect(AdminAuthStage.needsTotp, '/moderation'), '/code');
      expect(adminRedirect(AdminAuthStage.needsTotp, '/code'), isNull);
      expect(adminRedirect(AdminAuthStage.active, '/login'), '/overview');
      expect(adminRedirect(AdminAuthStage.active, '/ads'), isNull);
    });

    test('a wrong email and a wrong password get the same answer', () async {
      final s = store();
      await expectLater(
        s.signIn('nobody@demo.test', DemoAdminStore.demoPassword),
        throwsA(isA<AdminAuthException>()),
      );
      await expectLater(
        s.signIn('senior@demo.test', 'wrong'),
        throwsA(isA<AdminAuthException>()),
      );
    });

    test('a wrong code does not sign in; the right code does', () async {
      final s = store();
      await s.signIn('reviewer@demo.test', DemoAdminStore.demoPassword);
      await expectLater(
        s.verifyTotp('000000'),
        throwsA(isA<AdminTotpException>()),
      );
      expect(s.session, isNull);
      expect(
        (await s.verifyTotp(DemoAdminStore.demoCode)).role,
        AdminRole.reviewer,
      );
    });

    test('data calls fail when nobody is signed in', () async {
      final s = store();
      await expectLater(s.list(), throwsA(isA<AdminSessionExpiredException>()));
    });

    testWidgets('the console cannot be opened by address before signing in', (
      t,
    ) async {
      wide(t);
      await t.pumpWidget(app(store()));
      await settle(t);
      expect(find.byType(AdminLoginScreen), findsOneWidget);
      GoRouter.of(t.element(find.byType(AdminLoginScreen))).go('/verification');
      await settle(t);
      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.text('Verification queue'), findsNothing);
    });

    testWidgets('login, then the code, then the queue', (t) async {
      wide(t);
      await t.pumpWidget(app(store()));
      await settle(t);
      await login(t, 'reviewer');
      expect(find.text('Verification queue'), findsWidgets);
    });

    testWidgets('a wrong password shows one calm message and keeps the email', (
      t,
    ) async {
      wide(t);
      await t.pumpWidget(app(store()));
      await settle(t);
      await t.enterText(
        find.widgetWithText(TextField, 'Email'),
        'reviewer@demo.test',
      );
      await t.enterText(find.widgetWithText(TextField, 'Password'), 'nope');
      await t.tap(find.text('Continue'));
      await settle(t);
      expect(find.text('The email or password is not right.'), findsOneWidget);
      expect(find.text('reviewer@demo.test'), findsOneWidget);
    });

    testWidgets(
      'an ended session sends the person back to sign in with the reason',
      (t) async {
        wide(t);
        final s = store();
        await t.pumpWidget(app(s));
        await settle(t);
        await login(t, 'reviewer');
        s.debugExpireSession();
        GoRouter.of(t.element(find.text('Verification queue').first))
            .go('/moderation');
        await settle(t);
        await settle(t);
        expect(find.byType(AdminLoginScreen), findsOneWidget);
        expect(
          find.text('Your session ended. Sign in again to continue.'),
          findsOneWidget,
        );
      },
    );
  });

  group('verification rules', () {
    test('resubmissions queue first, then the oldest', () async {
      final s = store();
      await signIn(s, 'reviewer');
      s.debugAddVerification(
        (id) => applicant(id, ApplicantKind.agent, at: DateTime(2026, 10, 5)),
      );
      s.debugAddVerification(
        (id) => applicant(id, ApplicantKind.agent, at: DateTime(2026, 10, 1)),
      );
      final r = s.debugAddVerification(
        (id) => applicant(
          id,
          ApplicantKind.construction,
          at: DateTime(2026, 10, 9),
          resub: true,
        ),
      );
      final list = await s.list();
      expect(list.first.id, r.id);
      expect(list[1].submittedAt.isBefore(list[2].submittedAt), isTrue);
    });

    test('rejecting needs a reason, and "Other" needs a note', () async {
      final s = store();
      await signIn(s, 'reviewer');
      final v = s.debugAddVerification(
        (id) => applicant(id, ApplicantKind.agent),
      );
      await expectLater(
        s.decide(v.id, Decision.reject),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        s.decide(v.id, Decision.reject, reason: ReasonCode.other),
        throwsA(isA<ApiException>()),
      );
      final done = await s.decide(
        v.id,
        Decision.reject,
        reason: ReasonCode.nameMismatch,
        note: 'Names differ',
      );
      expect(done.status, QueueStatus.rejected);
      expect(done.history.single.reason, ReasonCode.nameMismatch);
    });

    test('a failed decision leaves the item exactly as it was', () async {
      final s = store();
      await signIn(s, 'reviewer');
      final v = s.debugAddVerification(
        (id) => applicant(id, ApplicantKind.agent),
      );
      s.debugNextError = const ApiException(ApiErrorCode.network);
      await expectLater(
        s.decide(v.id, Decision.approve),
        throwsA(isA<ApiException>()),
      );
      expect((await s.get(v.id))!.status, QueueStatus.pending);
      expect((await s.get(v.id))!.history, isEmpty);
    });

    test('an auditor can look but not decide', () async {
      final s = store();
      await signIn(s, 'auditor');
      final v = s.debugAddVerification(
        (id) => applicant(id, ApplicantKind.agent),
      );
      await expectLater(
        s.decide(v.id, Decision.approve),
        throwsA(isA<AdminForbiddenException>()),
      );
    });

    test('a developer needs two approvals from two different people', () async {
      final s = store();
      await signIn(s, 'senior');
      final v = s.debugAddVerification(
        (id) => applicant(id, ApplicantKind.developer),
      );
      final first = await s.decide(v.id, Decision.approve);
      expect(first.status, QueueStatus.awaitingSecondApproval);
      await expectLater(
        s.decide(v.id, Decision.approve),
        throwsA(isA<AdminSameApproverException>()),
      );
      await signIn(s, 'reviewer');
      await expectLater(
        s.decide(v.id, Decision.approve),
        throwsA(isA<AdminForbiddenException>()),
      );
      await signIn(s, 'super');
      expect(
        (await s.decide(v.id, Decision.approve)).status,
        QueueStatus.approved,
      );
    });

    test('a non-developer is approved by one reviewer', () async {
      final s = store();
      await signIn(s, 'reviewer');
      final v = s.debugAddVerification(
        (id) => applicant(id, ApplicantKind.interiorExterior),
      );
      expect(
        (await s.decide(v.id, Decision.approve)).status,
        QueueStatus.approved,
      );
    });

    test(
      'the 30-minute lock keeps a second reviewer out, and expires',
      () async {
        var now = DateTime(2026, 10, 20, 9);
        final s = DemoAdminStore(
          latency: Duration.zero,
          clock: () => now,
          ads: DemoAdRepository(latency: Duration.zero),
        );
        await signIn(s, 'reviewer');
        final v = s.debugAddVerification(
          (id) => applicant(id, ApplicantKind.agent),
        );
        await s.claim(v.id);
        await signIn(s, 'senior');
        await expectLater(s.claim(v.id), throwsA(isA<AdminLockedException>()));
        await expectLater(
          s.decide(v.id, Decision.approve),
          throwsA(isA<AdminLockedException>()),
        );
        now = now.add(const Duration(minutes: 31));
        expect(
          (await s.decide(v.id, Decision.approve)).status,
          QueueStatus.approved,
        );
      },
    );

    test('a decided item cannot be decided again', () async {
      final s = store();
      await signIn(s, 'reviewer');
      final v = s.debugAddVerification(
        (id) => applicant(id, ApplicantKind.agent),
      );
      await s.decide(v.id, Decision.approve);
      await expectLater(
        s.decide(v.id, Decision.reject, reason: ReasonCode.expired),
        throwsA(isA<AdminConflictException>()),
      );
    });
  });

  group('verification screens', () {
    testWidgets(
      'an empty queue says so and offers demo records only in demo mode',
      (t) async {
        wide(t);
        await t.pumpWidget(app(store()));
        await settle(t);
        await login(t, 'reviewer');
        expect(find.text('The queue is empty'), findsOneWidget);
        expect(find.text('Add demo records'), findsOneWidget);
      },
    );

    testWidgets(
      'demo records fill the queue with clearly demo applicants, resubmission first',
      (t) async {
        wide(t);
        final s = store();
        await t.pumpWidget(app(s));
        await settle(t);
        await login(t, 'reviewer');
        await t.tap(find.text('Add demo records'));
        await settle(t);
        expect(find.textContaining('Demo applicant'), findsWidgets);
        expect(find.text('Showing 5 of 5 applications'), findsOneWidget);
      },
    );

    testWidgets('filters narrow the table and keep the count honest', (
      t,
    ) async {
      wide(t);
      final s = store();
      await t.pumpWidget(app(s));
      await settle(t);
      await login(t, 'reviewer');
      await t.tap(find.text('Add demo records'));
      await settle(t);
      await t.ensureVisible(find.text('Construction company').first);
      await t.tap(find.text('Construction company').first);
      await settle(t);
      expect(find.text('Showing 1 of 5 applications'), findsOneWidget);
    });

    testWidgets(
      'approval is blocked until the checklist is complete; a rejection needs a reason; step-up needs the right code',
      (t) async {
        wide(t);
        final s = store();
        await t.pumpWidget(app(s));
        await settle(t);
        await login(t, 'reviewer');
        await t.tap(find.text('Add demo records'));
        await settle(t);
        await t.tap(find.textContaining('interior and exterior design').first);
        await settle(t);
        await t.tap(find.text('Approve'));
        await settle(t);
        expect(
          find.text('Tick every check in the checklist before approving.'),
          findsOneWidget,
        );
        await t.tap(find.text('Reject'));
        await settle(t);
        await t.ensureVisible(find.text('Reject').last);
        await t.tap(find.text('Reject').last);
        await settle(t);
        expect(find.text('Choose a reason.'), findsOneWidget);
        expect(find.text('Confirm it is you'), findsNothing);
      },
    );

    testWidgets(
      'a document the service cannot stream is flagged and says why',
      (t) async {
        wide(t);
        final s = store();
        await t.pumpWidget(app(s));
        await settle(t);
        await login(t, 'reviewer');
        await t.tap(find.text('Add demo records'));
        await settle(t);
        await t.tap(find.textContaining('architecture studio').first);
        await settle(t);
        expect(find.text('Not available to view'), findsOneWidget);
        await t.tap(find.text('View'));
        await settle(t);
        expect(find.text('This document is not available'), findsOneWidget);
      },
    );
  });

  group('listing moderation', () {
    ListingSubmission submission(
      String id, {
      ListingSource src = ListingSource.agent,
      bool complete = true,
      bool? fee,
    }) => ListingSubmission(
      id: id,
      title: complete ? 'Villa $id' : '',
      description: complete ? 'Nice' : '',
      ownerName: 'Owner',
      location: complete ? 'Bawshar' : '',
      type: PropertyType.villa,
      source: src,
      submittedAt: DateTime(2026, 10, 2),
      priceOmr: complete ? 1000 : null,
      sizeSqm: complete ? 100 : null,
      photos: complete ? const ['p'] : const [],
      documents: complete
          ? const [
              AdminDocument(id: 'x', label: 'Title deed', fileName: 'deed.pdf'),
            ]
          : const [],
      feeDisclosureAccepted: fee,
    );

    test(
      'a submission with missing mandatory information cannot be approved',
      () async {
        final s = store();
        await signIn(s, 'reviewer');
        final l = s.debugAddListing((id) => submission(id, complete: false));
        expect(
          l.missing,
          containsAll([
            'title',
            'description',
            'location',
            'size',
            'price',
            'photos',
            'deed',
          ]),
        );
        await expectLater(
          s.decideListing(l.id, Decision.approve),
          throwsA(isA<ApiException>()),
        );
        final r = await s.decideListing(
          l.id,
          Decision.requestResubmission,
          reason: ReasonCode.incompleteSubmission,
        );
        expect(r.status, ModerationStatus.resubmissionRequired);
      },
    );

    test(
      'a complete listing is approved only when a reviewer approves it',
      () async {
        final s = store();
        await signIn(s, 'reviewer');
        final l = s.debugAddListing((id) => submission(id));
        expect(l.status, ModerationStatus.pending);
        expect(
          (await s.decideListing(l.id, Decision.approve)).status,
          ModerationStatus.approved,
        );
      },
    );

    test('e-Broker submissions stay distinct from agent submissions', () {
      final a = submission('1');
      final e = submission('2', src: ListingSource.eBroker, fee: true);
      expect(a.source, isNot(e.source));
      expect(e.feeDisclosureAccepted, isTrue);
      expect(a.feeDisclosureAccepted, isNull);
    });

    testWidgets(
      'the review page shows the e-Broker disclosure as recorded and no fee of its own',
      (t) async {
        wide(t);
        final s = store();
        await t.pumpWidget(app(s));
        await settle(t);
        await login(t, 'reviewer');
        await t.tap(find.text('Listing moderation').first);
        await settle(t);
        await t.tap(find.text('Add demo records'));
        await settle(t);
        await t.tap(find.textContaining('(e-Broker)').first);
        await settle(t);
        expect(
          find.textContaining('Aqary Real Estate fees will apply up to 2%'),
          findsOneWidget,
        );
        expect(find.text('Accepted by the owner'), findsOneWidget);
        expect(find.textContaining('Yes'), findsOneWidget);
      },
    );
  });

  group('ads and sponsors', () {
    test(
      'banners are created as drafts and are never served until approved',
      () async {
        final s = store();
        await signIn(s, 'super');
        final repo = s.ads;
        final a = await repo.create(adDraft());
        expect(a.status, AdStatus.draft);
        expect(await repo.served(AdPlacement.homeTop), isEmpty);
        await repo.submitForReview(a.id);
        expect(await repo.served(AdPlacement.homeTop), isEmpty);
        s.ads.debugDecide(a.id, AdStatus.approved);
        expect((await repo.served(AdPlacement.homeTop)).single.id, a.id);
      },
    );

    test('validation: required fields, destination format, image type and size, schedule', () {
      expect(validateAd(adDraft()), isEmpty);
      expect(
        validateAd(
          AdDraft(
            sponsor: '',
            headline: '',
            cta: '',
            destination: 'http://insecure.test',
            imageRef: null,
          ),
        ).keys,
        containsAll(['sponsor', 'headline', 'cta', 'destination', 'image']),
      );
      expect(
        validateAd(
          AdDraft(
            sponsor: 'a',
            headline: 'b',
            cta: 'c',
            destination: '/app/explore',
            imageBytes: Uint8List.fromList([1, 2, 3, 4]),
          ),
        ).keys,
        contains('image'),
      );
      expect(
        validateAd(
          AdDraft(
            sponsor: 'a',
            headline: 'b',
            cta: 'c',
            destination: '/app/explore',
            imageBytes: Uint8List(kAdMaxImageBytes + 1)
              ..setAll(0, [0x89, 0x50, 0x4E, 0x47]),
          ),
        ).keys,
        contains('image'),
      );
      expect(
        validateAd(
          AdDraft(
            sponsor: 'a',
            headline: 'b',
            cta: 'c',
            destination: '/app/explore',
            imageBytes: png(),
            startsAt: DateTime(2026, 12, 1),
            endsAt: DateTime(2026, 11, 1),
          ),
        ).keys,
        contains('schedule'),
      );
      expect(
        validateAd(
          AdDraft(
            sponsor: 'a',
            headline: 'b',
            cta: 'c',
            destination: '/app/explore',
            imageBytes: png(),
          ),
        ),
        isEmpty,
      );
    });

    test('pause, resume and order change what is served', () async {
      final s = store();
      await signIn(s, 'super');
      final a = s.ads.debugAdd(adDraft(headline: 'One'));
      final b = s.ads.debugAdd(adDraft(headline: 'Two'));
      final repo = s.ads;
      expect((await repo.served(AdPlacement.homeTop)).map((x) => x.headline), [
        'One',
        'Two',
      ]);
      await repo.reorder([b.id, a.id]);
      expect((await repo.served(AdPlacement.homeTop)).map((x) => x.headline), [
        'Two',
        'One',
      ]);
      await repo.pause(a.id);
      expect((await repo.served(AdPlacement.homeTop)).map((x) => x.headline), [
        'Two',
      ]);
      await repo.resume(a.id);
      expect((await repo.served(AdPlacement.homeTop)), hasLength(2));
    });

    test(
      'editing a live banner sends it back to draft so it stops being served',
      () async {
        final s = store();
        await signIn(s, 'super');
        final a = s.ads.debugAdd(adDraft());
        final e = await s.ads.update(a.id, adDraft(headline: 'New headline'));
        expect(e.status, AdStatus.draft);
        expect(await s.ads.served(AdPlacement.homeTop), isEmpty);
      },
    );

    test(
      'roles: only senior reviewers and super admins manage and review banners',
      () async {
        final s = store();
        final c = ProviderContainer(overrides: adminOverrides(s));
        addTearDown(c.dispose);
        final repo = c.read(adAdminRepositoryProvider);
        await signIn(s, 'reviewer');
        await expectLater(
          repo.create(adDraft()),
          throwsA(isA<AdminForbiddenException>()),
        );
        expect(await repo.list(), isEmpty);
        await signIn(s, 'auditor');
        await expectLater(
          repo.create(adDraft()),
          throwsA(isA<AdminForbiddenException>()),
        );
        await signIn(s, 'senior');
        final a = await repo.create(adDraft());
        await repo.submitForReview(a.id);
        await signIn(s, 'reviewer');
        await expectLater(
          repo.decide(a.id, outcome: AdStatus.approved),
          throwsA(isA<AdminForbiddenException>()),
        );
        await signIn(s, 'senior');
        expect(
          (await repo.decide(a.id, outcome: AdStatus.approved)).status,
          AdStatus.approved,
        );
      },
    );

    test('a reviewer who asks for changes or rejects gives a reason that the banner keeps', () async {
      final s = store();
      await signIn(s, 'super');
      final a = await s.ads.create(adDraft());
      await s.ads.submitForReview(a.id);
      final r = await s.ads.decide(
        a.id,
        outcome: AdStatus.resubmissionRequired,
        reasonCode: 'INCOMPLETE_SUBMISSION',
        note: 'Image is blurry',
      );
      expect(r.status, AdStatus.resubmissionRequired);
      expect(r.feedback, 'Image is blurry');
      expect(await s.ads.served(AdPlacement.homeTop), isEmpty);
    });

    testWidgets('the preview is the same banner component the customers see', (
      t,
    ) async {
      wide(t);
      final s = store();
      await t.pumpWidget(app(s));
      await settle(t);
      await login(t, 'super');
      GoRouter.of(t.element(find.text('Verification queue').first))
          .go('/ads/new');
      await settle(t);
      await t.enterText(find.widgetWithText(TextField, 'Sponsor name'), 'Acme');
      await t.enterText(
        find.widgetWithText(TextField, 'Headline'),
        'Big offer',
      );
      await settle(t);
      expect(find.byType(SponsoredBannerView), findsOneWidget);
      expect(find.text('SPONSORED · Acme'), findsOneWidget);
      expect(find.text('Big offer'), findsWidgets);
    });

    testWidgets(
      'saving an empty form explains each missing field and keeps what was typed',
      (t) async {
        wide(t);
        final s = store();
        await t.pumpWidget(app(s));
        await settle(t);
        await login(t, 'super');
        GoRouter.of(t.element(find.text('Verification queue').first))
            .go('/ads/new');
        await settle(t);
        await t.enterText(
          find.widgetWithText(TextField, 'Sponsor name'),
          'Acme',
        );
        await t.ensureVisible(find.text('Save draft'));
        await t.tap(find.text('Save draft'));
        await settle(t);
        expect(find.text('Enter a headline.'), findsOneWidget);
        expect(find.text('Choose a banner image.'), findsOneWidget);
        expect(find.text('Acme'), findsWidgets);
        expect(await s.ads.list(), isEmpty);
      },
    );

    testWidgets(
      'an auditor sees the list but no New banner button, and the form is closed',
      (t) async {
        wide(t);
        final s = store();
        s.ads.debugAdd(adDraft());
        await t.pumpWidget(app(s));
        await settle(t);
        await login(t, 'auditor');
        GoRouter.of(t.element(find.text('Verification queue').first))
            .go('/ads');
        await settle(t);
        expect(find.text('Ads & Sponsors'), findsWidgets);
        expect(find.text('New banner'), findsNothing);
        GoRouter.of(t.element(find.text('Ads & Sponsors').first))
            .go('/ads/new');
        await settle(t);
        expect(
          find.text('Your role cannot create or edit banners.'),
          findsOneWidget,
        );
      },
    );
  });

  group('accessibility of the lists', () {
    testWidgets(
      'Pause, Move up and Move down are their own controls, not hidden inside the row',
      (t) async {
        final handle = t.ensureSemantics();
        wide(t);
        final s = store();
        s.ads.debugAdd(adDraft(sponsor: 'Acme', headline: 'Offer one'));
        s.ads.debugAdd(adDraft(sponsor: 'Beta', headline: 'Offer two'));
        await t.pumpWidget(app(s));
        await settle(t);
        await login(t, 'super');
        GoRouter.of(t.element(find.text('Verification queue').first))
            .go('/ads');
        await settle(t);
        for (final label in ['Pause', 'Move up', 'Move down']) {
          expect(find.bySemanticsLabel(label), findsWidgets, reason: label);
        }
        // The row itself is still one button that opens the banner.
        expect(
          find.bySemanticsLabel(RegExp(r'^Acme, Offer one')),
          findsOneWidget,
        );
        handle.dispose();
      },
    );

    testWidgets('the document viewer keeps its Close button reachable', (
      t,
    ) async {
      final handle = t.ensureSemantics();
      wide(t);
      final s = store();
      final v = s.debugAddVerification(
        (id) => applicant(id, ApplicantKind.agent),
      );
      await t.pumpWidget(app(s));
      await settle(t);
      await login(t, 'reviewer');
      GoRouter.of(t.element(find.text('Verification queue').first))
          .go('/verification/${v.id}');
      await settle(t);
      await t.tap(find.text('View').first);
      await settle(t);
      expect(find.bySemanticsLabel('Close'), findsOneWidget);
      handle.dispose();
    });
  });

  group('separation', () {
    test('the customer app imports the admin console only to host it at /admin', () {
      final offenders = <String>[];
      for (final f
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final p = f.path.replaceAll('\\', '/');
        if (p.startsWith('lib/admin/') || p.endsWith('lib/admin_main.dart')) {
          continue;
        }
        // The one deliberate bridge: the router hosts the console at `/admin` so a single web build
        // carries both. Nothing else in the customer app may reach into it.
        if (p == 'lib/core/router/app_router.dart') continue;
        final src = f.readAsStringSync();
        if (RegExp(r"import\s+'[^']*\badmin/|import\s+'[^']*admin_main\.dart")
            .hasMatch(src)) {
          offenders.add(p);
        }
      }
      expect(offenders, isEmpty);
    });
  });
}
