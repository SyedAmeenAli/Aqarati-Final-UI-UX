import 'dart:async';
import 'dart:io';

import 'package:aqarati_app/core/aq/aq_primitives.dart';
import 'package:aqarati_app/core/domain/account_models.dart';
import 'package:aqarati_app/data/api/account_api.dart';
import 'package:aqarati_app/data/demo/demo_backend.dart';
import 'package:aqarati_app/data/models/enums.dart';
import 'package:aqarati_app/features/devbuild/db_models.dart';
import 'package:aqarati_app/features/devbuild/db_projects.dart';
import 'package:aqarati_app/features/devbuild/db_repository.dart';
import 'package:aqarati_app/features/devbuild/db_routes.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regression tests for the three browser bugs (submit spinner, stray comma, narrow-phone stepper).

DemoBackendState _state() => DemoBackendState()
  ..purpose = SignupPurpose.propertyDevelopmentCompany
  ..grant = GrantState.approved
  ..account = AccountState.active
  ..businessName = 'Test Business';

final _me = MeSession(
  account: AccountState.active,
  purpose: SignupPurpose.propertyDevelopmentCompany,
  grant: GrantState.approved,
);

/// Records every write. The first [failFirst] writes fail like an offline request; when [gate] is set
/// the write waits for it, which lets a test tap again while the first request is still in flight.
class _Spy extends DemoDevBuildRepository {
  _Spy({this.failFirst = 0, this.gate}) : super(_state, lag: Duration.zero);
  int failFirst;
  Completer<void>? gate;
  final keys = <String>[];
  @override
  Future<DbProject> saveProject(
    ProjectDraft draft, {
    required bool submit,
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    if (gate != null) await gate!.future;
    if (failFirst > 0) {
      failFirst--;
      throw const ApiException(ApiErrorCode.network);
    }
    return super.saveProject(
      draft,
      submit: submit,
      idempotencyKey: idempotencyKey,
    );
  }
}

Widget _app(String location, DevBuildRepository repo, {double scale = 1}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (c, s, child) => Scaffold(body: child),
        routes: dbShellRoutes(),
      ),
      ...dbStandaloneRoutes(),
      GoRoute(
        path: '/app/account',
        builder: (c, s) => const Scaffold(body: Text('ACCOUNT PAGE')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      devBuildRepositoryProvider.overrideWithValue(repo),
      meProvider.overrideWith((ref) async => _me),
    ],
    child: MaterialApp.router(
      routerConfig: router,
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

Future<void> _settle(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 400));
  }
}

Future<void> _tapText(WidgetTester t, String text) async {
  final f = find.text(text);
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _settle(t, 3);
}

ProjectDraft _valid() => ProjectDraft(
  name: 'Harbour Homes',
  type: PropertyType.villa,
  bedrooms: 4,
  bathrooms: 3,
  areaSqm: 280,
  governorate: 'Muscat',
  wilayat: 'As Seeb',
);

/// A saved draft opened on the review step, so the next tap on Submit is the submission under test.
Future<String> _draftAtReview(_Spy repo) async {
  final d = await repo.saveProject(
    _valid(),
    submit: false,
    idempotencyKey: 'seed-${repo.keys.length}',
  );
  repo.keys.clear();
  return '/workspace/projects/${d.id}/edit?step=4';
}

DbProject _project({String area = '', String wilayat = '', String gov = ''}) =>
    DbProject(
      id: 'x',
      orgId: 'o',
      name: 'Name',
      propertyType: PropertyType.villa,
      governorate: gov,
      wilayat: wilayat,
      area: area,
      status: ProjectStatus.draft,
      rawStatus: 'draft',
      updatedAt: DateTime(2026, 10, 1),
    );

