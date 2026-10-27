/// Admin console domain. Sources: architecture v2.6 section 6 (admin platform, grant state machine,
/// 12 reason codes, 30-minute claim lock, four-eyes for developers) and the admin-web screen specs.
/// The role permission matrix (Ch. 47) is not in the repository, so [AdminPermissions] is a
/// front-end proposal; the API enforces the real rules and a rejected action is shown as such.
library;

import '../data/models/enums.dart';
import '../features/listings/listing_models.dart';

enum AdminRole { reviewer, seniorReviewer, superAdmin, auditor }

extension AdminPermissions on AdminRole {
  /// Decide verification and moderation items (non-developer). Auditors are read-only.
  bool get canDecide => this != AdminRole.auditor;

  /// Give the second approval a developer application needs.
  bool get canSecondApprove =>
      this == AdminRole.seniorReviewer || this == AdminRole.superAdmin;

  /// Create, edit, pause and order ad banners.
  bool get canManageAds =>
      this == AdminRole.seniorReviewer || this == AdminRole.superAdmin;

  /// Approve or reject ad banners that wait for review.
  bool get canReviewAds =>
      this == AdminRole.seniorReviewer || this == AdminRole.superAdmin;
}

class AdminSession {
  final String id, name;
  final AdminRole role;
  const AdminSession({
    required this.id,
    required this.name,
    required this.role,
  });
}

/// Login, then the one-time code, then the console. Nothing protected is reachable before [active].
enum AdminAuthStage { signedOut, needsTotp, active }

class AdminAuthState {
  final AdminAuthStage stage;
  final AdminSession? session;

  /// Why the person is back at the login screen (expired session, signed out elsewhere).
  final String? notice;
  const AdminAuthState(this.stage, {this.session, this.notice});
  static const signedOut = AdminAuthState(AdminAuthStage.signedOut);
}

class AdminAuthException implements Exception {
  const AdminAuthException();
}

class AdminTotpException implements Exception {
  const AdminTotpException();
}

class AdminSessionExpiredException implements Exception {
  const AdminSessionExpiredException();
}

/// The role may not do this; the service says no and the console shows it.
class AdminForbiddenException implements Exception {
  const AdminForbiddenException();
}

class AdminLockedException implements Exception {
  final String by;
  const AdminLockedException(this.by);
}

/// Four-eyes: the same person cannot give both approvals to a developer.
class AdminSameApproverException implements Exception {
  const AdminSameApproverException();
}

class AdminConflictException implements Exception {
  const AdminConflictException();
}

// ------------------------------------------------------------------ reason codes

/// The 12 documented reason codes. [other] needs a note.
enum ReasonCode {
  docUnreadable,
  docWrongType,
  nameMismatch,
  expired,
  notOnRegistry,
  licenceCategoryMismatch,
  ownerMismatch,
  duplicateListing,
  photosMismatch,
  callFailed,
  incompleteSubmission,
  other,
}

String reasonWire(ReasonCode c) => switch (c) {
  ReasonCode.docUnreadable => 'DOC_UNREADABLE',
  ReasonCode.docWrongType => 'DOC_WRONG_TYPE',
  ReasonCode.nameMismatch => 'NAME_MISMATCH',
  ReasonCode.expired => 'EXPIRED',
  ReasonCode.notOnRegistry => 'NOT_ON_REGISTRY',
  ReasonCode.licenceCategoryMismatch => 'LICENCE_CATEGORY_MISMATCH',
  ReasonCode.ownerMismatch => 'OWNER_MISMATCH',
  ReasonCode.duplicateListing => 'DUPLICATE_LISTING',
  ReasonCode.photosMismatch => 'PHOTOS_MISMATCH',
  ReasonCode.callFailed => 'CALL_FAILED',
  ReasonCode.incompleteSubmission => 'INCOMPLETE_SUBMISSION',
  ReasonCode.other => 'OTHER',
};

/// Reasons that make sense for an applicant, and for a listing. The full list stays the source of
/// truth; this only keeps each menu short.
const kApplicantReasons = [
  ReasonCode.docUnreadable,
  ReasonCode.docWrongType,
  ReasonCode.nameMismatch,
  ReasonCode.expired,
  ReasonCode.notOnRegistry,
  ReasonCode.licenceCategoryMismatch,
  ReasonCode.callFailed,
  ReasonCode.incompleteSubmission,
  ReasonCode.other,
];
const kListingReasons = [
  ReasonCode.docUnreadable,
  ReasonCode.docWrongType,
  ReasonCode.ownerMismatch,
  ReasonCode.duplicateListing,
  ReasonCode.photosMismatch,
  ReasonCode.incompleteSubmission,
  ReasonCode.other,
];

enum Decision { approve, requestResubmission, reject }

class DecisionRecord {
  final String byId, byName;
  final DateTime at;
  final Decision decision;
  final ReasonCode? reason;
  final String note;
  const DecisionRecord({
    required this.byId,
    required this.byName,
    required this.at,
    required this.decision,
    this.reason,
    this.note = '',
  });
}

class AdminDocument {
  final String id, label, fileName;

  /// False when the service cannot stream it (missing, expired or removed).
  final bool available;
  const AdminDocument({
    required this.id,
    required this.label,
    required this.fileName,
    this.available = true,
  });
}

// ------------------------------------------------------------------ verification queue

enum ApplicantKind {
  agent,
  developer,
  construction,
  architecture,
  interiorExterior,
}

/// Grant states the queue shows. awaitingSecondApproval is the developer four-eyes state.
enum QueueStatus {
  pending,
  awaitingSecondApproval,
  resubmissionRequired,
  approved,
  rejected,
}

