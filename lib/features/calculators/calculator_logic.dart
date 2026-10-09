import 'dart:math' as math;
import 'calculator_models.dart';

enum CalcFormat { money, percent, years, text }

/// One input on a calculator. [key] doubles as the localisation suffix (`calc.f.<key>`).
class CalcField {
  final String key;
  final String? unit; // 'OMR', '%', 'yrs', 'm²'
  final String? initial;
  const CalcField(this.key, {this.unit, this.initial});
}

/// One line of output. [labelKey] is a localisation key; for [CalcFormat.text] the
/// [text] is itself a localisation key.
class CalcOut {
  final String labelKey;
  final double value;
  final CalcFormat format;
  final String? text;
  final bool hero;
  const CalcOut(this.labelKey, this.value, this.format, {this.text, this.hero = false});
}

const kLoanTermYears = 25;
const kAffordabilityShare = 0.4;
const kUpkeepShare = 0.01;

List<CalcField> calcFields(CalculatorType t) => switch (t) {
      CalculatorType.emi => const [CalcField('price', unit: 'OMR'), CalcField('downPct', unit: '%', initial: '20'), CalcField('rate', unit: '%', initial: '5.5'), CalcField('term', unit: 'yrs', initial: '25')],
      CalculatorType.affordability => const [CalcField('income', unit: 'OMR'), CalcField('debts', unit: 'OMR', initial: '0'), CalcField('downAvail', unit: 'OMR', initial: '0'), CalcField('rate', unit: '%', initial: '5.5')],
      CalculatorType.downPayment => const [CalcField('price', unit: 'OMR'), CalcField('downPct', unit: '%', initial: '20')],
      CalculatorType.rentalYield => const [CalcField('price', unit: 'OMR'), CalcField('rent', unit: 'OMR')],
      CalculatorType.roi => const [CalcField('invest', unit: 'OMR'), CalcField('profit', unit: 'OMR')],
      CalculatorType.rentVsBuy => const [CalcField('rent', unit: 'OMR'), CalcField('price', unit: 'OMR'), CalcField('downPct', unit: '%', initial: '20'), CalcField('rate', unit: '%', initial: '5.5'), CalcField('stay', unit: 'yrs', initial: '5')],
      CalculatorType.appreciation => const [CalcField('value', unit: 'OMR'), CalcField('growth', unit: '%', initial: '3'), CalcField('years', unit: 'yrs', initial: '5')],
      CalculatorType.constructionCost => const [CalcField('area', unit: 'm²'), CalcField('rateM2', unit: 'OMR')],
    };

/// Monthly payment on [loan] over [months] at a monthly [rate] (fraction, e.g. 0.004).
double monthlyPayment(double loan, double rate, int months) {
  if (months <= 0 || loan <= 0) return 0;
  if (rate == 0) return loan / months;
  final g = math.pow(1 + rate, months);
  return loan * rate * g / (g - 1);
}

/// Balance left after [paid] payments.
double balanceAfter(double loan, double rate, int months, int paid) {
  if (loan <= 0) return 0;
  if (rate == 0) return loan * (1 - paid / months);
  final pay = monthlyPayment(loan, rate, months);
  return loan * math.pow(1 + rate, paid) - pay * (math.pow(1 + rate, paid) - 1) / rate;
}