void main() {
  group('bug 1: submit key and submission', () {
    test('idempotency keys are well formed and unique', () {
      final keys = {for (var i = 0; i < 5000; i++) dbNewIdempotencyKey()};
      expect(keys.length, 5000);
      for (final k in keys.take(50)) {
        expect(RegExp(r'^ik-\d+-\d+$').hasMatch(k), isTrue, reason: k);
      }
    });

    testWidgets('success: one write, confirmation says submitted for review', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(393, 1200));
      final repo = _Spy();
      final loc = await _draftAtReview(repo);
      await t.pumpWidget(_app(loc, repo));
      await _settle(t);
      await _tapText(t, 'Submit for review');
      await _settle(t, 8);
      expect(repo.keys.length, 1);
      expect(find.text('Submitted for review'), findsOneWidget);
      expect(
        (await repo.myProjects()).single.status,
        ProjectStatus.underReview,
      );
    });

    testWidgets(
      'failure then retry: spinner stops, error shown, retry reuses the key and creates one project',
      (t) async {
        await t.binding.setSurfaceSize(const Size(393, 1200));
        final repo = _Spy();
        final loc = await _draftAtReview(repo);
        repo.failFirst = 1;
        await t.pumpWidget(_app(loc, repo));
        await _settle(t);
        await _tapText(t, 'Submit for review');
        await _settle(t, 4);
        expect(find.textContaining('could not reach AQARATI'), findsOneWidget);
        expect(find.text('Submitted for review'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect((await repo.myProjects()).single.status, ProjectStatus.draft);

        await _tapText(t, 'Submit for review');
        await _settle(t, 8);
        expect(repo.keys.length, 2);
        expect(
          repo.keys[0],
          repo.keys[1],
          reason: 'a retry is the same request',
        );
        expect(find.text('Submitted for review'), findsOneWidget);
        expect((await repo.myProjects()).length, 1);
      },
    );

    testWidgets('a second tap while the first is in flight sends nothing', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(393, 1200));
      final gate = Completer<void>();
      final repo = _Spy();
      final loc = await _draftAtReview(repo);
      repo.gate = gate;
      await t.pumpWidget(_app(loc, repo));
      await _settle(t);
      await _tapText(t, 'Submit for review');
      // While the request is in flight the button shows progress; tapping where it is sends nothing.
      expect(find.text('Submit for review'), findsNothing);
      final btn = find.byType(AQPrimaryButton);
      for (var i = 0; i < 3; i++) {
        await t.tap(btn.last, warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(repo.keys.length, 1);
      gate.complete();
      await _settle(t, 8);
      expect(repo.keys.length, 1);
      expect(find.text('Submitted for review'), findsOneWidget);
      expect((await repo.myProjects()).length, 1);
    });

    test(
      'the repository replays a repeated key instead of writing twice',
      () async {
        final repo = _Spy();
        final a = await repo.saveProject(
          _valid(),
          submit: true,
          idempotencyKey: 'same',
        );
        final b = await repo.saveProject(
          _valid(),
          submit: true,
          idempotencyKey: 'same',
        );
        expect(b.id, a.id);
        expect((await repo.myProjects()).length, 1);
      },
    );
  });

  group('bug 2: location label', () {
    test('empty has no separators', () {
      expect(_project().locationLabel, '');
    });
    test('partial shows only what exists', () {
      expect(_project(gov: 'Muscat').locationLabel, 'Muscat');
      expect(_project(wilayat: 'As Seeb').locationLabel, 'As Seeb');
      expect(
        _project(wilayat: 'As Seeb', gov: 'Muscat').locationLabel,
        'As Seeb, Muscat',
      );
      expect(_project(area: '  ', gov: 'Muscat').locationLabel, 'Muscat');
    });
    test('complete is area, wilayat, governorate', () {
      expect(
        _project(
          area: 'Al Mouj',
          wilayat: 'As Seeb',
          gov: 'Muscat',
        ).locationLabel,
        'Al Mouj, As Seeb, Muscat',
      );
    });
    test('never starts or ends with a comma or doubles one', () {
      for (final a in ['', 'A']) {
        for (final w in ['', 'W']) {
          for (final g in ['', 'G']) {
            final s = _project(area: a, wilayat: w, gov: g).locationLabel;
            expect(s.startsWith(','), isFalse);
            expect(s.endsWith(','), isFalse);
            expect(s.contains(', ,'), isFalse);
            expect(s.contains(',,'), isFalse);
          }
        }
      }
    });

    testWidgets('a draft with no location shows no comma on the status page', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(393, 1200));
      final repo = _Spy();
      final d = await repo.saveProject(
        ProjectDraft(name: 'Bare Draft'),
        submit: false,
        idempotencyKey: 'bare',
      );
      await t.pumpWidget(_app('/workspace/projects/${d.id}', repo));
      await _settle(t);
      expect(find.textContaining('Bare Draft'), findsWidgets);
      expect(find.text(','), findsNothing);
      expect(find.textContaining(', ,'), findsNothing);
    });
  });

  group('bug 3: wizard stepper on phone widths', () {
    for (final w in [320.0, 360.0, 393.0, 412.0]) {
      for (final scale in [1.0, 1.5]) {
        for (var step = 0; step < 5; step++) {
          testWidgets('width $w scale $scale step ${step + 1}', (t) async {
            await t.binding.setSurfaceSize(Size(w, 900));
            final repo = _Spy();
            final d = await repo.saveProject(
              _valid(),
              submit: false,
              idempotencyKey: 'k$step',
            );
            await t.pumpWidget(
              _app(
                '/workspace/projects/${d.id}/edit?step=$step',
                repo,
                scale: scale,
              ),
            );
            await _settle(t);
            expect(t.takeException(), isNull);

            // Five distinct circles, left to right, inside the screen, never overlapping.
            final circles = find.byWidgetPredicate(
              (x) =>
                  x is AnimatedContainer &&
                  x.constraints?.maxWidth == 32 &&
                  x.constraints?.maxHeight == 32,
            );
            expect(circles, findsNWidgets(5));
            final rects = [
              for (var i = 0; i < 5; i++) t.getRect(circles.at(i)),
            ];
            for (var i = 0; i < 5; i++) {
              expect(rects[i].left >= 0 && rects[i].right <= w, isTrue);
              if (i > 0) expect(rects[i].left > rects[i - 1].right, isTrue);
            }

            // The caption names the real step and total, in full.
            final names = [
              'Basic information',
              'Property details',
              'Media & amenities',
              'Location',
              'Review & submit',
            ];
            final caption = find.text('Step ${step + 1} of 5: ${names[step]}');
            expect(caption, findsOneWidget);
            final cr = t.getRect(caption);
            expect(cr.left >= 0 && cr.right <= w, isTrue);

            // Exactly the circles before the current step show a check, the current one is numbered.
            expect(find.text('${step + 1}'), findsWidgets);
          });
        }
      }
    }
  });

  group('icons', () {
    test('every icon name handed to an AQ component exists as an asset', () {
      // AQPrimaryButton(leadingIcon:), AQIconButton(icon:) and AQIcon('x') load assets/icons/aq/<name>.svg;
      // a missing file is a 404 in the browser and an invisible icon.
      final re = RegExp(
        r"(?:leadingIcon:\s*|AQIcon\(\s*|AQIconButton\([^)]*?icon:\s*)'([a-z0-9-]+)'",
        dotAll: true,
      );
      final missing = <String>{};
      for (final f in Directory('lib/features/devbuild').listSync()) {
        if (f is! File || !f.path.endsWith('.dart')) continue;
        for (final m in re.allMatches(f.readAsStringSync())) {
          final n = m.group(1)!;
          if (!File('assets/icons/aq/$n.svg').existsSync()) {
            missing.add('$n (${f.uri.pathSegments.last})');
          }
        }
      }
      expect(missing, isEmpty);
    });
  });
}
