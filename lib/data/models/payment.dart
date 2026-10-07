import 'enums.dart';
import 'money.dart';

/// Payments are OMR-only. No live payment integration — this models the
/// abstraction a real provider will fill in later.
class Payment {
  final String id;
  final String contextTitle;
  final Money amount;
  final Money aqaratiFee;
  final String paymentMethodLabel; // e.g. "Visa •••• 4421" — mock only
  final PaymentStatus status;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.contextTitle,
    required this.amount,
    required this.aqaratiFee,
    required this.paymentMethodLabel,
    required this.status,
    required this.createdAt,
  });

  Money get total => amount + aqaratiFee;
}
