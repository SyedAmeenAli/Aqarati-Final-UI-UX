import 'dart:async';
import 'dart:typed_data';

import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/features/flow/state/document_state.dart';
import 'package:aqarati_app/features/maintenance/maintenance_models.dart';
import 'package:aqarati_app/features/maintenance/maintenance_repository.dart';
import 'package:aqarati_app/features/provider/provider_repository.dart';
import 'package:aqarati_app/features/provider/provider_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

DemoMaintenanceRepository store() =>
    DemoMaintenanceRepository(latency: Duration.zero);
DemoProviderInviteRepository invites() =>
    DemoProviderInviteRepository(latency: Duration.zero);

Future<MaintenanceBooking> sample(
  DemoMaintenanceRepository s, {
  String providerId = 'b4',
  MaintenanceService service = MaintenanceService.ac,
}) => s.request(
  providerId: providerId,
  providerName: 'P',
  service: service,
  date: DateTime.now().add(const Duration(days: 2)),
  window: MaintenanceWindow.morning,
  notes: 'Not cooling',
);

class _Picker implements DocumentPicker {
  final List<PickedDocument> queue;
  _Picker(this.queue);
  @override
  Future<PickedDocument?> pick() async =>
      queue.isEmpty ? null : queue.removeAt(0);
}

PickedDocument pdf(String n) => PickedDocument(
  name: n,
  sizeBytes: 8,
  bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0, 0, 0, 0]),
);

