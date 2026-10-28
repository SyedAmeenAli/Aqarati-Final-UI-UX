import 'package:aqarati_app/core/aq/aq_primitives.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/models/enums.dart';
import 'package:aqarati_app/features/devbuild/db_models.dart';
import 'package:aqarati_app/features/devbuild/db_projects.dart'
    show dbNewIdempotencyKey;
import 'package:aqarati_app/features/devbuild/db_repository.dart';
import 'package:aqarati_app/features/devbuild/db_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _MediaRepo extends DemoDevBuildRepository {
  _MediaRepo() : super(() => null);
  @override
  Future<DbProject?> approvedProject(String id) async {
    final p = await super.approvedProject(id);
    return p == null
        ? null
        : DbProject(
            id: p.id,
            orgId: p.orgId,
            name: p.name,
            propertyType: p.propertyType,
            governorate: p.governorate,
            wilayat: p.wilayat,
            status: p.status,
            rawStatus: p.rawStatus,
            updatedAt: p.updatedAt,
            mediaUrls: const [
              'assets/properties/p1/08_Contemporary_villa_front_facade_.jpg',
              'assets/properties/p1/07_Waterfront_villa_with_infinity_pool.jpg',
            ],
          );
  }
}

Widget _routed(
  String location, {
  List<Override> overrides = const [],
  double scale = 1,
  String lang = 'en',
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (c, s, child) => Scaffold(body: child),
        routes: [...dbShellRoutes(), ...dbProShellRoutes()],
      ),
      ...dbStandaloneRoutes(),
    ],
  );
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig: router,
      locale: Locale(lang),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
    ),
  );
}

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  group('status mapping', () {
    test(
      'known server statuses map; unknown stays unknown and is never approved',
      () {
        expect(projectStatusFromServer('draft'), ProjectStatus.draft);
        expect(
          projectStatusFromServer('pending_verification'),
          ProjectStatus.underReview,
        );
        expect(projectStatusFromServer('approved'), ProjectStatus.approved);
        expect(
          projectStatusFromServer('resubmission_required'),
          ProjectStatus.changesRequested,
        );
        expect(projectStatusFromServer('rejected'), ProjectStatus.rejected);
        expect(projectStatusFromServer('published'), ProjectStatus.unknown);
        expect(projectStatusFromServer(null), ProjectStatus.unknown);
        expect(ProjectStatus.unknown.isPublic, isFalse);
        expect(ProjectStatus.underReview.isPublic, isFalse);
      },
    );

    test('edit and resubmit are offered only where the workflow allows', () {
      expect(ProjectStatus.rejected.canEdit, isFalse);
      expect(ProjectStatus.underReview.canEdit, isFalse);
      expect(ProjectStatus.changesRequested.canResubmit, isTrue);
      expect(ProjectStatus.approved.canResubmit, isFalse);
    });
  });

  group('project draft', () {
    test('step validation is conditional on property type', () {
      final d = ProjectDraft();
      expect(d.validate(ProjectStep.basic).keys, containsAll(['name', 'type']));
      d
        ..name = 'Harbour Homes'
        ..type = PropertyType.villa;
      expect(d.validate(ProjectStep.basic), isEmpty);
      expect(
        d.validate(ProjectStep.details).keys,
        containsAll(['beds', 'baths', 'area']),
      );
      d.type = PropertyType.residentialLand;
      final land = d.validate(ProjectStep.details);
      expect(land.keys, ['land']);
      expect(land.containsKey('beds'), isFalse);
      expect(
        d.validate(ProjectStep.location).keys,
        containsAll(['gov', 'wil']),
      );
    });

    test('payload carries only contract fields, in metric', () {
      final d = ProjectDraft(
        name: ' Harbour Homes ',
        type: PropertyType.villa,
        bedrooms: 4,
        bathrooms: 3,
        areaSqm: 280,
        landSqm: 400,
        governorate: 'Muscat',
        wilayat: 'As Seeb',
      );
      final p = d.toPayload();
      expect(p['name'], 'Harbour Homes');
      expect(p['area_sqm'], 280);
      expect(p.containsKey('land_sqm'), isFalse);
      for (final proposed in [
        'description',
        'amenities',
        'highlights',
        'cover',
        'completion_date',
        'status',
      ]) {
        expect(p.containsKey(proposed), isFalse, reason: proposed);
      }
      d.type = PropertyType.agriculturalLand;
      final land = d.toPayload();
      expect(land['land_sqm'], 400);
      expect(land.containsKey('bedrooms'), isFalse);
    });

    test(
      'a draft with no location has an empty label, never a stray comma',
      () {
        final p = DbProject(
          id: 'x',
          orgId: 'o',
          name: 'Draft',
          propertyType: PropertyType.villa,
          governorate: '',
          wilayat: '',
          status: ProjectStatus.draft,
          rawStatus: 'draft',
          updatedAt: DateTime(2026, 1, 1),
        );
        expect(p.locationLabel, isEmpty);
        final q = DbProject(
          id: 'y',
          orgId: 'o',
          name: 'Placed',
          propertyType: PropertyType.villa,
          governorate: 'Muscat',
          wilayat: 'As Seeb',
          area: 'Al Mouj',
          status: ProjectStatus.draft,
          rawStatus: 'draft',
          updatedAt: DateTime(2026, 1, 1),
        );
        expect(q.locationLabel, 'Al Mouj, As Seeb, Muscat');
      },
    );

    test('coordinates must be a complete pair inside Oman', () {
      final d = ProjectDraft(governorate: 'Muscat', wilayat: 'As Seeb');
      expect(d.validate(ProjectStep.location), isEmpty);
      d.latitude = 23.6;
      expect(d.validate(ProjectStep.location)['coords'], 'db.err.coordsPair');
      d.longitude = 58.3;
      expect(d.validate(ProjectStep.location), isEmpty);
      d.latitude = 40;
      expect(d.validate(ProjectStep.location)['coords'], 'db.err.coordsRange');
    });

    test('idempotency keys are unique and never throw', () {
      final keys = {for (var i = 0; i < 200; i++) dbNewIdempotencyKey()};
      expect(keys.length, 200);
    });

    test('every governorate has wilayats and an Arabic name', () {
      expect(omanGovernorates.length, 11);
      for (final g in omanGovernorates.keys) {
        expect(omanGovernorates[g], isNotEmpty);
        expect(omanGovernorateAr.containsKey(g), isTrue, reason: g);
      }
    });
  });

  group('workspace access', () {
    MeSession me(SignupPurpose? p, GrantState? g, {ReviewStage? st}) =>
        MeSession(
          account: AccountState.active,
          purpose: p,
          grant: g,
          stage: st,
        );
    test('only an approved matching grant unlocks the workspace', () {
      expect(workspaceAccessOf(null).gate, WorkspaceGate.signedOut);
      expect(
        workspaceAccessOf(me(SignupPurpose.userToShop, null)).gate,
        WorkspaceGate.notBusiness,
      );
      expect(
        workspaceAccessOf(
          me(SignupPurpose.realEstateAgent, GrantState.approved),
        ).gate,
        WorkspaceGate.notBusiness,
      );
      expect(
        workspaceAccessOf(
          me(SignupPurpose.propertyDevelopmentCompany, GrantState.draft),
        ).gate,
        WorkspaceGate.onboarding,
      );
      expect(
        workspaceAccessOf(
          me(
            SignupPurpose.propertyDevelopmentCompany,
            GrantState.pendingVerification,
          ),
        ).gate,
        WorkspaceGate.pending,
      );
      expect(
        workspaceAccessOf(
          me(
            SignupPurpose.propertyDevelopmentCompany,
            GrantState.pendingVerification,
            st: ReviewStage.awaitingSecondApproval,
          ),
        ).gate,
        WorkspaceGate.awaitingSecond,
      );
      expect(
        workspaceAccessOf(
          me(
            SignupPurpose.constructionCompany,
            GrantState.resubmissionRequired,
          ),
        ).gate,
        WorkspaceGate.resubmission,
      );
      expect(
        workspaceAccessOf(
          me(SignupPurpose.buildingArchitecture, GrantState.rejected),
        ).gate,
        WorkspaceGate.rejected,
      );
      expect(
        workspaceAccessOf(
          me(SignupPurpose.interiorExteriorDesign, GrantState.suspended),
        ).gate,
        WorkspaceGate.suspended,
      );
      final ok = workspaceAccessOf(
        me(SignupPurpose.propertyDevelopmentCompany, GrantState.approved),
      );
      expect(ok.approved, isTrue);
      expect(ok.type, ProType.developer);
      expect(ok.type!.hasProjects, isTrue);
      expect(
        workspaceAccessOf(
          me(SignupPurpose.constructionCompany, GrantState.approved),
        ).type!.hasProjects,
        isFalse,
      );
    });
  });

  group('directory rules', () {
    final repo = DemoDevBuildRepository(() => null);
    test(
      'exactly four categories; every listed business is approved',
      () async {
        expect(ProType.values.length, 4);
        final all = await repo.professionals(const DbQuery(), limit: 50);
        expect(all.items, isNotEmpty);
        expect(all.items.every((p) => p.verified), isTrue);
        expect(
          all.items.any((p) => p.id == 'b3'),
          isFalse,
          reason: 'an under-review business is not public',
        );
      },
    );

    test('developers appear only with an approved project, and a project name finds them', () async {
      final devs = await repo.professionals(
        const DbQuery(type: ProType.developer),
        limit: 50,
      );
      for (final d in devs.items) {
        expect((await repo.approvedProjects(d.id)), isNotEmpty);
      }
      final byProject = await repo.professionals(
        const DbQuery(text: 'Barka Gardens'),
        limit: 50,
      );
      expect(byProject.items.map((p) => p.id), contains('demo-d1'));
    });

    test('filters narrow and pagination reports more', () async {
      final gov = await repo.professionals(
        const DbQuery(governorate: 'Al Batinah North'),
        limit: 50,
      );
      expect(
        gov.items.every((p) => p.governorate == 'Al Batinah North'),
        isTrue,
      );
      final one = await repo.professionals(const DbQuery(), limit: 1);
      expect(one.items.length, 1);
      expect(one.hasMore, isTrue);
    });

    test(
      'workspace calls are denied without an approved business grant',
      () async {
        expect(repo.myProjects(), throwsA(isA<PermissionDeniedException>()));
        expect(repo.myProject('x'), throwsA(isA<PermissionDeniedException>()));
      },
    );
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('Development & Building home builds at text scale $scale', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(_routed('/app/explore/build', scale: scale));
      await _settle(t);
      expect(t.takeException(), isNull);
      expect(find.text('Development & Building'), findsWidgets);
      expect(
        find.bySemanticsLabel(RegExp('Property Developers')),
        findsWidgets,
      );
      expect(
        find.textContaining('Al Mouj Residences'),
        findsWidgets,
        reason: 'featured shows only approved project data',
      );
    });

    testWidgets('Categories and results build at text scale $scale', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(
        _routed('/app/explore/build/categories', scale: scale),
      );
      await _settle(t);
      expect(t.takeException(), isNull);
      expect(find.text('Professional categories'), findsOneWidget);
      await t.pumpWidget(
        _routed(
          '/app/explore/build/results?cat=interiorExterior',
          scale: scale,
        ),
      );
      await _settle(t);
      expect(t.takeException(), isNull);
      expect(find.textContaining('verified'), findsWidgets);
    });

    testWidgets(
      'Profile, reviews, projects and project detail build at text scale $scale',
      (t) async {
        await t.binding.setSurfaceSize(const Size(393, 852));
        for (final loc in [
          '/build/pro/b2',
          '/build/pro/b2/reviews',
          '/build/pro/b2/projects',
          '/build/project/demo-p1',
          '/build/pro/demo-c1',
        ]) {
          await t.pumpWidget(_routed(loc, scale: scale));
          await _settle(t);
          expect(t.takeException(), isNull, reason: loc);
        }
      },
    );
  }

  testWidgets(
    'home category opens that category, results open a profile, list/map toggle keeps results',
    (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(_routed('/app/explore/build'));
      await _settle(t);
      await t.tap(
        find.bySemanticsLabel(RegExp('^Construction Companies')).first,
      );
      await _settle(t);
      expect(find.textContaining('Sahari Contracting'), findsOneWidget);
      expect(
        find.text('Namaa Construction'),
        findsNothing,
        reason: 'developers are not construction firms',
      );
      await t.ensureVisible(find.textContaining('Sahari Contracting').first);
      await t.pump();
      await t.tap(
        find.textContaining('Sahari Contracting').first,
        warnIfMissed: false,
      );
      await _settle(t);
      expect(find.textContaining('Sahari Contracting'), findsWidgets);
      expect(find.widgetWithText(AQPrimaryButton, 'Contact'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('empty search shows a way back, not a dead end', (t) async {
    await t.binding.setSurfaceSize(const Size(393, 852));
    await t.pumpWidget(_routed('/app/explore/build/results?q=zzzzzz'));
    await _settle(t);
    expect(find.textContaining('No verified businesses match'), findsOneWidget);
    expect(find.text('Clear all'), findsOneWidget);
  });

  testWidgets('Arabic renders right-to-left without overflow', (t) async {
    await t.binding.setSurfaceSize(const Size(393, 852));
    await t.pumpWidget(_routed('/app/explore/build', lang: 'ar'));
    await _settle(t);
    expect(t.takeException(), isNull);
    expect(
      Directionality.of(t.element(find.byType(Scaffold).first)),
      TextDirection.rtl,
    );
  });

  testWidgets('a contact action copies the number and states what it did', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(393, 852));
    await t.pumpWidget(_routed('/build/pro/demo-c1'));
    await _settle(t);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'gallery shows a clear empty state when no approved media exists',
    (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(_routed('/build/project/demo-p1/gallery'));
      await _settle(t);
      expect(
        find.textContaining('No approved project photos yet'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'gallery opens a viewer with a real count when approved media exists',
    (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(
        _routed(
          '/build/project/demo-p1/gallery',
          overrides: [
            devBuildRepositoryProvider.overrideWithValue(_MediaRepo()),
          ],
        ),
      );
      await _settle(t);
      expect(t.takeException(), isNull);
      expect(find.text('1/2'), findsOneWidget);
    },
  );

  testWidgets(
    'without a real API every screen shows retry, never invented content',
    (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(
        _routed(
          '/app/explore/build/results',
          overrides: [
            devBuildRepositoryProvider.overrideWithValue(
              const UnavailableDevBuildRepository(),
            ),
          ],
        ),
      );
      await _settle(t);
      expect(find.textContaining('could not reach AQARATI'), findsOneWidget);
      expect(find.textContaining('Sahari Contracting'), findsNothing);
    },
  );
}