class VerificationItem {
  final String id, applicantName;
  final ApplicantKind kind;
  final DateTime submittedAt;
  final QueueStatus status;

  /// A resubmission queues ahead of first-time applications.
  final bool isResubmission;
  final Map<String, String> details;
  final List<AdminDocument> documents;
  final List<DecisionRecord> history;

  /// Who is reviewing it now (30-minute lock), if anyone.
  final String? claimedById, claimedByName;
  final DateTime? claimExpiresAt;

  /// The first approver of a developer application.
  final String? firstApproverId;
  const VerificationItem({
    required this.id,
    required this.applicantName,
    required this.kind,
    required this.submittedAt,
    required this.status,
    this.isResubmission = false,
    this.details = const {},
    this.documents = const [],
    this.history = const [],
    this.claimedById,
    this.claimedByName,
    this.claimExpiresAt,
    this.firstApproverId,
  });

  bool get open =>
      status == QueueStatus.pending ||
      status == QueueStatus.awaitingSecondApproval;
  bool get isDeveloper => kind == ApplicantKind.developer;
  bool claimedByOther(String adminId, DateTime now) =>
      claimedById != null &&
      claimedById != adminId &&
      claimExpiresAt != null &&
      now.isBefore(claimExpiresAt!);

  VerificationItem copyWith({
    QueueStatus? status,
    List<DecisionRecord>? history,
    String? claimedById,
    String? claimedByName,
    DateTime? claimExpiresAt,
    bool clearClaim = false,
    String? firstApproverId,
  }) => VerificationItem(
    id: id,
    applicantName: applicantName,
    kind: kind,
    submittedAt: submittedAt,
    status: status ?? this.status,
    isResubmission: isResubmission,
    details: details,
    documents: documents,
    history: history ?? this.history,
    claimedById: clearClaim ? null : (claimedById ?? this.claimedById),
    claimedByName: clearClaim ? null : (claimedByName ?? this.claimedByName),
    claimExpiresAt: clearClaim ? null : (claimExpiresAt ?? this.claimExpiresAt),
    firstApproverId: firstApproverId ?? this.firstApproverId,
  );
}

/// Checks the reviewer ticks before approving (registry lookup, name match, call, duplicates).
const kApplicantChecklist = ['registry', 'name', 'call', 'duplicates'];

/// Order: resubmissions first, then oldest first.
int compareQueue(VerificationItem a, VerificationItem b) {
  if (a.isResubmission != b.isResubmission) return a.isResubmission ? -1 : 1;
  return a.submittedAt.compareTo(b.submittedAt);
}

// ------------------------------------------------------------------ listing moderation

enum ListingSource { agent, eBroker }

enum ModerationStatus { pending, resubmissionRequired, approved, rejected }

class ListingSubmission {
  final String id, title, description, ownerName, location;
  final PropertyType type;
  final ListingSource source;
  final DateTime submittedAt;
  final ModerationStatus status;
  final double? priceOmr, sizeSqm;
  final TransactionType transaction;
  final List<String> photos;
  final List<AdminDocument> documents;

  /// e-Broker only: whether the fee disclosure ("fees will apply up to 2%") was accepted. Null when
  /// the submission carries no such record.
  final bool? feeDisclosureAccepted;
  final List<DecisionRecord> history;
  final String? claimedById, claimedByName;
  final DateTime? claimExpiresAt;
  const ListingSubmission({
    required this.id,
    required this.title,
    this.description = '',
    required this.ownerName,
    this.location = '',
    required this.type,
    required this.source,
    required this.submittedAt,
    this.status = ModerationStatus.pending,
    this.priceOmr,
    this.sizeSqm,
    this.transaction = TransactionType.buy,
    this.photos = const [],
    this.documents = const [],
    this.feeDisclosureAccepted,
    this.history = const [],
    this.claimedById,
    this.claimedByName,
    this.claimExpiresAt,
  });

  PropertyMarket get market => marketOf(type);
  bool get open => status == ModerationStatus.pending;

  /// Mandatory information the submission lacks, so the reviewer sees it at a glance.
  List<String> get missing => [
    if (title.trim().isEmpty) 'title',
    if (description.trim().isEmpty) 'description',
    if (location.trim().isEmpty) 'location',
    if (sizeSqm == null || sizeSqm! <= 0) 'size',
    if (priceOmr == null || priceOmr! <= 0) 'price',
    if (photos.isEmpty) 'photos',
    if (documents.isEmpty) 'deed',
  ];

  bool claimedByOther(String adminId, DateTime now) =>
      claimedById != null &&
      claimedById != adminId &&
      claimExpiresAt != null &&
      now.isBefore(claimExpiresAt!);

  ListingSubmission copyWith({
    ModerationStatus? status,
    List<DecisionRecord>? history,
    String? claimedById,
    String? claimedByName,
    DateTime? claimExpiresAt,
    bool clearClaim = false,
  }) => ListingSubmission(
    id: id,
    title: title,
    description: description,
    ownerName: ownerName,
    location: location,
    type: type,
    source: source,
    submittedAt: submittedAt,
    status: status ?? this.status,
    priceOmr: priceOmr,
    sizeSqm: sizeSqm,
    transaction: transaction,
    photos: photos,
    documents: documents,
    feeDisclosureAccepted: feeDisclosureAccepted,
    history: history ?? this.history,
    claimedById: clearClaim ? null : (claimedById ?? this.claimedById),
    claimedByName: clearClaim ? null : (claimedByName ?? this.claimedByName),
    claimExpiresAt: clearClaim ? null : (claimExpiresAt ?? this.claimExpiresAt),
  );
}
