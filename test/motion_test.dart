import 'package:aqarati_app/core/aq/aq_primitives.dart';
import 'package:aqarati_app/core/aq/aq_scene.dart';
import 'package:aqarati_app/core/aq/aq_tokens.dart';
import 'package:aqarati_app/data/demo/demo_providers.dart';
import 'package:aqarati_app/features/entry/models/signup_purpose.dart';
import 'package:aqarati_app/features/flow/screens/signup_form_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget localized(Widget home, {bool rtl = false, bool reduce = false, ThemeMode mode = ThemeMode.light, Widget Function(BuildContext, Widget)? wrap}) => MaterialApp(
      themeMode: mode,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      locale: Locale(rtl ? 'ar' : 'en'),
      localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      supportedLocales: const [Locale('en'), Locale('ar')],
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduce), child: wrap == null ? child! : wrap(c, child!)),
      home: home,
    );

void main() {
  group('motion tokens match the brief', () {
    int ms(Duration d) => d.inMilliseconds;
    test('durations are inside the specified ranges', () {
      expect(ms(AQMotion.tapDown), inInclusiveRange(90, 140));
      expect(ms(AQMotion.tapUp), inInclusiveRange(130, 180));
      expect(ms(AQMotion.icon), inInclusiveRange(150, 220));
      expect(ms(AQMotion.page), inInclusiveRange(240, 320));
      expect(ms(AQMotion.sheet), inInclusiveRange(260, 340));
      expect(ms(AQMotion.dialog), inInclusiveRange(180, 240));
      expect(ms(AQMotion.formStep), inInclusiveRange(220, 280));
      expect(ms(AQMotion.theme), inInclusiveRange(280, 420));
      expect(ms(AQMotion.themeReduced), inInclusiveRange(80, 120));
      expect(ms(AQMotion.state), inInclusiveRange(180, 280));
      expect(AQMotion.routeTravel, inInclusiveRange(16, 24));
      expect(AQMotion.stepTravel, inInclusiveRange(12, 18));
    });
  });

  group('theme transition', () {
    test('palette interpolation has exact endpoints and a distinct midpoint', () {
      expect(identical(AQColors.lerp(AQColors.light, AQColors.dark, 0), AQColors.light), isTrue);
      expect(identical(AQColors.lerp(AQColors.light, AQColors.dark, 1), AQColors.dark), isTrue);
      final mid = AQColors.lerp(AQColors.light, AQColors.dark, 0.5);
      expect(mid.background, isNot(AQColors.light.background));
      expect(mid.background, isNot(AQColors.dark.background));
      expect(mid.ink, isNot(AQColors.light.ink));
      expect(AQColors.lerp(AQColors.light, AQColors.dark, 0.3).brightness, Brightness.light);
      expect(AQColors.lerp(AQColors.light, AQColors.dark, 0.7).brightness, Brightness.dark);
    });

    testWidgets('switching the in-app mode fades the palette (no snap) and ends exactly on dark', (t) async {
      final mode = ValueNotifier(ThemeMode.light);
      final seen = <Color>[];
      await t.pumpWidget(ValueListenableBuilder<ThemeMode>(
        valueListenable: mode,
        builder: (c, m, _) => localized(
          Builder(builder: (ctx) {
            seen.add(AQColors.of(ctx).background);
            return const Text('probe');
          }),
          mode: m,
          wrap: (c, child) => AQThemeTransition(mode: m, child: child),
        ),
      ));
      await t.pump();
      expect(seen.last, AQColors.light.background);
      seen.clear();
      mode.value = ThemeMode.dark;
      await t.pump();
      await t.pump(const Duration(milliseconds: 120));
      final midway = seen.last;
      expect(midway, isNot(AQColors.light.background));
      expect(midway, isNot(AQColors.dark.background), reason: 'mid-transition colour is an interpolation');
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 40));
      }
      await t.pump(const Duration(milliseconds: 600));
      expect(seen.last, AQColors.dark.background);
      expect(seen.toSet().length, greaterThan(3), reason: 'several distinct frames, not a single jump');
    });

    testWidgets('reduced motion finishes the change within about 100 ms', (t) async {
      final mode = ValueNotifier(ThemeMode.light);
      Color? seen;
      await t.pumpWidget(ValueListenableBuilder<ThemeMode>(
        valueListenable: mode,
        builder: (c, m, _) => localized(
          Builder(builder: (ctx) {
            seen = AQColors.of(ctx).background;
            return const Text('probe');
          }),
          mode: m,
          reduce: true,
          wrap: (c, child) => AQThemeTransition(mode: m, child: child),
        ),
      ));
      mode.value = ThemeMode.dark;
      await t.pump();
      await t.pump(const Duration(milliseconds: 130));
      expect(seen, AQColors.dark.background);
    });

    testWidgets('form text, focus and scroll position survive a theme change', (t) async {
      final mode = ValueNotifier(ThemeMode.light);
      final controller = TextEditingController(text: 'Villa Marina');
      final scroll = ScrollController();
      await t.binding.setSurfaceSize(const Size(393, 600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(ValueListenableBuilder<ThemeMode>(
        valueListenable: mode,
        builder: (c, m, _) => localized(
          Scaffold(
            body: ListView(controller: scroll, children: [
              TextField(controller: controller),
              for (var i = 0; i < 30; i++) SizedBox(height: 60, child: Text('row $i')),
            ]),
          ),
          mode: m,
          wrap: (c, child) => AQThemeTransition(mode: m, child: child),
        ),
      ));
      scroll.jumpTo(240);
      await t.pump();
      mode.value = ThemeMode.dark;
      await t.pump(const Duration(milliseconds: 500));
      expect(controller.text, 'Villa Marina');
      expect(scroll.offset, 240);
    });

    testWidgets('without the scope the palette still follows the Material brightness', (t) async {
      Color? seen;
      await t.pumpWidget(localized(Builder(builder: (ctx) {
        seen = AQColors.of(ctx).background;
        return const SizedBox();
      }), mode: ThemeMode.dark));
      await t.pump(const Duration(milliseconds: 400));
      expect(seen, AQColors.dark.background);
    });
  });

  group('route transitions', () {
    Widget routerApp({required bool rtl, bool reduce = false}) {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (c, s) => Scaffold(body: Center(child: TextButton(onPressed: () => c.push('/b'), child: const Text('go')))), routes: [
          GoRoute(path: 'b', pageBuilder: (c, s) => AQRoute.forward(key: s.pageKey, child: const Scaffold(body: Align(alignment: AlignmentDirectional.topStart, child: Text('PAGE B'))))),
        ]),
      ]);
      return MaterialApp.router(
        routerConfig: router,
        locale: Locale(rtl ? 'ar' : 'en'),
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: const [Locale('en'), Locale('ar')],
        builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: reduce), child: child!),
      );
    }

    for (final rtl in [false, true]) {
      testWidgets('a push arrives from the logical forward side (${rtl ? 'RTL: from the left' : 'LTR: from the right'}) and pop reverses', (t) async {
        await t.pumpWidget(routerApp(rtl: rtl));
        await t.pumpAndSettle();
        await t.tap(find.text('go'));
        await t.pump();
        await t.pump(const Duration(milliseconds: 30));
        final early = t.getTopLeft(find.text('PAGE B')).dx;
        await t.pumpAndSettle();
        final settled = t.getTopLeft(find.text('PAGE B')).dx;
        // Travel is the configured number of pixels, in the direction of reading.
        final travel = early - settled;
        if (rtl) {
          expect(travel, lessThan(0), reason: 'RTL page starts to the left of its resting place');
        } else {
          expect(travel, greaterThan(0), reason: 'LTR page starts to the right of its resting place');
        }
        expect(travel.abs(), lessThanOrEqualTo(AQMotion.routeTravel + 0.5));
        expect(travel.abs(), greaterThan(4), reason: 'there is visible movement');

        // Back: same axis, reverse direction.
        final nav = t.state<NavigatorState>(find.byType(Navigator).first);
        nav.pop();
        await t.pump();
        await t.pump(const Duration(milliseconds: 40));
        final leaving = t.getTopLeft(find.text('PAGE B')).dx;
        expect((leaving - settled).sign, travel.sign, reason: 'pop drifts back toward the side it came from');
        await t.pumpAndSettle();
        expect(find.text('PAGE B'), findsNothing);
      });
    }

    testWidgets('reduced motion removes the travel: only a fade', (t) async {
      await t.pumpWidget(routerApp(rtl: false, reduce: true));
      await t.pumpAndSettle();
      await t.tap(find.text('go'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 30));
      final early = t.getTopLeft(find.text('PAGE B')).dx;
      await t.pumpAndSettle();
      expect(early, t.getTopLeft(find.text('PAGE B')).dx);
    });

    testWidgets('tab pages cross-fade without travel', (t) async {
      final router = GoRouter(routes: [
        ShellRoute(builder: (c, s, child) => Scaffold(body: child), routes: [
          GoRoute(path: '/', pageBuilder: (c, s) => AQRoute.tab(key: s.pageKey, child: Align(alignment: Alignment.topLeft, child: TextButton(onPressed: () => c.go('/two'), child: const Text('ONE'))))),
          GoRoute(path: '/two', pageBuilder: (c, s) => AQRoute.tab(key: s.pageKey, child: const Align(alignment: Alignment.topLeft, child: Text('TWO')))),
        ]),
      ]);
      await t.pumpWidget(MaterialApp.router(routerConfig: router));
      await t.pumpAndSettle();
      await t.tap(find.text('ONE'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      final early = t.getTopLeft(find.text('TWO')).dx;
      await t.pumpAndSettle();
      expect(find.text('TWO'), findsOneWidget);
      expect(early, t.getTopLeft(find.text('TWO')).dx, reason: 'no horizontal travel between tabs');
    });
  });

  group('navigation bar', () {
    testWidgets('one indicator slides to the selected tab', (t) async {
      final nav = AQNavController();
      var index = 0;
      late StateSetter set;
      await t.binding.setSurfaceSize(const Size(393, 700));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(localized(Scaffold(
        body: Stack(children: [
          StatefulBuilder(builder: (c, s) {
            set = s;
            return Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AQGlassNav(items: const [AQNavItem('home', 'Home'), AQNavItem('explore', 'Explore'), AQNavItem('activity', 'Activity'), AQNavItem('account', 'Account')], index: index, controller: nav, onSelected: (i) => set(() => index = i)),
            );
          }),
        ]),
      )));
      await t.pump();
      final start = t.getTopLeft(find.byKey(const ValueKey('nav-indicator'))).dx;
      await t.tap(find.text('Account'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 80));
      final mid = t.getTopLeft(find.byKey(const ValueKey('nav-indicator'))).dx;
      await t.pump(const Duration(milliseconds: 400));
      final end = t.getTopLeft(find.byKey(const ValueKey('nav-indicator'))).dx;
      expect(end, greaterThan(start + 150));
      expect(mid, inExclusiveRange(start, end), reason: 'it travels, it does not jump');
      expect(find.byKey(const ValueKey('nav-indicator')), findsOneWidget);
    });
  });

  group('press feedback', () {
    testWidgets('a button scales to 0.98 on press and returns to 1.0', (t) async {
      var taps = 0;
      await t.pumpWidget(localized(Scaffold(body: Center(child: AQPrimaryButton(label: 'Continue', onPressed: () => taps++)))));
      double scale() => t.widget<AnimatedScale>(find.descendant(of: find.byType(AQPrimaryButton), matching: find.byType(AnimatedScale)).first).scale;
      expect(scale(), 1.0);
      final g = await t.startGesture(t.getCenter(find.byType(AQPrimaryButton)));
      await t.pump();
      expect(scale(), 0.98);
      await g.up();
      await t.pump(const Duration(milliseconds: 200));
      expect(scale(), 1.0);
      expect(taps, 1, reason: 'the animation never blocks the action');
    });

    testWidgets('a disabled button does not respond to press', (t) async {
      await t.pumpWidget(localized(const Scaffold(body: Center(child: AQPrimaryButton(label: 'Continue', onPressed: null)))));
      final g = await t.startGesture(t.getCenter(find.byType(AQPrimaryButton)));
      await t.pump();
      expect(t.widget<AnimatedScale>(find.descendant(of: find.byType(AQPrimaryButton), matching: find.byType(AnimatedScale)).first).scale, 1.0);
      await g.up();
    });

    testWidgets('reduced motion keeps the pressed state but with no duration', (t) async {
      await t.pumpWidget(localized(Scaffold(body: Center(child: AQPrimaryButton(label: 'Continue', onPressed: () {}))), reduce: true));
      final g = await t.startGesture(t.getCenter(find.byType(AQPrimaryButton)));
      await t.pump();
      final s = t.widget<AnimatedScale>(find.descendant(of: find.byType(AQPrimaryButton), matching: find.byType(AnimatedScale)).first);
      expect(s.scale, 0.98);
      expect(s.duration, Duration.zero);
      await g.up();
    });
  });

  group('form step switcher', () {
    Widget host({required int step, required bool forward, bool rtl = false, bool reduce = false}) => localized(
          Scaffold(body: Align(alignment: AlignmentDirectional.topStart, child: AQStepSwitcher(stepKey: step, forward: forward, child: Align(alignment: AlignmentDirectional.topStart, child: SizedBox(width: 120, height: 40, child: Text('STEP $step')))))),
          rtl: rtl,
          reduce: reduce,
        );

    for (final rtl in [false, true]) {
      testWidgets('Next enters from the logical forward side, Back reverses (${rtl ? 'RTL' : 'LTR'})', (t) async {
        await t.pumpWidget(host(step: 0, forward: true, rtl: rtl));
        await t.pumpAndSettle();
        final rest = t.getTopLeft(find.text('STEP 0')).dx;
        await t.pumpWidget(host(step: 1, forward: true, rtl: rtl));
        await t.pump(const Duration(milliseconds: 20));
        final inFwd = t.getTopLeft(find.text('STEP 1')).dx - rest;
        await t.pumpAndSettle();
        expect(inFwd.sign, rtl ? -1 : 1);
        expect(inFwd.abs(), lessThanOrEqualTo(AQMotion.stepTravel + 0.5));

        await t.pumpWidget(host(step: 0, forward: false, rtl: rtl));
        await t.pump(const Duration(milliseconds: 20));
        final inBack = t.getTopLeft(find.text('STEP 0')).dx - rest;
        await t.pumpAndSettle();
        expect(inBack.sign, rtl ? 1 : -1, reason: 'Back arrives from the opposite side');
      });
    }

    testWidgets('only the current step remains after the transition and reduced motion is immediate', (t) async {
      await t.pumpWidget(host(step: 0, forward: true, reduce: true));
      await t.pumpWidget(host(step: 1, forward: true, reduce: true));
      await t.pump();
      await t.pump(const Duration(milliseconds: 1));
      expect(find.text('STEP 1'), findsOneWidget);
      expect(find.text('STEP 0'), findsNothing);
    });
  });

  group('signup form steps', () {
    Future<void> pumpForm(WidgetTester t, {bool rtl = false, bool reduce = false}) async {
      SharedPreferences.setMockInitialValues({});
      await t.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(ProviderScope(overrides: demoOverrides(), child: localized(const SignupFormScreen(purpose: SignupPurpose.userToShop), rtl: rtl, reduce: reduce)));
      await t.pump(const Duration(milliseconds: 900));
    }

    testWidgets('Next slides the new step in, Back returns, and the typed values survive both ways', (t) async {
      await pumpForm(t);
      final fields = find.byType(TextField);
      await t.enterText(fields.at(0), 'Ameen');
      await t.enterText(fields.at(1), 'Ali');
      await t.pump();
      await t.tap(find.byType(AQPrimaryButton));
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      expect(find.text('Where can we reach you?'), findsOneWidget, reason: 'the next step is already entering');
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text("Let's start with you."), findsNothing, reason: 'the old step has left');
      // Back: the previous step returns with its values.
      await t.tap(find.bySemanticsLabel('Back').first);
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text("Let's start with you."), findsOneWidget);
      expect(find.text('Ameen'), findsOneWidget);
      expect(find.text('Ali'), findsOneWidget);
    });

    testWidgets('an invalid Next keeps the step and its values, with the error shown', (t) async {
      await pumpForm(t);
      await t.enterText(find.byType(TextField).at(0), 'Ameen');
      await t.pump();
      await t.tap(find.byType(AQPrimaryButton));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text("Let's start with you."), findsOneWidget);
      expect(find.text('This field is required.'), findsOneWidget);
      expect(find.text('Ameen'), findsOneWidget);
    });

    testWidgets('reduced motion swaps the step with no leftover frame', (t) async {
      await pumpForm(t, reduce: true);
      await t.enterText(find.byType(TextField).at(0), 'A');
      await t.enterText(find.byType(TextField).at(1), 'B');
      await t.pump();
      await t.tap(find.byType(AQPrimaryButton));
      await t.pump();
      await t.pump(const Duration(milliseconds: 20));
      expect(find.text('Where can we reach you?'), findsOneWidget);
      expect(find.text("Let's start with you."), findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('renders and steps in Arabic RTL without error', (t) async {
      await pumpForm(t, rtl: true);
      await t.enterText(find.byType(TextField).at(0), 'أمين');
      await t.enterText(find.byType(TextField).at(1), 'علي');
      await t.pump();
      await t.tap(find.byType(AQPrimaryButton));
      await t.pump(const Duration(milliseconds: 600));
      expect(t.takeException(), isNull);
    });
  });

  group('favourite heart', () {
    testWidgets('pops once when the saved state changes, not on first build', (t) async {
      final saved = ValueNotifier(false);
      await t.pumpWidget(localized(Scaffold(body: Center(child: ValueListenableBuilder<bool>(valueListenable: saved, builder: (c, v, _) => AQHeart(saved: v, savedColor: Colors.red, idleColor: Colors.black))))));
      double scale() => (t.widget<Transform>(find.descendant(of: find.byType(AQHeart), matching: find.byType(Transform)).first)).transform.getMaxScaleOnAxis();
      expect(scale(), 1.0, reason: 'no animation on first build');
      saved.value = true;
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      expect(scale(), isNot(1.0), reason: 'pops while changing');
      await t.pump(const Duration(milliseconds: 400));
      expect(scale(), 1.0, reason: 'settles back and does not loop');
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('reduced motion changes the icon with no scale', (t) async {
      final saved = ValueNotifier(false);
      await t.pumpWidget(localized(Scaffold(body: Center(child: ValueListenableBuilder<bool>(valueListenable: saved, builder: (c, v, _) => AQHeart(saved: v, savedColor: Colors.red, idleColor: Colors.black)))), reduce: true));
      saved.value = true;
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      expect(t.widget<Transform>(find.descendant(of: find.byType(AQHeart), matching: find.byType(Transform)).first).transform.getMaxScaleOnAxis(), 1.0);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });
}
