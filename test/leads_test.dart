import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/data/models/enums.dart';
import 'package:aqarati_app/features/devbuild/db_models.dart'
    show PermissionDeniedException;
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/leads/lead_models.dart';
import 'package:aqarati_app/features/leads/lead_repository.dart';
import 'package:aqarati_app/features/leads/lead_screens.dart';
import 'package:aqarati_app/features/leads/phone_launcher.dart';
import 'package:aqarati_app/features/viewing/domain/viewing_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

const _agent = MeSession(
  account: AccountState.active,
  purpose: SignupPurpose.realEstateAgent,
  grant: GrantState.approved,
);
const _dev = MeSession(
  account: AccountState.active,
  purpose: SignupPurpose.propertyDevelopmentCompany,
  grant: GrantState.approved,
);
const _con = MeSession(
  account: AccountState.active,
  purpose: SignupPurpose.constructionCompany,
  grant: GrantState.approved,
);
const _buyer = MeSession(
  account: AccountState.active,
  purpose: SignupPurpose.userToShop,
);

class _Launcher implements PhoneLauncher {
  final bool ok;
  final List<String> dialled = [];
  _Launcher({this.ok = true});
  @override
  Future<bool> dial(String number) async {
    dialled.add(number);
    return ok;
  }
}

DemoLeadRepository repo() => DemoLeadRepository(latency: Duration.zero);
final _now = DateTime(2026, 10, 20, 10);

Lead contact(String id, {String? phone = '+968 9000 0001'}) => Lead(
  id: id,
  kind: LeadKind.contact,
  receivedAt: _now,
  customerName: 'Ali',
  phone: phone,
  message: 'Still available?',
  propertyId: 'p1',
  propertyTitle: 'Palm villa',
);
Lead viewing(String id) => Lead(
  id: id,
  kind: LeadKind.viewingRequest,
  receivedAt: _now,
  customerName: 'Sara',
  phone: '+968 9000 0002',
  propertyId: 'p1',
  propertyTitle: 'Palm villa',
  viewingId: 'v1',
  viewingStatus: ViewingStatus.requested,
  requestedSlot: ViewingSlot(DateTime(2026, 10, 24, 16)),
);

