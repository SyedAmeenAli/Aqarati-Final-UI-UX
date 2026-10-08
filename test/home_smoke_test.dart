import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aqarati_app/features/workspace/aq_home.dart';

Widget _app(Widget child, {double scale = 1}) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
        supportedLocales: const [Locale('en'), Locale('ar')],
        home: MediaQuery(data: MediaQueryData(size: const Size(393, 852), textScaler: TextScaler.linear(scale)), child: Scaffold(body: child)),
      ),
    );

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('Home builds at text scale $scale', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(_app(const AQHomeScreen(), scale: scale));
      await t.pump(const Duration(seconds: 1));
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
    });
    testWidgets('Explore builds at text scale $scale', (t) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      await t.pumpWidget(_app(const AQExploreScreen(), scale: scale));
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
    });
  }
}
