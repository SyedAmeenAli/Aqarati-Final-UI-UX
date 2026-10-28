import 'dart:typed_data';

import 'package:aqarati_app/core/aq/aq_forms.dart' show AQCheckRow;
import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/data/models/enums.dart';
import 'package:aqarati_app/features/devbuild/db_models.dart'
    show PermissionDeniedException;
import 'package:aqarati_app/features/ebroker/ebroker_models.dart';
import 'package:aqarati_app/features/ebroker/ebroker_repository.dart';
import 'package:aqarati_app/features/ebroker/ebroker_screens.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/flow/state/document_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _buyer = MeSession(
  account: AccountState.active,
  purpose: SignupPurpose.userToShop,
);

EBrokerInput input({
  String deed = 'DEED123456',
  String title = 'Plot in Seeb',
}) => EBrokerInput(
  title: title,
  description: 'Corner plot',
  type: PropertyType.residentialLand,
  governorate: 'Muscat',
  wilayat: 'Bawshar',
  sizeSqm: 600,
  priceOmr: 90000,
  titleDeed: deed,
  ownerIdName: 'id.jpg',
  deedDocName: 'deed.pdf',
  photoNames: const ['a.jpg'],
  feeAccepted: true,
);

DemoEBrokerRepository repo() => DemoEBrokerRepository(latency: Duration.zero);

class _Picker implements DocumentPicker {
  final List<PickedDocument> queue;
  _Picker(this.queue);
  @override
  Future<PickedDocument?> pick() async =>
      queue.isEmpty ? null : queue.removeAt(0);
}

PickedDocument jpg(String n) => PickedDocument(
  name: n,
  sizeBytes: 8,
  bytes: Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0]),
);

