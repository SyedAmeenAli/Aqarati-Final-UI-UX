import '../../features/entry/models/signup_purpose.dart';

/// Customer account state (distinct from business role-grant verification).
enum AccountState { otpPending, active }

/// Role-grant lifecycle. `approved` IS the active approved state; there is no
/// separate "active business" state.
enum GrantState { draft, pendingVerification, approved, resubmissionRequired, rejected, suspended }

/// Developer approval is four-eyes: first approval leads to a distinct
/// "awaiting second approval" state; do not collapse it into generic pending.
enum ReviewStage { underReview, awaitingSecondApproval }

enum DocumentKind {
  photoId,
  agentLicence,
  supportingDocument,
  crCertificate,
  municipalLicence,
  officialCorporateRegistration,
  activityLicences,
  developerLicence;

  /// Expiry is tracked for these (source: agent licence; CR; developer licence).
  bool get tracksExpiry => this == agentLicence || this == crCertificate || this == developerLicence || this == officialCorporateRegistration;
}

enum InteriorExteriorServiceType { interior, exterior, both }

/// Typed description of one public sign-up path: which business fields it
/// collects and which documents it later requires. One config, one form.
class RoleFormConfig {
  final SignupPurpose purpose;
  final bool hasBusinessName;
  final bool hasAgencyName;
  final bool hasServiceType;
  final List<DocumentKind> documents;
  final bool fourEyes;
  const RoleFormConfig({
    required this.purpose,
    this.hasBusinessName = false,
    this.hasAgencyName = false,
    this.hasServiceType = false,
    this.documents = const [],
    this.fourEyes = false,
  });

  bool get needsDocuments => documents.isNotEmpty;
  bool get hasBusinessStep => hasBusinessName || hasAgencyName || hasServiceType;
}

const roleConfigs = <SignupPurpose, RoleFormConfig>{
  SignupPurpose.userToShop: RoleFormConfig(purpose: SignupPurpose.userToShop),
  SignupPurpose.realEstateAgent: RoleFormConfig(
    purpose: SignupPurpose.realEstateAgent,
    hasAgencyName: true,
    documents: [DocumentKind.photoId, DocumentKind.agentLicence, DocumentKind.supportingDocument],
  ),
  // The CR activity list is checked during verification; a separate Activity
  // Licence is a pending product decision, so it is deliberately NOT required.
  SignupPurpose.constructionCompany: RoleFormConfig(
    purpose: SignupPurpose.constructionCompany,
    hasBusinessName: true,
    documents: [DocumentKind.crCertificate, DocumentKind.municipalLicence],
  ),
  SignupPurpose.propertyDevelopmentCompany: RoleFormConfig(
    purpose: SignupPurpose.propertyDevelopmentCompany,
    hasBusinessName: true,
    fourEyes: true,
    documents: [DocumentKind.officialCorporateRegistration, DocumentKind.crCertificate, DocumentKind.activityLicences, DocumentKind.developerLicence],
  ),
  SignupPurpose.buildingArchitecture: RoleFormConfig(
    purpose: SignupPurpose.buildingArchitecture,
    hasBusinessName: true,
    documents: [DocumentKind.crCertificate, DocumentKind.municipalLicence],
  ),
  SignupPurpose.interiorExteriorDesign: RoleFormConfig(
    purpose: SignupPurpose.interiorExteriorDesign,
    hasBusinessName: true,
    hasServiceType: true,
    documents: [DocumentKind.crCertificate, DocumentKind.municipalLicence],
  ),
};

/// Public form values. Passwords and documents are NEVER part of this object.
class SignupFormValues {
  final String firstName, lastName, phone, email, businessName, agencyName;
  final InteriorExteriorServiceType? serviceType;
  final bool consent;
  const SignupFormValues({this.firstName = '', this.lastName = '', this.phone = '', this.email = '', this.businessName = '', this.agencyName = '', this.serviceType, this.consent = false});

  SignupFormValues copyWith({String? firstName, String? lastName, String? phone, String? email, String? businessName, String? agencyName, InteriorExteriorServiceType? serviceType, bool? consent}) => SignupFormValues(
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        businessName: businessName ?? this.businessName,
        agencyName: agencyName ?? this.agencyName,
        serviceType: serviceType ?? this.serviceType,
        consent: consent ?? this.consent,
      );

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'businessName': businessName,
        'agencyName': agencyName,
        'serviceType': serviceType?.name,
        'consent': consent,
      };

  factory SignupFormValues.fromJson(Map<String, dynamic> j) => SignupFormValues(
        firstName: j['firstName'] as String? ?? '',
        lastName: j['lastName'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        email: j['email'] as String? ?? '',
        businessName: j['businessName'] as String? ?? '',
        agencyName: j['agencyName'] as String? ?? '',
        serviceType: InteriorExteriorServiceType.values.where((e) => e.name == j['serviceType']).firstOrNull,
        consent: j['consent'] as bool? ?? false,
      );
}

/// Resolved account/session (GET /me).
class MeSession {
  final AccountState account;
  final SignupPurpose? purpose;
  final GrantState? grant;
  final ReviewStage? stage;
  final String? phoneLast4;
  const MeSession({required this.account, this.purpose, this.grant, this.stage, this.phoneLast4});
}

enum DocumentOutcome { notSubmitted, pendingReview, accepted, rejected }

class DocumentStatus {
  final DocumentKind kind;
  final DocumentOutcome outcome;
  final DateTime? expiry;
  final String? rejectionReasonCode;
  /// Metadata only (never content): shown in review and details.
  final String? fileName;
  final int? sizeBytes;
  const DocumentStatus({required this.kind, required this.outcome, this.expiry, this.rejectionReasonCode, this.fileName, this.sizeBytes});
}

/// GET /me/verification.
class VerificationInfo {
  final SignupPurpose purpose;
  final GrantState grant;
  final ReviewStage? stage;
  final DateTime? submittedAt;
  final List<DocumentStatus> documents;
  final String? reasonCode;
  /// Application reference and company name: derived/demo until the API contract defines them.
  final String? reference;
  final String? businessName;
  final DateTime? decidedAt;
  const VerificationInfo({required this.purpose, required this.grant, this.stage, this.submittedAt, this.documents = const [], this.reasonCode, this.reference, this.businessName, this.decidedAt});
}

/// Expiry-aware status for CR / licence documents.
enum ExpiryStatus { none, valid, expiringSoon, expired }

ExpiryStatus expiryStatusOf(DateTime? expiry, {DateTime? now}) {
  if (expiry == null) return ExpiryStatus.none;
  final n = now ?? DateTime.now();
  if (expiry.isBefore(n)) return ExpiryStatus.expired;
  if (expiry.difference(n).inDays <= 30) return ExpiryStatus.expiringSoon;
  return ExpiryStatus.valid;
}
