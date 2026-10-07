import 'enums.dart';
import 'money.dart';

class QuoteLineItem {
  final String label;
  final int quantity;
  final Money unitPrice;

  const QuoteLineItem({
    required this.label,
    required this.quantity,
    required this.unitPrice,
  });

  Money get subtotal => unitPrice * quantity.toDouble();
}

class Quote {
  final String id;
  final String conversationId;
  final List<QuoteLineItem> items;
  final Money aqaratiFee;
  final String terms;
  final DateTime expiresAt;
  final QuoteStatus status;

  const Quote({
    required this.id,
    required this.conversationId,
    required this.items,
    required this.aqaratiFee,
    this.terms = '',
    required this.expiresAt,
    required this.status,
  });

  Money get subtotal =>
      items.fold(const Money(0), (sum, item) => sum + item.subtotal);

  Money get total => subtotal + aqaratiFee;
}