Widget app(
  DemoLeadRepository r, {
  MeSession? me = _agent,
  required String start,
  PhoneLauncher? launcher,
}) {
  final router = GoRouter(
    initialLocation: start,
    routes: [
      GoRoute(
        path: '/app/home',
        builder: (_, _) => const Scaffold(body: Text('HOME')),
      ),
      GoRoute(
        path: '/agent/leads',
        builder: (_, _) => const LeadInboxScreen(scope: LeadScope.agent),
      ),
      GoRoute(
        path: '/agent/leads/:id',
        builder: (_, s) => LeadDetailScreen(
          scope: LeadScope.agent,
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/workspace/enquiries',
        builder: (_, _) => const LeadInboxScreen(scope: LeadScope.developer),
      ),
      GoRoute(
        path: '/workspace/enquiries/:id',
        builder: (_, s) => LeadDetailScreen(
          scope: LeadScope.developer,
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/workspace/requests',
        builder: (_, _) => const LeadInboxScreen(scope: LeadScope.service),
      ),
      GoRoute(
        path: '/workspace/requests/:id',
        builder: (_, s) => LeadDetailScreen(
          scope: LeadScope.service,
          id: s.pathParameters['id']!,
        ),
      ),
    ],
  );
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      meProvider.overrideWith((ref) async {
        if (me == null) throw const ApiException(ApiErrorCode.network);
        return me;
      }),
      leadRepositoryProvider.overrideWithValue(r),
      if (launcher != null) phoneLauncherProvider.overrideWithValue(launcher),
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

void tall(WidgetTester t) {
  t.view.physicalSize = const Size(393, 2000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  group('repository', () {
    test('starts empty: no lead is ever invented', () async {
      final r = repo();
      for (final s in LeadScope.values) {
        expect(await r.list(s), isEmpty);
      }
    });

    test(
      'a viewing request is answered through the viewing lifecycle only',
      () async {
        final r = repo();
        final l = r.debugAdd(LeadScope.agent, (id) => viewing(id));
        expect(
          (await r.respondToViewing(
            l.id,
            ViewingResponse.confirm,
          )).viewingStatus,
          ViewingStatus.confirmed,
        );
        await expectLater(
          r.respondToViewing(l.id, ViewingResponse.decline),
          throwsA(isA<ApiException>()),
        );
        final c = r.debugAdd(LeadScope.agent, (id) => contact(id));
        await expectLater(
          r.respondToViewing(c.id, ViewingResponse.confirm),
          throwsA(isA<ApiException>()),
        );
      },
    );

    test('a lead that is not yours cannot be read', () async {
      final r = repo();
      await expectLater(
        r.get(r.debugForeignId()),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
  });

  group('inbox', () {
    testWidgets('empty states are written for each role and invent nothing', (
      t,
    ) async {
      tall(t);
      await t.pumpWidget(app(repo(), start: '/agent/leads'));
      await settle(t);
      expect(find.text('No leads yet'), findsOneWidget);
      expect(find.text('Open my listings'), findsOneWidget);
      await t.pumpWidget(app(repo(), me: _dev, start: '/workspace/enquiries'));
      await settle(t);
      expect(find.text('No enquiries yet'), findsOneWidget);
      await t.pumpWidget(app(repo(), me: _con, start: '/workspace/requests'));
      await settle(t);
      expect(find.text('No requests yet'), findsOneWidget);
    });

    testWidgets('each inbox is closed to the wrong role', (t) async {
      tall(t);
      await t.pumpWidget(app(repo(), me: _buyer, start: '/agent/leads'));
      await settle(t);
      expect(find.text('Agent workspace only'), findsOneWidget);
      await t.pumpWidget(
        app(repo(), me: _agent, start: '/workspace/enquiries'),
      );
      await settle(t);
      expect(find.text('Development company only'), findsOneWidget);
      await t.pumpWidget(app(repo(), me: _dev, start: '/workspace/requests'));
      await settle(t);
      expect(find.text('Service companies only'), findsOneWidget);
      await t.pumpWidget(app(repo(), me: null, start: '/agent/leads'));
      await settle(t);
      expect(find.text('Agent workspace only'), findsOneWidget);
    });

    testWidgets(
      'a failed request shows an error with a retry, not "no leads"',
      (t) async {
        tall(t);
        await t.pumpWidget(app(_FailingList(), start: '/agent/leads'));
        await settle(t);
        expect(find.text('No leads yet'), findsNothing);
        expect(find.text('Try again'), findsOneWidget);
      },
    );

    testWidgets(
      'agent leads show the kind and viewing status, and filter by kind',
      (t) async {
        final r = repo();
        r.debugAdd(LeadScope.agent, (id) => contact(id));
        r.debugAdd(LeadScope.agent, (id) => viewing(id));
        tall(t);
        await t.pumpWidget(app(r, start: '/agent/leads'));
        await settle(t);
        expect(find.text('Contact request'), findsOneWidget);
        expect(find.text('Viewing request'), findsOneWidget);
        expect(find.text('Requested'), findsOneWidget);
        await t.tap(find.text('Contact').first);
        await settle(t);
        expect(find.text('Viewing request'), findsNothing);
        expect(find.text('Contact request'), findsOneWidget);
      },
    );

    testWidgets(
      'developer enquiries keep their project and filter by project',
      (t) async {
        final r = repo();
        r.debugAdd(
          LeadScope.developer,
          (id) => Lead(
            id: id,
            kind: LeadKind.projectEnquiry,
            receivedAt: _now,
            customerName: 'Noor',
            projectId: 'a',
            projectName: 'Marina Heights',
          ),
        );
        r.debugAdd(
          LeadScope.developer,
          (id) => Lead(
            id: id,
            kind: LeadKind.projectEnquiry,
            receivedAt: _now,
            customerName: 'Omar',
            projectId: 'b',
            projectName: 'Garden Court',
          ),
        );
        tall(t);
        await t.pumpWidget(app(r, me: _dev, start: '/workspace/enquiries'));
        await settle(t);
        expect(find.text('Project enquiry'), findsNWidgets(2));
        await t.tap(find.text('Garden Court').first);
        await settle(t);
        expect(find.text('Project enquiry'), findsOneWidget);
        expect(find.textContaining('Omar'), findsOneWidget);
        expect(find.textContaining('Noor'), findsNothing);
      },
    );

    testWidgets('service requests show the real category, not a fixed one', (
      t,
    ) async {
      final r = repo();
      r.debugAdd(
        LeadScope.service,
        (id) => Lead(
          id: id,
          kind: LeadKind.serviceRequest,
          receivedAt: _now,
          customerName: 'Huda',
          serviceCategory: ServiceCategory.construction,
          serviceLocation: 'Sohar',
        ),
      );
      tall(t);
      await t.pumpWidget(app(r, me: _con, start: '/workspace/requests'));
      await settle(t);
      expect(find.textContaining('Construction'), findsWidgets);
      expect(find.textContaining('Electrical'), findsNothing);
    });
  });

  group('detail', () {
    testWidgets(
      'Call opens the dialler with the shared number and claims nothing more',
      (t) async {
        final r = repo();
        final l = r.debugAdd(LeadScope.agent, (id) => contact(id));
        final launcher = _Launcher();
        tall(t);
        await t.pumpWidget(
          app(r, start: '/agent/leads/${l.id}', launcher: launcher),
        );
        await settle(t);
        await t.tap(find.text('Call').first);
        await settle(t);
        expect(launcher.dialled, ['+968 9000 0001']);
        expect(find.textContaining('completed'), findsNothing);
      },
    );

    testWidgets('no phone number means no Call button and a clear reason', (
      t,
    ) async {
      final r = repo();
      final l = r.debugAdd(LeadScope.agent, (id) => contact(id, phone: null));
      tall(t);
      await t.pumpWidget(app(r, start: '/agent/leads/${l.id}'));
      await settle(t);
      expect(find.text('Call'), findsNothing);
      expect(find.text('Name not shared'), findsNothing);
    });

    testWidgets(
      'a dialler that cannot open shows a message and keeps the number visible',
      (t) async {
        final r = repo();
        final l = r.debugAdd(LeadScope.agent, (id) => contact(id));
        tall(t);
        await t.pumpWidget(
          app(r, start: '/agent/leads/${l.id}', launcher: _Launcher(ok: false)),
        );
        await settle(t);
        await t.tap(find.text('Call').first);
        await settle(t);
        expect(
          find.text(
            'We could not open the phone app. The number is shown above.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('9000 0001'), findsWidgets);
      },
    );

    testWidgets('confirming a viewing request follows the real response', (
      t,
    ) async {
      final r = repo();
      final l = r.debugAdd(LeadScope.agent, (id) => viewing(id));
      tall(t);
      await t.pumpWidget(app(r, start: '/agent/leads/${l.id}'));
      await settle(t);
      expect(
        find.text('The customer asked for this time. Confirm or decline it.'),
        findsOneWidget,
      );
      await t.tap(find.text('Confirm viewing'));
      await settle(t);
      expect(find.text('Viewing confirmed'), findsOneWidget);
      expect((await r.get(l.id))!.viewingStatus, ViewingStatus.confirmed);
      expect(find.text('Confirm viewing'), findsNothing);
    });

    testWidgets('a failed confirmation leaves the request requested', (
      t,
    ) async {
      final r = repo();
      final l = r.debugAdd(LeadScope.agent, (id) => viewing(id));
      tall(t);
      await t.pumpWidget(app(r, start: '/agent/leads/${l.id}'));
      await settle(t);
      r.debugNextError = const ApiException(ApiErrorCode.network);
      await t.tap(find.text('Confirm viewing'));
      await settle(t);
      expect(
        find.text(
          'We could not update this viewing. Its status did not change.',
        ),
        findsOneWidget,
      );
      expect((await r.get(l.id))!.viewingStatus, ViewingStatus.requested);
    });

    testWidgets('declining asks first', (t) async {
      final r = repo();
      final l = r.debugAdd(LeadScope.agent, (id) => viewing(id));
      tall(t);
      await t.pumpWidget(app(r, start: '/agent/leads/${l.id}'));
      await settle(t);
      await t.tap(find.text('Decline').first);
      await settle(t);
      expect(find.text('Decline this request?'), findsOneWidget);
      await t.tap(find.text('Decline request'));
      await settle(t);
      expect((await r.get(l.id))!.viewingStatus, ViewingStatus.declined);
    });

    testWidgets(
      'a lead that is not in your inbox cannot be opened by its address',
      (t) async {
        final r = repo();
        tall(t);
        await t.pumpWidget(app(r, start: '/agent/leads/${r.debugForeignId()}'));
        await settle(t);
        expect(find.text('This is not in your inbox'), findsOneWidget);
      },
    );

    testWidgets('a service request keeps its category and location', (t) async {
      final r = repo();
      final l = r.debugAdd(
        LeadScope.service,
        (id) => Lead(
          id: id,
          kind: LeadKind.serviceRequest,
          receivedAt: _now,
          customerName: 'Huda',
          phone: '+968 9111 1111',
          serviceCategory: ServiceCategory.interiorDesign,
          serviceLocation: 'Sohar',
          requestedTiming: 'Next month',
        ),
      );
      tall(t);
      await t.pumpWidget(
        app(r, me: _con, start: '/workspace/requests/${l.id}'),
      );
      await settle(t);
      expect(find.textContaining('Interior Design'), findsWidgets);
      expect(find.textContaining('Sohar'), findsOneWidget);
      expect(find.textContaining('Next month'), findsOneWidget);
    });
  });
}

class _FailingList extends DemoLeadRepository {
  _FailingList() : super(latency: Duration.zero);
  @override
  Future<List<Lead>> list(LeadScope scope) async =>
      throw const ApiException(ApiErrorCode.network);
}