Widget app(
  DemoEBrokerRepository r, {
  MeSession? me = _buyer,
  String start = '/sell',
  DocumentPicker? picker,
}) {
  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: '/properties',
        builder: (_, _) => const Scaffold(body: Text('PROPS')),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const Scaffold(body: Text('LOGIN')),
      ),
      GoRoute(path: '/sell', builder: (_, _) => const EBrokerIntroScreen()),
      GoRoute(path: '/sell/new', builder: (_, _) => const EBrokerFormScreen()),
      GoRoute(
        path: '/sell/:id',
        builder: (_, s) => EBrokerDetailScreen(
          id: s.pathParameters['id']!,
          flash: s.uri.queryParameters['flash'],
        ),
      ),
      GoRoute(
        path: '/sell/:id/edit',
        builder: (_, s) => EBrokerFormScreen(editId: s.pathParameters['id']),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      meProvider.overrideWith((ref) async {
        if (me == null) throw const ApiException(ApiErrorCode.network);
        return me;
      }),
      eBrokerRepositoryProvider.overrideWithValue(r),
      if (picker != null) documentPickerProvider.overrideWithValue(picker),
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

Future<void> big(WidgetTester t) async {
  t.view.physicalSize = const Size(393, 1800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  test('the fee wording is exactly the approved sentence', () {
    expect(kEBrokerFeeDisclosure, 'Aqary Real Estate fees will apply up to 2%');
  });

  group('rules', () {
    test(
      'a new submission starts in review and records the acceptance',
      () async {
        final r = repo();
        final s = await r.submit(input());
        expect(s.status, EBrokerStatus.pendingVerification);
        expect(s.feeAcceptedAt, isNotNull);
      },
    );
    test('a submission without the fee acceptance is refused', () async {
      final r = repo();
      final bad = EBrokerInput(
        title: 'x',
        description: '',
        type: PropertyType.villa,
        governorate: 'Muscat',
        wilayat: 'Bawshar',
        sizeSqm: 1,
        priceOmr: 1,
        titleDeed: 'ABCDEF',
        ownerIdName: 'a',
        deedDocName: 'b',
        photoNames: const ['c'],
        feeAccepted: false,
      );
      await expectLater(r.submit(bad), throwsA(isA<ApiException>()));
      expect(await r.mine(), isEmpty);
    });
    test('the same title deed is refused', () async {
      final r = repo();
      await r.submit(input());
      await expectLater(
        r.submit(input(deed: 'deed-12 3456', title: 'Other')),
        throwsA(isA<EBrokerDuplicateException>()),
      );
    });
    test('resubmission only when changes were requested', () async {
      final r = repo();
      final s = await r.submit(input());
      await expectLater(
        r.resubmit(s.id, input()),
        throwsA(isA<ApiException>()),
      );
      r.debugSet(s.id, EBrokerStatus.resubmissionRequired, feedback: 'blurry');
      final n = await r.resubmit(s.id, input(title: 'Plot in Seeb, updated'));
      expect(n.status, EBrokerStatus.pendingVerification);
      expect(n.input.title, 'Plot in Seeb, updated');
    });
    test(
      'someone else\'s submission is denied; failures change nothing',
      () async {
        final r = repo();
        await expectLater(
          r.get(r.debugForeignId()),
          throwsA(isA<PermissionDeniedException>()),
        );
        r.debugNextError = const ApiException(ApiErrorCode.network);
        await expectLater(r.submit(input()), throwsA(isA<ApiException>()));
        expect(await r.mine(), isEmpty);
      },
    );
    test('the unconnected service fails honestly', () async {
      await expectLater(
        const UnavailableEBrokerRepository().submit(input()),
        throwsA(isA<ApiException>()),
      );
    });
    test('deed and file signature helpers', () {
      expect(eBrokerDeedValid('ab-12 34 56'), isTrue);
      expect(eBrokerDeedValid('12'), isFalse);
      expect(isJpgOrPng([0x89, 0x50, 0x4E, 0x47, 0]), isTrue);
      expect(isJpgOrPng([1, 2, 3, 4]), isFalse);
    });
  });

  group('screens', () {
    testWidgets(
      'intro shows the fee sentence, no payment, and a start button',
      (t) async {
        await big(t);
        await t.pumpWidget(app(repo()));
        await settle(t);
        expect(
          find.text('Aqary Real Estate fees will apply up to 2%'),
          findsOneWidget,
        );
        expect(
          find.text('Nothing is charged or paid in the app.'),
          findsOneWidget,
        );
        expect(find.text('Start a submission'), findsOneWidget);
        expect(find.text('No submissions yet'), findsNothing);
        expect(find.textContaining('commission'), findsNothing);
      },
    );

    testWidgets('signed out: asks to log in, no start button', (t) async {
      await big(t);
      await t.pumpWidget(app(repo(), me: null));
      await settle(t);
      expect(find.text('Sign in to sell'), findsOneWidget);
      expect(find.text('Start a submission'), findsNothing);
    });

    Future<void> next(WidgetTester t) async {
      await t.tap(find.text('Continue'));
      await settle(t);
    }

    Future<void> pick(WidgetTester t, String field, String option) async {
      await t.tap(find.text(field).first);
      await settle(t);
      await t.tap(find.text(option).last);
      await settle(t);
    }

    /// Walks the wizard to the review step. The picker serves a photo, then the ID, then the deed.
    Future<void> fillToReview(WidgetTester t) async {
      await pick(t, 'Market', 'Residential');
      await pick(t, 'Property type', 'Villa');
      await next(t);
      await t.enterText(find.widgetWithText(TextField, 'Title'), 'Sea villa');
      await t.enterText(find.widgetWithText(TextField, 'Size (m²)'), '420');
      await next(t);
      await pick(t, 'Governorate', 'Muscat');
      await pick(t, 'Wilayat', 'Bawshar');
      await next(t);
      await t.enterText(find.widgetWithText(TextField, 'Asking price (OMR)'), '250000');
      await t.tap(find.text('Add photo'));
      await settle(t);
      await next(t);
      await t.tap(find.text('Choose a file').first);
      await settle(t);
      await t.tap(find.text('Choose a file').first);
      await settle(t);
      await t.enterText(find.widgetWithText(TextField, 'Title deed number'), 'DEED778899');
      await t.ensureVisible(find.byType(AQCheckRow));
      await t.tap(find.byType(AQCheckRow));
      await settle(t);
      await next(t);
    }

    testWidgets('it is a six step wizard that starts with the property type', (t) async {
      await big(t);
      await t.pumpWidget(app(repo(), start: '/sell/new'));
      await settle(t);
      expect(find.text('What are you selling?'), findsOneWidget);
      expect(find.text('Step 1 of 6'), findsOneWidget);
      expect(find.text('Send for review'), findsNothing);
      expect(find.text('Title deed number'), findsNothing, reason: 'later steps are not shown yet');
    });

    testWidgets('each step blocks Continue until it is complete and says why', (t) async {
      await big(t);
      final r = repo();
      await t.pumpWidget(app(r, start: '/sell/new'));
      await settle(t);
      await next(t);
      expect(find.text('Choose a market.'), findsOneWidget);
      expect(find.text('What are you selling?'), findsOneWidget, reason: 'still on step 1');
      await pick(t, 'Market', 'Residential');
      await pick(t, 'Property type', 'Villa');
      await next(t);
      expect(find.text('About the property'), findsOneWidget);
      await next(t);
      expect(find.text('Enter a title.'), findsOneWidget);
      expect(find.text('Enter the size as a number above zero.'), findsOneWidget);
      expect(await r.mine(), isEmpty);
    });

    testWidgets('Back keeps what was entered', (t) async {
      await big(t);
      await t.pumpWidget(app(repo(), start: '/sell/new'));
      await settle(t);
      await pick(t, 'Market', 'Residential');
      await pick(t, 'Property type', 'Villa');
      await next(t);
      await t.enterText(find.widgetWithText(TextField, 'Title'), 'Sea villa');
      await t.tap(find.text('Back').last);
      await settle(t);
      expect(find.text('What are you selling?'), findsOneWidget);
      expect(find.text('Villa'), findsWidgets, reason: 'the type is still chosen');
      await next(t);
      expect(find.text('Sea villa'), findsOneWidget, reason: 'the title is still typed');
    });

    testWidgets('a full submission lands in review and says nothing was sent to a real service', (t) async {
      await big(t);
      final r = repo();
      await t.pumpWidget(app(r, start: '/sell/new', picker: _Picker([jpg('p1.jpg'), jpg('id.jpg'), jpg('deed.jpg')])));
      await settle(t);
      await fillToReview(t);
      expect(find.text('Review and send'), findsOneWidget);
      expect(find.text('Step 6 of 6'), findsOneWidget);
      expect(find.textContaining('Sea villa'), findsOneWidget);
      expect(find.textContaining('DEED778899'), findsOneWidget);
      expect(find.textContaining('Aqary Real Estate fees will apply up to 2%'), findsOneWidget);
      await t.tap(find.text('Send for review'));
      await settle(t);
      final list = await r.mine();
      expect(list, hasLength(1));
      expect(list.single.status, EBrokerStatus.pendingVerification);
      expect(find.text('In review'), findsWidgets);
      expect(find.textContaining('Prototype submission saved'), findsOneWidget);
      expect(find.textContaining('No listing has been sent to a real service'), findsOneWidget);
      expect(find.text('Approved'), findsNothing);
    });

    testWidgets('review can jump back to a section to edit it', (t) async {
      await big(t);
      await t.pumpWidget(app(repo(), start: '/sell/new', picker: _Picker([jpg('p1.jpg'), jpg('id.jpg'), jpg('deed.jpg')])));
      await settle(t);
      await fillToReview(t);
      await t.tap(find.text('Edit').at(1));
      await settle(t);
      expect(find.text('About the property'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Sea villa'), findsOneWidget);
    });

    testWidgets('a failed send keeps every answer and offers the same send again', (t) async {
      await big(t);
      final r = repo();
      await t.pumpWidget(app(r, start: '/sell/new', picker: _Picker([jpg('p1.jpg'), jpg('id.jpg'), jpg('deed.jpg')])));
      await settle(t);
      await fillToReview(t);
      r.debugNextError = const ApiException(ApiErrorCode.network);
      await t.tap(find.text('Send for review'));
      await settle(t);
      expect(find.textContaining('Nothing was submitted'), findsOneWidget);
      expect(find.text('Review and send'), findsOneWidget);
      expect(find.textContaining('Sea villa'), findsOneWidget);
      expect(await r.mine(), isEmpty);
      await t.tap(find.text('Send for review'));
      await settle(t);
      expect((await r.mine()).single.input.title, 'Sea villa');
    });

    testWidgets('a failed load says so and Try again recovers', (t) async {
      await big(t);
      final r = repo();
      await r.submit(input());
      r.debugNextError = const ApiException(ApiErrorCode.network);
      await t.pumpWidget(app(r, start: '/sell'));
      await settle(t);
      expect(find.textContaining('Plot in Seeb'), findsNothing);
      await t.tap(find.text('Try again'));
      await settle(t);
      expect(find.textContaining('Plot in Seeb'), findsOneWidget);
    });

    testWidgets(
      'changes requested: feedback shown and an update button leads to the form',
      (t) async {
        await big(t);
        final r = repo();
        final s = await r.submit(input());
        r.debugSet(
          s.id,
          EBrokerStatus.resubmissionRequired,
          feedback: 'Deed is blurry',
        );
        await t.pumpWidget(app(r, start: '/sell/${s.id}'));
        await settle(t);
        expect(find.text('Deed is blurry'), findsOneWidget);
        await t.tap(find.text('Update and resubmit'));
        await settle(t);
        expect(find.text('What are you selling?'), findsOneWidget);
        await t.tap(find.text('Continue'));
        await settle(t);
        expect(find.widgetWithText(TextField, 'Title'), findsOneWidget);
        expect(find.text('Plot in Seeb'), findsWidgets);
      },
    );

    testWidgets('someone else\'s submission shows not yours', (t) async {
      await big(t);
      final r = repo();
      await t.pumpWidget(app(r, start: '/sell/${r.debugForeignId()}'));
      await settle(t);
      expect(find.text('This is not your submission'), findsOneWidget);
    });
  });
}
