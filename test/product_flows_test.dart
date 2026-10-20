import 'package:aqarati_app/core/auth/auth_repository.dart';
import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/data/demo/demo_backend.dart';
import 'package:aqarati_app/data/repositories/app_state_providers.dart';
import 'package:aqarati_app/features/account/delete_account_screen.dart';
import 'package:aqarati_app/features/activity/activity_screen.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/maintenance/maintenance_models.dart';
import 'package:aqarati_app/features/maintenance/maintenance_repository.dart';
import 'package:aqarati_app/features/maintenance/maintenance_screens.dart';
import 'package:aqarati_app/features/notifications/notifications.dart';
import 'package:aqarati_app/features/viewing/data/viewing_repository.dart';
import 'package:aqarati_app/features/viewing/domain/viewing_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Maintenance booking lifecycle, Activity, notifications and account removal.

DemoMaintenanceRepository repo({DateTime Function()? clock}) => DemoMaintenanceRepository(latency: Duration.zero, clock: clock);

Widget app(Widget child, {List<Override> overrides = const [], List<String>? visited}) {
  final router = GoRouter(
    initialLocation: '/start',
    routes: [GoRoute(path: '/start', builder: (c, s) => Scaffold(body: child))],
    errorBuilder: (c, s) {
      visited?.add(s.uri.toString());
      return Scaffold(body: Text('ROUTE ${s.uri}'));
    },
  );
  return ProviderScope(
    overrides: [meProvider.overrideWith((ref) async => throw const ApiException(ApiErrorCode.network)), ...overrides],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: const [Locale('en'), Locale('ar')],
    ),
  );
}

Future<void> settle(WidgetTester t, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 300));
  }
}

Future<void> pumpApp(WidgetTester t, Widget w, {double width = 393, double height = 1700}) async {
  await t.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => t.binding.setSurfaceSize(null));
  await t.pumpWidget(w);
  await settle(t);
}

Future<void> tapText(WidgetTester t, String text, {bool last = false}) async {
  final f = find.text(text);
  final target = last ? f.last : f.first;
  await t.ensureVisible(target);
  await t.pump();
  await t.tap(target, warnIfMissed: false);
  await settle(t, 4);
}

/// The label the day chips use: weekday, then "day month".
String dayLabel(DateTime d) {
  final weekday = DateFormat.E('en').format;
  final dayNum = DateFormat.d('en').format;
  final month = DateFormat.MMM('en').format;
  return '${weekday(d)}\n${dayNum(d)} ${month(d)}';
}

DateTime midnight(DateTime d) => DateTime(d.year, d.month, d.day);