/// Results for [t] from the entered [v], or null while the required inputs are missing
/// or out of range. Nothing is ever computed from guessed values.
List<CalcOut>? calculate(CalculatorType t, Map<String, double?> v) {
  double? g(String k) => v[k];
  bool pos(String k) => (g(k) ?? 0) > 0;
  bool pct(String k) => g(k) != null && g(k)! >= 0 && g(k)! <= 100;
  bool nonNeg(String k) => g(k) != null && g(k)! >= 0;

  switch (t) {
    case CalculatorType.emi:
      if (!pos('price') || !pct('downPct') || !nonNeg('rate') || g('rate')! > 60 || !pos('term') || g('term')! > 50) return null;
      final down = g('price')! * g('downPct')! / 100;
      final loan = g('price')! - down;
      final months = (g('term')! * 12).round();
      final pay = monthlyPayment(loan, g('rate')! / 100 / 12, months);
      return [
        CalcOut('calc.o.monthly', pay, CalcFormat.money, hero: true),
        CalcOut('calc.o.down', down, CalcFormat.money),
        CalcOut('calc.o.loan', loan, CalcFormat.money),
        CalcOut('calc.o.interest', pay * months - loan, CalcFormat.money),
        CalcOut('calc.o.totalPaid', pay * months + down, CalcFormat.money),
      ];
    case CalculatorType.affordability:
      if (!pos('income') || !nonNeg('debts') || !nonNeg('downAvail') || !nonNeg('rate') || g('rate')! > 60) return null;
      final room = g('income')! * kAffordabilityShare - g('debts')!;
      final months = kLoanTermYears * 12;
      final r = g('rate')! / 100 / 12;
      final maxLoan = room <= 0 ? 0.0 : (r == 0 ? room * months : room * (math.pow(1 + r, months) - 1) / (r * math.pow(1 + r, months)));
      return [
        CalcOut('calc.o.maxPrice', maxLoan + g('downAvail')!, CalcFormat.money, hero: true),
        CalcOut('calc.o.comfort', room < 0 ? 0 : room, CalcFormat.money),
        CalcOut('calc.o.maxLoan', maxLoan, CalcFormat.money),
      ];
    case CalculatorType.downPayment:
      if (!pos('price') || !pct('downPct')) return null;
      final down = g('price')! * g('downPct')! / 100;
      return [CalcOut('calc.o.down', down, CalcFormat.money, hero: true), CalcOut('calc.o.loan', g('price')! - down, CalcFormat.money)];
    case CalculatorType.rentalYield:
      if (!pos('price') || !nonNeg('rent')) return null;
      final annual = g('rent')! * 12;
      return [CalcOut('calc.o.yield', annual / g('price')! * 100, CalcFormat.percent, hero: true), CalcOut('calc.o.annualRent', annual, CalcFormat.money)];
    case CalculatorType.roi:
      if (!pos('invest') || g('profit') == null) return null;
      return [CalcOut('calc.o.roi', g('profit')! / g('invest')! * 100, CalcFormat.percent, hero: true), CalcOut('calc.o.payback', g('profit')! > 0 ? g('invest')! / g('profit')! : 0, CalcFormat.years)];
    case CalculatorType.rentVsBuy:
      if (!pos('rent') || !pos('price') || !pct('downPct') || !nonNeg('rate') || g('rate')! > 60 || !pos('stay') || g('stay')! > kLoanTermYears) return null;
      final price = g('price')!;
      final loan = price - price * g('downPct')! / 100;
      final r = g('rate')! / 100 / 12;
      final months = kLoanTermYears * 12;
      final paid = (g('stay')! * 12).round();
      final pay = monthlyPayment(loan, r, months);
      final interest = pay * paid - (loan - balanceAfter(loan, r, months, paid));
      final upkeep = price * kUpkeepShare * g('stay')!;
      final buy = interest + upkeep;
      final rent = g('rent')! * 12 * g('stay')!;
      return [
        CalcOut('calc.o.better', 0, CalcFormat.text, text: buy < rent ? 'calc.o.buying' : 'calc.o.renting', hero: true),
        CalcOut('calc.o.rentCost', rent, CalcFormat.money),
        CalcOut('calc.o.buyCost', buy, CalcFormat.money),
      ];
    case CalculatorType.appreciation:
      if (!pos('value') || g('growth') == null || g('growth')! < -50 || g('growth')! > 100 || !pos('years') || g('years')! > 100) return null;
      final future = g('value')! * math.pow(1 + g('growth')! / 100, g('years')!);
      return [CalcOut('calc.o.future', future.toDouble(), CalcFormat.money, hero: true), CalcOut('calc.o.gain', future.toDouble() - g('value')!, CalcFormat.money)];
    case CalculatorType.constructionCost:
      if (!pos('area') || !pos('rateM2')) return null;
      return [CalcOut('calc.o.build', g('area')! * g('rateM2')!, CalcFormat.money, hero: true)];
  }
}
