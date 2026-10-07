import 'enums.dart';

enum MaintenanceStatus { requested, quoted, scheduled, inProgress, completed }

class MaintenanceRequest {
  final String id;
  final String homeId;
  final ServiceCategory category;
  final String description;
  final MaintenanceStatus status;
  final DateTime createdAt;

  const MaintenanceRequest({
    required this.id,
    required this.homeId,
    required this.category,
    this.description = '',
    required this.status,
    required this.createdAt,
  });
}

class Inspection {
  final String id;
  final String homeId;
  final String label;
  final DateTime scheduledAt;
  final bool completed;

  const Inspection({
    required this.id,
    required this.homeId,
    required this.label,
    required this.scheduledAt,
    this.completed = false,
  });
}
