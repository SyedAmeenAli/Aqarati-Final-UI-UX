/// Professional engagements (client side): both the client and the professional confirm that they
/// worked together. Rules come from architecture v2.6 section 32: the other side confirms within 14
/// days, a review is allowed within 60 days of confirmation, related accounts are blocked. This is
/// separate from property viewings and maintenance bookings.
const kEngagementConfirmDays = 14;
const kReviewWindowDays = 60;

/// Where a request stands from the client's point of view.
/// awaitingProfessional -> confirmed | expired | declined | cancelled
/// awaitingMe (the professional asked the client first) -> confirmed | expired
enum EngagementPhase {
  awaitingProfessional,
  awaitingMe,
  confirmed,
  expired,
  declined,
  cancelled,
}

class ClientEngagement {
  final String id;
  final String professionalId;
  final String professionalName;

  /// Professional type key (construction, development, architecture, interior_exterior).
  final String professionalType;
  final EngagementPhase phase;
  final DateTime requestedAt;
  final DateTime? confirmedAt;
  const ClientEngagement({
    required this.id,
    required this.professionalId,
    required this.professionalName,
    required this.professionalType,
    required this.phase,
    required this.requestedAt,
    this.confirmedAt,
  });

  bool get isWaiting =>
      phase == EngagementPhase.awaitingProfessional ||
      phase == EngagementPhase.awaitingMe;

  /// Last moment the other side can confirm.
  DateTime get confirmBy =>
      requestedAt.add(const Duration(days: kEngagementConfirmDays));

  /// Last moment a review can be written (only once confirmed).
  DateTime? get reviewBy =>
      confirmedAt?.add(const Duration(days: kReviewWindowDays));

  /// A waiting request past its 14 days reads as expired even if the server has not flipped it yet.
  EngagementPhase phaseAt(DateTime now) =>
      isWaiting && now.isAfter(confirmBy) ? EngagementPhase.expired : phase;

  bool reviewOpenAt(DateTime now) =>
      phase == EngagementPhase.confirmed &&
      reviewBy != null &&
      !now.isAfter(reviewBy!);

  ClientEngagement copyWith({EngagementPhase? phase, DateTime? confirmedAt}) =>
      ClientEngagement(
        id: id,
        professionalId: professionalId,
        professionalName: professionalName,
        professionalType: professionalType,
        phase: phase ?? this.phase,
        requestedAt: requestedAt,
        confirmedAt: confirmedAt ?? this.confirmedAt,
      );
}

/// A request that is already open for this professional.
class DuplicateEngagementException implements Exception {
  final String existingId;
  const DuplicateEngagementException(this.existingId);
}

enum EngagementIneligibleReason {
  relatedAccount,
  professionalUnavailable,
  serviceUnavailable,
  notAllowed,
}

class EngagementIneligibleException implements Exception {
  final EngagementIneligibleReason reason;
  const EngagementIneligibleException(this.reason);
}

/// Every edge state the engagement flow can end in. Each one explains what happened and offers a
/// next step; none shows a reason that the service did not provide.
enum EngagementEdge {
  expired,
  declined,
  cancelled,
  duplicate,
  ineligible,
  relatedAccount,
  professionalUnavailable,
  serviceUnavailable,
  permissionDenied,
  error,
}
