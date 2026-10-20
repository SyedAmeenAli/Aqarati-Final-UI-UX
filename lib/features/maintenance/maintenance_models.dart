enum MaintenanceService { plumber, pool, ac, kitchen }

enum MaintenanceWindow { morning, afternoon, evening }

/// requested -> confirmed | declined; requested or confirmed -> cancelled; confirmed -> completed.
enum MaintenanceStatus { requested, confirmed, declined, cancelled, completed }

class MaintenanceBooking {
  final String id;
  final String providerId;
  final String providerName;
  final MaintenanceService service;
  final DateTime date;
  final MaintenanceWindow window;
  final String notes;
  final MaintenanceStatus status;
  final DateTime createdAt;
  const MaintenanceBooking({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.service,
    required this.date,
    required this.window,
    this.notes = '',
    required this.status,
    required this.createdAt,
  });

  bool get isOpen => status == MaintenanceStatus.requested || status == MaintenanceStatus.confirmed;
  bool get canCancel => isOpen;

  MaintenanceBooking copyWith({MaintenanceStatus? status}) => MaintenanceBooking(
        id: id,
        providerId: providerId,
        providerName: providerName,
        service: service,
        date: date,
        window: window,
        notes: notes,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}

/// Thrown when the same provider, service, day and time of day is already open.
class DuplicateBookingException implements Exception {
  const DuplicateBookingException();
}

/// Days a request may be made for: today up to this many days ahead.
const kMaintenanceHorizonDays = 14;