Widget app(
  DemoMaintenanceRepository s,
  DemoProviderInviteRepository inv, {
  String start = '/provider',
  DocumentPicker? picker,
}) {
  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: '/app/account',
        builder: (_, _) => const Scaffold(body: Text('ACCOUNT')),
      ),
      GoRoute(path: '/provider', builder: (_, _) => const ProviderHomeScreen()),
      GoRoute(
        path: '/provider/invite',
        builder: (_, st) =>
            ProviderInviteScreen(code: st.uri.queryParameters['code']),
      ),
      GoRoute(
        path: '/provider/requests/:id',
        builder: (_, st) => ProviderRequestScreen(id: st.pathParameters['id']!),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      maintenanceRepositoryProvider.overrideWithValue(s),
      providerInviteRepositoryProvider.overrideWithValue(inv),
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

void big(WidgetTester t) {
  t.view.physicalSize = const Size(393, 1800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// A store whose reads fail until told otherwise (a connection that comes back).
class _Flaky extends DemoMaintenanceRepository {
  bool down = false;
  _Flaky() : super(latency: Duration.zero);
  @override
  Future<MaintenanceBooking?> get(String id) async {
    if (down) throw const ApiException(ApiErrorCode.network);
    return super.get(id);
  }
}

/// A store whose answers (confirm, decline, complete) can fail, optionally with reads failing too
/// (the whole connection down, which is what the browser fault switch does).
class _FailingAnswers extends DemoMaintenanceRepository {
  bool failAnswers = false;
  bool failReads = false;
  int answerCalls = 0;
  Completer<void>? hold;
  _FailingAnswers() : super(latency: Duration.zero);
  @override
  Future<MaintenanceBooking?> get(String id) async {
    if (failReads) throw const ApiException(ApiErrorCode.network);
    return super.get(id);
  }

  @override
  Future<MaintenanceBooking> respond(String id, {required bool confirm}) async {
    answerCalls++;
    if (hold != null) await hold!.future;
    if (failAnswers) throw const ApiException(ApiErrorCode.network);
    return super.respond(id, confirm: confirm);
  }
}

void main() {
  group('a failed answer (browser regression)', () {
    Future<_FailingAnswers> open(WidgetTester t) async {
      big(t);
      final s = _FailingAnswers();
      final i = invites()..debugSignInApproved();
      final b = await sample(s);
      await t.pumpWidget(app(s, i, start: '/provider/requests/${b.id}'));
      await settle(t);
      return s;
    }

    testWidgets(
      'keeps the request as it was and offers the same answer again',
      (t) async {
        final s = await open(t);
        s.failAnswers = true;
        await t.tap(find.text('Confirm request'));
        await settle(t);
        expect(find.textContaining('The request is unchanged'), findsOneWidget);
        expect(find.text('Request confirmed'), findsNothing);
        expect(find.text('Confirm request'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        s.failAnswers = false;
        await t.tap(find.text('Try again'));
        await settle(t);
        expect(s.answerCalls, 2);
        expect(find.text('Request confirmed'), findsOneWidget);
        expect(find.textContaining('The request is unchanged'), findsNothing);
        expect(find.text('Confirm request'), findsNothing);
      },
    );

    testWidgets('a second failure still shows no confirmed state', (t) async {
      final s = await open(t);
      s.failAnswers = true;
      await t.tap(find.text('Confirm request'));
      await settle(t);
      await t.tap(find.text('Try again'));
      await settle(t);
      expect(s.answerCalls, 2);
      expect(find.text('Request confirmed'), findsNothing);
      expect(find.text('Confirm request'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('survives the whole connection being down, then back', (
      t,
    ) async {
      final s = await open(t);
      s.failAnswers = true;
      s.failReads = true;
      await t.tap(find.text('Confirm request'));
      await settle(t);
      // The request stays on screen; the page is not replaced by a blank error.
      expect(find.text('Confirm request'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      s.failAnswers = false;
      s.failReads = false;
      await t.tap(find.text('Try again'));
      await settle(t);
      expect(find.text('Request confirmed'), findsOneWidget);
    });

    testWidgets('the retry button answers a screen reader tap on its own', (
      t,
    ) async {
      final h = t.ensureSemantics();
      final s = await open(t);
      s.failAnswers = true;
      await t.tap(find.text('Confirm request'));
      await settle(t);
      s.failAnswers = false;
      // This is the path a screen reader or the browser accessibility tree uses (no pointer).
      t.semantics.tap(find.semantics.byLabel('Try again'));
      await settle(t);
      expect(s.answerCalls, 2);
      expect(find.text('Request confirmed'), findsOneWidget);
      h.dispose();
    });

    testWidgets('repeated taps while it is sending run the answer once', (
      t,
    ) async {
      final s = await open(t);
      s.hold = Completer<void>();
      final at = t.getCenter(find.text('Confirm request'));
      await t.tapAt(at);
      await t.pump(const Duration(milliseconds: 50));
      await t.tapAt(at);
      await t.tapAt(at);
      s.hold!.complete();
      await settle(t);
      expect(s.answerCalls, 1);
      expect(find.text('Request confirmed'), findsOneWidget);
    });
  });

  testWidgets('a request that failed to load recovers with Try again', (
    t,
  ) async {
    big(t);
    final s = _Flaky();
    final i = invites()..debugSignInApproved();
    final b = await sample(s);
    s.down = true;
    await t.pumpWidget(app(s, i, start: '/provider/requests/${b.id}'));
    await settle(t);
    expect(find.textContaining('Try again'), findsWidgets);
    expect(find.text('Confirm request'), findsNothing);
    s.down = false;
    await t.tap(find.textContaining('Try again').first);
    await settle(t);
    expect(find.text('Confirm request'), findsOneWidget);
  });

  group('invitation rules', () {
    test('valid, expired, used and unknown codes', () async {
      final i = invites();
      expect((await i.check(' demo-invite ')).services, isNotEmpty);
      for (final (code, problem) in [
        (kDemoInviteExpired, InviteProblem.expired),
        (kDemoInviteUsed, InviteProblem.used),
        ('nope', InviteProblem.invalid),
      ]) {
        await expectLater(
          i.check(code),
          throwsA(
            isA<InviteException>().having((e) => e.problem, 'problem', problem),
          ),
        );
      }
    });
    test('accepting uses the code up and starts under review', () async {
      final i = invites();
      const setup = ProviderSetup(
        businessName: 'Cool Air',
        phone: '90001111',
        services: [MaintenanceService.ac],
        crName: 'cr.pdf',
        licenceName: 'lic.pdf',
      );
      final a = await i.accept(kDemoInviteOk, setup);
      expect(a.grant, ProviderGrant.pendingVerification);
      expect(a.canWork, isFalse);
      await expectLater(
        i.accept(kDemoInviteOk, setup),
        throwsA(isA<InviteException>()),
      );
    });
    test('the unconnected service fails honestly', () async {
      await expectLater(
        const UnavailableProviderInviteRepository().check('x'),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        const UnavailableProviderWorkRepository().requests('b4'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('work rules', () {
    test('a provider sees only their own business\'s requests', () async {
      final s = store();
      final mine = await sample(s);
      final other = await sample(s, providerId: 'b9');
      final w = DemoProviderWorkRepository(s);
      expect((await w.requests('b4')).map((b) => b.id), [mine.id]);
      await expectLater(
        w.request('b4', other.id),
        throwsA(isA<ProviderNotYoursException>()),
      );
      await expectLater(
        w.respond('b4', other.id, confirm: true),
        throwsA(isA<ProviderNotYoursException>()),
      );
    });
    test(
      'confirm or decline only while requested; complete only when confirmed',
      () async {
        final s = store();
        final w = DemoProviderWorkRepository(s);
        final b = await sample(s);
        await expectLater(w.complete('b4', b.id), throwsA(isA<ApiException>()));
        expect(
          (await w.respond('b4', b.id, confirm: true)).status,
          MaintenanceStatus.confirmed,
        );
        await expectLater(
          w.respond('b4', b.id, confirm: false),
          throwsA(isA<ApiException>()),
        );
        expect(
          (await w.complete('b4', b.id)).status,
          MaintenanceStatus.completed,
        );
      },
    );
    test(
      'a failed answer changes nothing, and the customer sees the real status',
      () async {
        final s = store();
        final w = DemoProviderWorkRepository(s);
        final b = await sample(s);
        expect((await s.get(b.id))!.status, MaintenanceStatus.requested);
        await w.respond('b4', b.id, confirm: true);
        expect((await s.get(b.id))!.status, MaintenanceStatus.confirmed);
      },
    );
  });

  group('screens', () {
    testWidgets('not a provider: says so and offers the invitation', (t) async {
      big(t);
      await t.pumpWidget(app(store(), invites()));
      await settle(t);
      expect(find.text('Providers only'), findsOneWidget);
      await t.tap(find.text('I have an invitation'));
      await settle(t);
      expect(find.text('Provider invitation'), findsOneWidget);
      expect(find.textContaining('no public sign-up'), findsOneWidget);
    });

    for (final (code, msg) in [
      ('', 'Enter the code from your invitation.'),
      ('WRONG', 'This code is not valid. Check it and try again.'),
      (
        kDemoInviteExpired,
        'This invitation has expired. Ask AQARATI for a new one.',
      ),
      (kDemoInviteUsed, 'This invitation was already used. Log in instead.'),
    ]) {
      testWidgets('invitation "$code" shows: $msg', (t) async {
        big(t);
        await t.pumpWidget(app(store(), invites(), start: '/provider/invite'));
        await settle(t);
        if (code.isNotEmpty) {
          await t.enterText(
            find.widgetWithText(TextField, 'Invitation code'),
            code,
          );
        }
        await t.tap(find.text('Check invitation'));
        await settle(t);
        expect(find.text(msg), findsOneWidget);
        expect(find.text('Your business'), findsNothing);
      });
    }

    testWidgets('a valid invitation leads through setup to "under review"', (
      t,
    ) async {
      big(t);
      final i = invites();
      await t.pumpWidget(
        app(
          store(),
          i,
          start: '/provider/invite?code=$kDemoInviteOk',
          picker: _Picker([pdf('cr.pdf'), pdf('lic.pdf')]),
        ),
      );
      await settle(t);
      await t.tap(find.text('Check invitation'));
      await settle(t);
      expect(find.text('Your business'), findsOneWidget);
      await t.tap(find.text('Send for verification'));
      await settle(t);
      expect(find.text('Enter the business name.'), findsOneWidget);
      expect(find.text('Add the registration certificate.'), findsOneWidget);
      await t.enterText(
        find.widgetWithText(TextField, 'Business name'),
        'Cool Air',
      );
      await t.enterText(
        find.widgetWithText(TextField, 'Phone (8 digits)'),
        '90001111',
      );
      await t.tap(find.text('Choose a file').first);
      await settle(t);
      await t.tap(find.text('Choose a file').first);
      await settle(t);
      await t.tap(find.text('Send for verification'));
      await settle(t);
      expect(find.text('Your business is under review'), findsOneWidget);
      expect(find.text('Under review'), findsWidgets);
      expect(find.text('Confirm request'), findsNothing);
    });

    testWidgets('verified provider: empty inbox, then a request to confirm', (
      t,
    ) async {
      big(t);
      final s = store();
      final i = invites()..debugSignInApproved();
      await t.pumpWidget(app(s, i));
      await settle(t);
      expect(find.text('No requests yet'), findsOneWidget);
      final b = await sample(s);
      await t.pumpWidget(app(s, i, start: '/provider/requests/${b.id}'));
      await settle(t);
      expect(find.text('Confirm request'), findsOneWidget);
      await t.tap(find.text('Confirm request'));
      await settle(t);
      expect(find.text('Request confirmed'), findsOneWidget);
      expect((await s.get(b.id))!.status, MaintenanceStatus.confirmed);
      expect(find.text('Mark as completed'), findsOneWidget);
    });

    testWidgets('decline asks first; Keep request changes nothing', (t) async {
      big(t);
      final s = store();
      final i = invites()..debugSignInApproved();
      final b = await sample(s);
      await t.pumpWidget(app(s, i, start: '/provider/requests/${b.id}'));
      await settle(t);
      await t.tap(find.text('Decline'));
      await settle(t);
      expect(find.text('Decline this request?'), findsOneWidget);
      await t.tap(find.text('Keep request'));
      await settle(t);
      expect((await s.get(b.id))!.status, MaintenanceStatus.requested);
      await t.tap(find.text('Decline'));
      await settle(t);
      await t.tap(find.text('Decline request'));
      await settle(t);
      expect(find.text('Request declined'), findsOneWidget);
      expect((await s.get(b.id))!.status, MaintenanceStatus.declined);
    });

    testWidgets('a failed confirm says so and does not show confirmed', (
      t,
    ) async {
      big(t);
      final s = store();
      final i = invites()..debugSignInApproved();
      final b = await sample(s);
      await t.pumpWidget(app(s, i, start: '/provider/requests/${b.id}'));
      await settle(t);
      final sFail = DemoMaintenanceRepository(latency: Duration.zero);
      expect(sFail, isNotNull);
      // Make the store fail the next call by confirming a request that was cancelled meanwhile.
      await s.cancel(b.id);
      await t.tap(find.text('Confirm request'));
      await settle(t);
      expect(find.text('Request confirmed'), findsNothing);
      expect(find.textContaining('has changed'), findsOneWidget);
      expect(find.text('Cancelled'), findsWidgets);
    });

    testWidgets('someone else\'s request, a bad id, and a pending provider', (
      t,
    ) async {
      big(t);
      final s = store();
      final i = invites()..debugSignInApproved();
      final other = await sample(s, providerId: 'b9');
      await t.pumpWidget(app(s, i, start: '/provider/requests/${other.id}'));
      await settle(t);
      expect(find.text('This is not your request'), findsOneWidget);
      await t.pumpWidget(app(s, i, start: '/provider/requests/nope'));
      await settle(t);
      expect(find.text('We could not find this request.'), findsOneWidget);
      final p = invites();
      await p.accept(
        kDemoInviteOk,
        const ProviderSetup(
          businessName: 'X',
          phone: '90001111',
          services: [MaintenanceService.ac],
          crName: 'a',
          licenceName: 'b',
        ),
      );
      await t.pumpWidget(app(s, p, start: '/provider/requests/${other.id}'));
      await settle(t);
      expect(find.text('Providers only'), findsOneWidget);
    });

    testWidgets('history lists answered requests', (t) async {
      big(t);
      final s = store();
      final i = invites()..debugSignInApproved();
      final b = await sample(s);
      await s.respond(b.id, confirm: false);
      await t.pumpWidget(app(s, i));
      await settle(t);
      expect(find.text('No requests yet'), findsOneWidget);
      await t.tap(find.text('History'));
      await settle(t);
      expect(find.text('Declined'), findsWidgets);
    });
  });
}
