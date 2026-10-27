import '../../data/models/enums.dart';

/// The only fee wording the product has approved. No rate is calculated, no payment is taken: the fee
/// model is open decision 26 (a proposed single disclosed rate up to 2%, fixed per listing at approval),
/// and brokerage licensing is on hold, so the app shows this sentence and records the acceptance.
const kEBrokerFeeDisclosure = 'Aqary Real Estate fees will apply up to 2%';

/// Item state machine (architecture v2.6 section 19): draft -> pending_verification ->
/// approved | resubmission_required | rejected. Only a reviewer decides; nothing here approves.
enum EBrokerStatus {
  pendingVerification,
  resubmissionRequired,
  approved,
  rejected,
}

class EBrokerInput {
  final String title, description;
  final PropertyType type;
  final String governorate, wilayat;
  final double sizeSqm, priceOmr;
  final String titleDeed;

  /// Names only: the demo keeps no file content. A real service receives the uploads.
  final String ownerIdName, deedDocName;
  final List<String> photoNames;

  /// The person saw [kEBrokerFeeDisclosure] and accepted it.
  final bool feeAccepted;
  const EBrokerInput({
    required this.title,
    required this.description,
    required this.type,
    required this.governorate,
    required this.wilayat,
    required this.sizeSqm,
    required this.priceOmr,
    required this.titleDeed,
    required this.ownerIdName,
    required this.deedDocName,
    required this.photoNames,
    required this.feeAccepted,
  });
}

class EBrokerSubmission {
  final String id;
  final EBrokerInput input;
  final EBrokerStatus status;
  final String? feedback;
  final DateTime submittedAt;

  /// When the acceptance of the disclosure was recorded.
  final DateTime? feeAcceptedAt;
  const EBrokerSubmission({
    required this.id,
    required this.input,
    required this.status,
    this.feedback,
    required this.submittedAt,
    this.feeAcceptedAt,
  });

  bool get canResubmit => status == EBrokerStatus.resubmissionRequired;

  EBrokerSubmission copyWith({
    EBrokerInput? input,
    EBrokerStatus? status,
    String? feedback,
    DateTime? feeAcceptedAt,
  }) => EBrokerSubmission(
    id: id,
    input: input ?? this.input,
    status: status ?? this.status,
    feedback: feedback ?? this.feedback,
    submittedAt: submittedAt,
    feeAcceptedAt: feeAcceptedAt ?? this.feeAcceptedAt,
  );
}

/// The same title deed is already in a submission.
class EBrokerDuplicateException implements Exception {
  const EBrokerDuplicateException();
}

String normaliseEBrokerDeed(String raw) =>
    raw.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
bool eBrokerDeedValid(String raw) =>
    RegExp(r'^[A-Z0-9]{6,20}$').hasMatch(normaliseEBrokerDeed(raw));

/// JPG or PNG by signature, not by file name.
bool isJpgOrPng(List<int> b) =>
    b.length >= 4 &&
    ((b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) ||
        (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47));
