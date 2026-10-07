import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';
import '../../data/models/money.dart';
import 'calculator_models.dart';

class CalculatorScreen extends StatefulWidget {
  final CalculatorType type;

  const CalculatorScreen({super.key, required this.type});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final Map<String, TextEditingController> _controllers = {};
  List<MapEntry<String, String>>? _results;

  List<String> get _fields {
    switch (widget.type) {
      case CalculatorType.emi:
        return ['Property price (OMR)', 'Down payment (%)', 'Interest rate (% p.a.)', 'Loan term (years)'];
      case CalculatorType.affordability:
        return ['Monthly income (OMR)', 'Other monthly debts (OMR)', 'Down payment available (OMR)', 'Interest rate (% p.a.)'];
      case CalculatorType.downPayment:
        return ['Property price (OMR)', 'Down payment (%)'];
      case CalculatorType.rentalYield:
        return ['Property price (OMR)', 'Monthly rent (OMR)'];
      case CalculatorType.roi:
        return ['Total investment (OMR)', 'Net annual profit (OMR)'];
      case CalculatorType.rentVsBuy:
        return ['Monthly rent (OMR)', 'Property price (OMR)', 'Down payment (%)', 'Years you plan to stay'];
      case CalculatorType.appreciation:
        return ['Current property value (OMR)', 'Annual appreciation (%)', 'Years'];
      case CalculatorType.constructionCost:
        return ['Built-up area (m²)', 'Rate per m² (OMR)'];
    }
  }

  double _val(String field) => double.tryParse(_controllers[field]?.text.replaceAll(',', '') ?? '') ?? 0;

  void _calculate() {
    List<MapEntry<String, String>> results;
    switch (widget.type) {
      case CalculatorType.emi:
        final price = _val('Property price (OMR)');
        final downPct = _val('Down payment (%)');
        final rate = _val('Interest rate (% p.a.)') / 100 / 12;
        final months = _val('Loan term (years)') * 12;
        final downPayment = price * downPct / 100;
        final loan = price - downPayment;
        final emi = rate == 0 || months == 0
            ? (months == 0 ? 0 : loan / months)
            : loan * rate * math.pow(1 + rate, months) / (math.pow(1 + rate, months) - 1);
        results = [
          MapEntry('Down payment', Money(downPayment).formatted),
          MapEntry('Loan amount', Money(loan).formatted),
          MapEntry('Monthly payment', Money(emi.toDouble()).formatted),
        ];
      case CalculatorType.affordability:
        final income = _val('Monthly income (OMR)');
        final debts = _val('Other monthly debts (OMR)');
        final downPayment = _val('Down payment available (OMR)');
        final rate = _val('Interest rate (% p.a.)') / 100 / 12;
        const months = 25 * 12;
        final maxPayment = (income * 0.4) - debts;
        final maxLoan = maxPayment <= 0 || rate == 0
            ? maxPayment * months
            : maxPayment * (math.pow(1 + rate, months) - 1) / (rate * math.pow(1 + rate, months));
        final maxPrice = maxLoan + downPayment;
        results = [
          MapEntry('Comfortable monthly payment', Money(maxPayment < 0 ? 0 : maxPayment).formatted),
          MapEntry('Estimated max property price', Money(maxPrice < 0 ? 0 : maxPrice.toDouble()).formatted),
        ];
      case CalculatorType.downPayment:
        final price = _val('Property price (OMR)');
        final pct = _val('Down payment (%)');
        final down = price * pct / 100;
        results = [
          MapEntry('Down payment', Money(down).formatted),
          MapEntry('Loan amount', Money(price - down).formatted),
        ];
      case CalculatorType.rentalYield:
        final price = _val('Property price (OMR)');
        final rent = _val('Monthly rent (OMR)');
        final annual = rent * 12;
        final yieldPct = price == 0 ? 0 : (annual / price) * 100;
        results = [
          MapEntry('Annual rent', Money(annual).formatted),
          MapEntry('Rental yield', '${yieldPct.toStringAsFixed(2)}%'),
        ];
      case CalculatorType.roi:
        final investment = _val('Total investment (OMR)');
        final profit = _val('Net annual profit (OMR)');
        final roi = investment == 0 ? 0 : (profit / investment) * 100;
        results = [MapEntry('Annual ROI', '${roi.toStringAsFixed(2)}%')];
      case CalculatorType.rentVsBuy:
        final rent = _val('Monthly rent (OMR)');
        final price = _val('Property price (OMR)');
        final downPct = _val('Down payment (%)');
        final years = _val('Years you plan to stay');
        final totalRent = rent * 12 * years;
        final downPayment = price * downPct / 100;
        final totalBuy = downPayment + (price * 0.01 * years); // rough maintenance+fees estimate
        results = [
          MapEntry('Total cost of renting', Money(totalRent).formatted),
          MapEntry('Total cost of buying (est.)', Money(totalBuy).formatted),
          MapEntry('Better option', totalBuy < totalRent ? 'Buying' : 'Renting'),
        ];
      case CalculatorType.appreciation:
        final value = _val('Current property value (OMR)');
        final rate = _val('Annual appreciation (%)') / 100;
        final years = _val('Years');
        final future = value * math.pow(1 + rate, years);
        results = [MapEntry('Projected future value', Money(future.toDouble()).formatted)];
      case CalculatorType.constructionCost:
        final area = _val('Built-up area (m²)');
        final rate = _val('Rate per m² (OMR)');
        results = [MapEntry('Estimated total cost', Money(area * rate).formatted)];
    }
    setState(() => _results = results);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    for (final f in _fields) {
      _controllers.putIfAbsent(f, () => TextEditingController());
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.type.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.type.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.xl),
            for (final field in _fields) ...[
              Text(field.toUpperCase(), style: theme.textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _controllers[field],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            const SizedBox(height: AppSpacing.sm),
            AqaratiButton(label: 'Calculate', fullWidth: true, onPressed: _calculate),
            if (_results != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.sand,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _results!
                      .map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r.key, style: theme.textTheme.bodyMedium),
                                Text(
                                  r.value,
                                  style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
