import 'enums.dart';

/// Property verification — separate from identity/business verification.
/// "Is this particular property/listing valid?"
class PropertyVerification {
  final VerificationStatus status;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? note;

  const PropertyVerification({
    required this.status,
    this.submittedAt,
    this.verifiedAt,
    this.note,
  });

  bool get isVerified => status == VerificationStatus.verified;
}
