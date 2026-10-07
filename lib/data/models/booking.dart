import 'enums.dart';
import 'money.dart';

class Booking {
  final String id;
  final BookingContext context;
  final String contextTitle;
  final DateTime date;
  final String timeSlotLabel;
  final String locationLabel;
  final Money price;
  final BookingStatus status;

  const Booking({
    required this.id,
    required this.context,
    required this.contextTitle,
    required this.date,
    required this.timeSlotLabel,
    required this.locationLabel,
    required this.price,
    required this.status,
  });
}
