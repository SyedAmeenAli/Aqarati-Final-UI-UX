import '../../data/models/enums.dart';
import '../viewing/domain/viewing_models.dart';

/// Whose inbox a lead belongs to. The service decides who may see what; the app only asks for the
/// scope the signed-in role works in.
enum LeadScope { agent, developer, service }

/// The four record types. They are different records and are never merged or relabelled.
enum LeadKind { contact, viewingRequest, projectEnquiry, serviceRequest }

class Lead {
  final String id;
  final LeadKind kind;
  final DateTime receivedAt;

  /// Display name the customer allowed to share. Null when the service withheld it.
  final String? customerName;

  /// Phone number, present only when this caller is entitled to see it.
  final String? phone;
  final String message;

  // Property context (agent leads).
  final String? propertyId, propertyTitle, propertyImage;

  // Project context (developer enquiries).
  final String? projectId, projectName, projectImage;

  // Service request context.
  final ServiceCategory? serviceCategory;
  final String? serviceLocation, requestedTiming;

  // Viewing request context: mirrors the viewing record, never replaces it.
  final String? viewingId;
  final ViewingStatus? viewingStatus;
  final ViewingSlot? requestedSlot;

  /// Status code from the service for non-viewing leads, when the model has one. Null otherwise:
  /// the app never invents a status.
  final String? status;
  const Lead({
    required this.id,
    required this.kind,
    required this.receivedAt,
    this.customerName,
    this.phone,
    this.message = '',
    this.propertyId,
    this.propertyTitle,
    this.propertyImage,
    this.projectId,
    this.projectName,
    this.projectImage,
    this.serviceCategory,
    this.serviceLocation,
    this.requestedTiming,
    this.viewingId,
    this.viewingStatus,
    this.requestedSlot,
    this.status,
  });

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;
  bool get canRespondToViewing =>
      kind == LeadKind.viewingRequest &&
      viewingStatus == ViewingStatus.requested;

  Lead copyWith({ViewingStatus? viewingStatus}) => Lead(
    id: id,
    kind: kind,
    receivedAt: receivedAt,
    customerName: customerName,
    phone: phone,
    message: message,
    propertyId: propertyId,
    propertyTitle: propertyTitle,
    propertyImage: propertyImage,
    projectId: projectId,
    projectName: projectName,
    projectImage: projectImage,
    serviceCategory: serviceCategory,
    serviceLocation: serviceLocation,
    requestedTiming: requestedTiming,
    viewingId: viewingId,
    viewingStatus: viewingStatus ?? this.viewingStatus,
    requestedSlot: requestedSlot,
    status: status,
  );
}

/// What the host can do with a viewing request. This is the existing viewing lifecycle seen from the
/// host side (`PATCH /viewings/:id`), not a second booking system.
enum ViewingResponse { confirm, decline }