void main() {
  group('maintenance repository', () {
    final today = DateTime(2026, 10, 16);
    DemoMaintenanceRepository r() => repo(clock: () => today);

    test('a request starts as requested, never confirmed', () async {
      final b = await r().request(providerId: 'b4', providerName: 'Rawaq', service: MaintenanceService.ac, date: today.add(const Duration(days: 2)), window: MaintenanceWindow.morning, notes: '  leaks  ');
      expect(b.status, MaintenanceStatus.requested);
      expect(b.notes, 'leaks');
      expect(b.canCancel, isTrue);
    });

    test('the same open request cannot be sent twice', () async {
      final x = r();
      final d = today.add(const Duration(days: 1));
      await x.request(providerId: 'b4', providerName: 'R', service: MaintenanceService.pool, date: d, window: MaintenanceWindow.evening);
      expect(() => x.request(providerId: 'b4', providerName: 'R', service: MaintenanceService.pool, date: d, window: MaintenanceWindow.evening), throwsA(isA<DuplicateBookingException>()));
      // A different window is a different request.
      await x.request(providerId: 'b4', providerName: 'R', service: MaintenanceService.pool, date: d, window: MaintenanceWindow.morning);
      expect((await x.list()).length, 2);
    });

    test('days in the past or beyond the horizon are rejected', () async {
      final x = r();
      expect(() => x.request(providerId: 'b4', providerName: 'R', service: MaintenanceService.ac, date: today.subtract(const Duration(days: 1)), window: MaintenanceWindow.morning), throwsA(isA<ApiException>()));
      expect(() => x.request(providerId: 'b4', providerName: 'R', service: MaintenanceService.ac, date: today.add(const Duration(days: kMaintenanceHorizonDays + 1)), window: MaintenanceWindow.morning), throwsA(isA<ApiException>()));
      final ok = await x.request(providerId: 'b4', providerName: 'R', service: MaintenanceService.ac, date: today.add(const Duration(days: kMaintenanceHorizonDays)), window: MaintenanceWindow.morning);
      expect(ok.status, MaintenanceStatus.requested);
    });

    test('only open requests can be cancelled, and a cancelled one frees the slot', () async {
      final x = r();
      final d = today.add(const Duration(days: 3));
      final b = await x.request(providerId: 'b4', providerName: 'R', service: MaintenanceService.kitchen, date: d, window: MaintenanceWindow.afternoon);
      final c = await x.cancel(b.id);
      expect(c.status, MaintenanceStatus.cancelled);
      expect(() => x.cancel(b.id), throwsA(isA<ApiException>()));
      await x.request(providerId: 'b4', providerName: 'R', service: MaintenanceService.kitchen, date: d, window: MaintenanceWindow.afternoon);
    });

    test('the unavailable repository fails like an offline request', () async {
      const u = UnavailableMaintenanceRepository();
      expect(u.list(), throwsA(isA<ApiException>()));
      expect(u.cancel('x'), throwsA(isA<ApiException>()));
    });
  });

  group('maintenance request screen', () {
    Widget host(DemoMaintenanceRepository r, {String provider = 'b4', List<String>? visited}) => app(
          MaintenanceBookScreen(providerId: provider),
          overrides: [maintenanceRepositoryProvider.overrideWithValue(r)],
          visited: visited,
        );

    testWidgets('validates, shows a review step, and sends exactly one request', (t) async {
      final r = repo();
      final visited = <String>[];
      await pumpApp(t, host(r, visited: visited));
      expect(find.text('Request a booking'), findsWidgets);

      // Nothing chosen: the form stays and explains what is missing.
      await tapText(t, 'Review request');
      expect(find.text('Choose a service.'), findsOneWidget);
      expect(find.text('Choose a day.'), findsOneWidget);
      expect(find.text('Choose a time of day.'), findsOneWidget);
      expect(await r.list(), isEmpty);

      final day = midnight(DateTime.now()).add(const Duration(days: 1));
      await tapText(t, 'AC');
      await tapText(t, dayLabel(day));
      await tapText(t, 'Evening');
      await tapText(t, 'Review request');
      expect(find.text('Check your request'), findsOneWidget);
      expect(find.text('Nothing is booked until the provider confirms.'), findsOneWidget);
      expect(await r.list(), isEmpty, reason: 'reviewing sends nothing');

      await tapText(t, 'Send request');
      final all = await r.list();
      expect(all.length, 1);
      expect(all.single.status, MaintenanceStatus.requested);
      expect(all.single.service, MaintenanceService.ac);
      expect(all.single.window, MaintenanceWindow.evening);
      expect(visited, contains('/bookings/${all.single.id}'));
    });

    testWidgets('Edit returns to the form with the choices kept', (t) async {
      await pumpApp(t, host(repo()));
      await tapText(t, 'Pool');
      await tapText(t, dayLabel(midnight(DateTime.now())));
      await tapText(t, 'Morning');
      await tapText(t, 'Review request');
      await tapText(t, 'Edit');
      expect(find.text('What do you need?'), findsOneWidget);
      await tapText(t, 'Review request');
      expect(find.text('Check your request'), findsOneWidget, reason: 'the choices were kept');
    });

    testWidgets('a duplicate open request is explained, not sent', (t) async {
      final r = repo();
      final d = midnight(DateTime.now()).add(const Duration(days: 2));
      await r.request(providerId: 'b4', providerName: 'Rawaq', service: MaintenanceService.plumber, date: d, window: MaintenanceWindow.morning);
      await pumpApp(t, host(r));
      await tapText(t, 'Plumber');
      await tapText(t, dayLabel(d));
      await tapText(t, 'Morning');
      await tapText(t, 'Review request');
      await tapText(t, 'Send request');
      expect(find.textContaining('already have an open request'), findsOneWidget);
      expect((await r.list()).length, 1);
    });

    testWidgets('a failing service says nothing was sent and keeps the form', (t) async {
      await pumpApp(t, app(const MaintenanceBookScreen(providerId: 'b4'), overrides: [maintenanceRepositoryProvider.overrideWithValue(const UnavailableMaintenanceRepository())]));
      await tapText(t, 'Pool');
      await tapText(t, dayLabel(midnight(DateTime.now())));
      await tapText(t, 'Evening');
      await tapText(t, 'Review request');
      await tapText(t, 'Send request');
      expect(find.textContaining('Nothing was sent'), findsOneWidget);
      expect(find.text('Send request'), findsOneWidget, reason: 'the person can retry');
    });

    testWidgets('a provider that is not maintenance cannot be booked', (t) async {
      await pumpApp(t, host(repo(), provider: 'b1'));
      expect(find.text('Booking is available for maintenance providers only.'), findsOneWidget);
      expect(find.text('Review request'), findsNothing);
    });
  });

  group('maintenance request detail', () {
    final day = midnight(DateTime.now()).add(const Duration(days: 1));

    Future<(DemoMaintenanceRepository, MaintenanceBooking)> seeded() async {
      final r = repo();
      final b = await r.request(providerId: 'b4', providerName: 'Rawaq Maintenance Services', service: MaintenanceService.ac, date: day, window: MaintenanceWindow.morning, notes: 'Unit is noisy');
      return (r, b);
    }

    testWidgets('requested: says it is not confirmed and cancelling asks first', (t) async {
      final (r, b) = await seeded();
      await pumpApp(t, app(MaintenanceDetailScreen(id: b.id), overrides: [maintenanceRepositoryProvider.overrideWithValue(r)]));
      expect(find.text('Your request is with the provider'), findsOneWidget);
      expect(find.textContaining('not confirmed yet'), findsOneWidget);
      expect(find.text('Unit is noisy'), findsOneWidget);
      await tapText(t, 'Cancel request');
      expect(find.text('Cancel this request?'), findsOneWidget);
      // Keeping the request changes nothing.
      await tapText(t, 'Keep request');
      expect((await r.get(b.id))!.status, MaintenanceStatus.requested);
      await tapText(t, 'Cancel request');
      await tapText(t, 'Cancel request', last: true);
      expect((await r.get(b.id))!.status, MaintenanceStatus.cancelled);
      expect(find.text('You cancelled this request'), findsOneWidget);
      expect(find.text('Request again'), findsOneWidget);
    });

    testWidgets('every status has its own honest copy', (t) async {
      final (r, b) = await seeded();
      final expected = <MaintenanceStatus, String>{
        MaintenanceStatus.confirmed: 'The provider confirmed',
        MaintenanceStatus.declined: 'The provider could not take this request',
        MaintenanceStatus.completed: 'This job is complete',
      };
      for (final e in expected.entries) {
        r.debugSet(b.id, e.key);
        await pumpApp(t, app(MaintenanceDetailScreen(id: b.id), overrides: [maintenanceRepositoryProvider.overrideWithValue(r)]));
        expect(find.text(e.value), findsOneWidget, reason: e.key.name);
        if (e.key == MaintenanceStatus.confirmed) expect(find.textContaining('Nothing is added to your calendar'), findsOneWidget);
        await t.pumpWidget(const SizedBox());
      }
    });

    testWidgets('an unknown booking is reported, not faked', (t) async {
      await pumpApp(t, app(const MaintenanceDetailScreen(id: 'nope'), overrides: [maintenanceRepositoryProvider.overrideWithValue(repo())]));
      expect(find.text('This booking request was not found.'), findsOneWidget);
    });
  });

  group('activity', () {
    testWidgets('one switch for viewings and maintenance; the maintenance list has an honest empty state', (t) async {
      await pumpApp(t, app(const ActivityScreen(), overrides: [maintenanceRepositoryProvider.overrideWithValue(repo())]));
      expect(find.text('Viewings'), findsOneWidget);
      expect(find.text('Maintenance'), findsOneWidget);
      await tapText(t, 'Maintenance');
      expect(find.text('No maintenance requests yet'), findsOneWidget);
      expect(find.text('Find a provider'), findsOneWidget);
    });

    testWidgets('requests appear in the maintenance list and open their detail', (t) async {
      final r = repo();
      await r.request(providerId: 'b4', providerName: 'Rawaq Maintenance Services', service: MaintenanceService.plumber, date: midnight(DateTime.now()).add(const Duration(days: 1)), window: MaintenanceWindow.afternoon);
      final visited = <String>[];
      await pumpApp(t, app(const ActivityScreen(), overrides: [maintenanceRepositoryProvider.overrideWithValue(r)], visited: visited));
      await tapText(t, 'Maintenance');
      expect(find.textContaining('Plumber'), findsWidgets);
      await t.tap(find.textContaining('Rawaq Maintenance Services').first, warnIfMissed: false);
      await settle(t, 3);
      expect(visited.any((v) => v.startsWith('/bookings/m')), isTrue);
    });
  });

  group('notifications', () {
    test('verification titles come from the real grant and stage', () {
      expect(verificationTitleKey(GrantState.pendingVerification, ReviewStage.underReview), 'ntf.ver.pending');
      expect(verificationTitleKey(GrantState.pendingVerification, ReviewStage.awaitingSecondApproval), 'ntf.ver.second');
      expect(verificationTitleKey(GrantState.approved, null), 'ntf.ver.approved');
      expect(verificationTitleKey(GrantState.resubmissionRequired, null), 'ntf.ver.resub');
      expect(verificationTitleKey(GrantState.rejected, null), 'ntf.ver.rejected');
      expect(verificationTitleKey(GrantState.suspended, null), 'ntf.ver.suspended');
      expect(verificationTitleKey(GrantState.draft, null), isEmpty, reason: 'a draft is not an event');
    });

    testWidgets('an empty inbox says so and does not invent updates', (t) async {
      await pumpApp(t, app(const NotificationsScreen(), overrides: [maintenanceRepositoryProvider.overrideWithValue(repo()), viewingRepositoryProvider.overrideWithValue(DemoViewingRepository(latency: Duration.zero))]));
      expect(find.text('Nothing new yet'), findsOneWidget);
      expect(find.textContaining('Push delivery is not connected'), findsOneWidget);
    });

    testWidgets('real maintenance changes appear, a tap marks read and opens the request', (t) async {
      final r = repo();
      final b = await r.request(providerId: 'b4', providerName: 'Rawaq Maintenance Services', service: MaintenanceService.ac, date: midnight(DateTime.now()).add(const Duration(days: 1)), window: MaintenanceWindow.morning);
      final visited = <String>[];
      final container = ProviderContainer(overrides: [
        meProvider.overrideWith((ref) async => throw const ApiException(ApiErrorCode.network)),
        maintenanceRepositoryProvider.overrideWithValue(r),
        viewingRepositoryProvider.overrideWithValue(DemoViewingRepository(latency: Duration.zero)),
      ]);
      addTearDown(container.dispose);
      await t.binding.setSurfaceSize(const Size(393, 1200));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final router = GoRouter(
        initialLocation: '/n',
        routes: [GoRoute(path: '/n', builder: (c, s) => const NotificationsScreen())],
        errorBuilder: (c, s) {
          visited.add(s.uri.toString());
          return const Scaffold(body: Text('DETAIL'));
        },
      );
      await t.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router, localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate]),
      ));
      await settle(t);
      expect(find.text('Maintenance request sent'), findsOneWidget);
      expect(container.read(unreadNotificationsProvider), 1);
      expect(find.text('1 unread'), findsOneWidget);

      await t.tap(find.text('Maintenance request sent'), warnIfMissed: false);
      await settle(t, 3);
      expect(visited, ['/bookings/${b.id}']);
      expect(container.read(readNotificationsProvider), contains('mnt-${b.id}-requested'));
      expect(container.read(unreadNotificationsProvider), 0);

      // A status change creates a new, unread update.
      r.debugSet(b.id, MaintenanceStatus.confirmed);
      container.invalidate(maintenanceBookingsProvider);
      container.invalidate(notificationsProvider);
      await container.read(notificationsProvider.future);
      expect(container.read(unreadNotificationsProvider), 1);
      final titles = container.read(notificationsProvider).value!.map((n) => n.titleKey).toList();
      expect(titles, contains('ntf.mnt.confirmed'));
    });

    testWidgets('Mark all as read clears the unread count', (t) async {
      final r = repo();
      final d = midnight(DateTime.now());
      await r.request(providerId: 'b4', providerName: 'R', service: MaintenanceService.ac, date: d.add(const Duration(days: 1)), window: MaintenanceWindow.morning);
      await r.request(providerId: 'b4', providerName: 'R', service: MaintenanceService.pool, date: d.add(const Duration(days: 2)), window: MaintenanceWindow.evening);
      await pumpApp(t, app(const NotificationsScreen(), overrides: [maintenanceRepositoryProvider.overrideWithValue(r), viewingRepositoryProvider.overrideWithValue(DemoViewingRepository(latency: Duration.zero))]));
      expect(find.text('2 unread'), findsOneWidget);
      await tapText(t, 'Mark all as read');
      expect(find.text('2 unread'), findsNothing);
    });

    testWidgets('when every source fails the inbox says so and offers a retry', (t) async {
      await pumpApp(t, app(const NotificationsScreen(), overrides: [maintenanceRepositoryProvider.overrideWithValue(const UnavailableMaintenanceRepository()), viewingRepositoryProvider.overrideWithValue(_FailingViewings())]));
      expect(find.text('We could not load your updates.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });

  group('account removal', () {
    DemoBackendState signedIn() => DemoBackendState()
      ..email = 'a@b.co'
      ..phone = '91234567'
      ..purpose = SignupPurpose.userToShop
      ..account = AccountState.active
      ..signedIn = true;
    final me = meProvider.overrideWith((ref) async => MeSession(account: AccountState.active, purpose: SignupPurpose.userToShop));

    testWidgets('a signed-out visitor is asked to sign in first', (t) async {
      await pumpApp(t, app(const DeleteAccountScreen()));
      expect(find.text('Sign in first'), findsOneWidget);
      expect(find.text('Delete my account'), findsNothing);
    });

    testWidgets('requires the confirmation word and an acknowledgement before anything is sent', (t) async {
      final s = signedIn();
      await pumpApp(t, app(const DeleteAccountScreen(), overrides: [accountApiProvider.overrideWithValue(DemoAccountApi(s)), me]));
      expect(find.textContaining('This cannot be undone'), findsOneWidget);
      await tapText(t, 'Continue');
      expect(find.text('Confirm deletion'), findsOneWidget);
      await tapText(t, 'Delete my account');
      expect(find.text('Type the confirmation word exactly.'), findsOneWidget);
      expect(find.text('Confirm that you understand.'), findsOneWidget);
      expect(s.email, 'a@b.co', reason: 'nothing was removed');
    });

    testWidgets('success signs out, clears local data and says what happened', (t) async {
      final s = signedIn();
      final container = ProviderContainer(overrides: [accountApiProvider.overrideWithValue(DemoAccountApi(s)), authRepositoryProvider.overrideWithValue(DemoAuthRepository(s)), me]);
      addTearDown(container.dispose);
      container.read(savedPropertyIdsProvider.notifier).state = {'p1'};
      container.read(recentSearchesProvider.notifier).state = ['villa'];
      await t.binding.setSurfaceSize(const Size(393, 1200));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(initialLocation: '/d', routes: [GoRoute(path: '/d', builder: (c, st) => const DeleteAccountScreen()), GoRoute(path: '/entry', builder: (c, st) => const Scaffold(body: Text('ENTRY')))]),
          localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        ),
      ));
      await settle(t);
      await tapText(t, 'Continue');
      await t.enterText(find.byType(TextField).first, 'DELETE');
      await t.pump();
      await tapText(t, 'I understand this cannot be undone.');
      await tapText(t, 'Delete my account');
      await settle(t, 8);
      expect(find.text('Your account was deleted'), findsOneWidget);
      expect(s.email, isNull, reason: 'the simulated account is gone');
      expect(s.signedIn, isFalse);
      expect(container.read(savedPropertyIdsProvider), isEmpty);
      expect(container.read(recentSearchesProvider), isEmpty);
      await tapText(t, 'Back to start');
      expect(find.text('ENTRY'), findsOneWidget);
    });

    testWidgets('failure removes nothing, keeps the person signed in, and allows a retry', (t) async {
      final s = signedIn();
      await pumpApp(t, app(const DeleteAccountScreen(), overrides: [accountApiProvider.overrideWithValue(const UnavailableAccountApi()), authRepositoryProvider.overrideWithValue(DemoAuthRepository(s)), me]));
      await tapText(t, 'Continue');
      await t.enterText(find.byType(TextField).first, 'DELETE');
      await t.pump();
      await tapText(t, 'I understand this cannot be undone.');
      await tapText(t, 'Delete my account');
      await settle(t, 6);
      expect(find.textContaining('Nothing was deleted'), findsOneWidget);
      expect(s.signedIn, isTrue, reason: 'still signed in');
      expect(find.text('Delete my account'), findsOneWidget, reason: 'the person can retry');
      expect(find.text('Your account was deleted'), findsNothing);
    });
  });
}

class _FailingViewings extends DemoViewingRepository {
  _FailingViewings() : super(latency: Duration.zero);
  @override
  Future<List<Viewing>> list() async => throw StateError('offline');
}
