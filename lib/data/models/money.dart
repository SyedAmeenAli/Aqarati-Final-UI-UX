import 'package:intl/intl.dart';

/// OMR-only money value object. Every price in the app must flow through this.
class Money {
  final double amount;

  const Money(this.amount);

  static final NumberFormat _formatter = NumberFormat.decimalPattern('en_US')
    ..maximumFractionDigits = 0;

  String get formatted => 'OMR ${_formatter.format(amount)}';

  /// Compact marker-style label, e.g. "OMR 125K" — matches the map
  /// reference's price-pill format exactly (19.05/19.06-map-markers).
  String get compact {
    if (amount >= 1000) {
      final k = amount / 1000;
      final rounded = k == k.roundToDouble() ? k.toInt().toString() : k.toStringAsFixed(1);
      return 'OMR ${rounded}K';
    }
    return 'OMR ${amount.toInt()}';
  }

  Money operator +(Money other) => Money(amount + other.amount);
  Money operator -(Money other) => Money(amount - other.amount);
  Money operator *(double factor) => Money(amount * factor);

  @override
  String toString() => formatted;
}
