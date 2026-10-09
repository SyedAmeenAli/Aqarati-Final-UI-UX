import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:aqarati_app/features/calculators/calculator_logic.dart';
import 'package:aqarati_app/features/calculators/calculator_models.dart';
import 'package:aqarati_app/features/calculators/calculator_screen.dart';
import 'package:aqarati_app/features/calculators/calculators_list_screen.dart';

double _v(List<CalcOut> o, String key) => o.firstWhere((e) => e.labelKey == key).value;

void main() {
  test('loan payment matches the standard formula', () {
    final o = calculate(CalculatorType.emi, {'price': 100000, 'downPct': 20, 'rate': 6, 'term': 20})!;
    expect(_v(o, 'calc.o.down'), 20000);
    expect(_v(o, 'calc.o.loan'), 80000);
    expect(_v(o, 'calc.o.monthly'), closeTo(573.14, 0.01));
    expect(_v(o, 'calc.o.interest'), closeTo(573.14 * 240 - 80000, 3));
  });

  test('zero interest splits the loan evenly', () {
    final o = calculate(CalculatorType.emi, {'price': 120000, 'downPct': 0, 'rate': 0, 'term': 10})!;
    expect(_v(o, 'calc.o.monthly'), 1000);
  });

  test('missing or silly inputs give no result', () {
    expect(calculate(CalculatorType.emi, {'price': null, 'downPct': 20, 'rate': 5, 'term': 25}), isNull);
    expect(calculate(CalculatorType.emi, {'price': 100000, 'downPct': 120, 'rate': 5, 'term': 25}), isNull);
    expect(calculate(CalculatorType.rentalYield, {'price': 0, 'rent': 500}), isNull);
    expect(calculate(CalculatorType.roi, {'invest': 0, 'profit': 10}), isNull);
  });

  test('yield, ROI, growth and build cost', () {
    expect(_v(calculate(CalculatorType.rentalYield, {'price': 100000, 'rent': 500})!, 'calc.o.yield'), closeTo(6, 1e-9));
    expect(_v(calculate(CalculatorType.roi, {'invest': 50000, 'profit': 4000})!, 'calc.o.roi'), closeTo(8, 1e-9));
    expect(_v(calculate(CalculatorType.appreciation, {'value': 100000, 'growth': 10, 'years': 2})!, 'calc.o.future'), closeTo(121000, 1e-6));
    expect(_v(calculate(CalculatorType.constructionCost, {'area': 300, 'rateM2': 250})!, 'calc.o.build'), 75000);
  });

  test('affordability stays inside the income share and never goes negative', () {
    final o = calculate(CalculatorType.affordability, {'income': 2000, 'debts': 900, 'downAvail': 10000, 'rate': 5})!;
    expect(_v(o, 'calc.o.comfort'), 0);
    expect(_v(o, 'calc.o.maxPrice'), 10000);
  });

  test('rent or buy compares like with like', () {
    final cheapRent = calculate(CalculatorType.rentVsBuy, {'rent': 200, 'price': 200000, 'downPct': 20, 'rate': 6, 'stay': 5})!;
    expect(cheapRent.first.text, 'calc.o.renting');
    final dearRent = calculate(CalculatorType.rentVsBuy, {'rent': 2500, 'price': 100000, 'downPct': 20, 'rate': 4, 'stay': 5})!;
    expect(dearRent.first.text, 'calc.o.buying');
  });

  testWidgets('list and every calculator build at 1x and 2x text', (t) async {
    await t.binding.setSurfaceSize(const Size(393, 852));
    for (final scale in [1.0, 2.0]) {
      Widget app(Widget child) => ProviderScope(
            child: MaterialApp(
              localizationsDelegates: const [GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
              home: MediaQuery(data: MediaQueryData(size: const Size(393, 852), textScaler: TextScaler.linear(scale)), child: child),
            ),
          );
      await t.pumpWidget(app(const CalculatorsListScreen()));
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
      for (final type in CalculatorType.values) {
        await t.pumpWidget(app(CalculatorScreen(type: type)));
        await t.pump(const Duration(seconds: 2));
        expect(t.takeException(), isNull, reason: '${type.name} at $scale');
      }
    }
  });
}
