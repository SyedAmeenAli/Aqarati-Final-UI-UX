import '../../core/domain/account_models.dart';
import '../../data/models/business.dart';
import '../../data/models/enums.dart';
import '../entry/models/signup_purpose.dart';

/// The four customer-facing categories of Development & Building. SOURCE-CONFIRMED.
enum ProType { developer, construction, architecture, interiorExterior }

extension ProTypeX on ProType {
  String get key => 'db.type.$name';
  String get icon => switch (this) {
    ProType.developer => 'development',
    ProType.construction => 'construction',
    ProType.architecture => 'architecture',
    ProType.interiorExterior => 'interior',
  };

  /// Sign-up path that grants this professional type.
  SignupPurpose get purpose => switch (this) {
    ProType.developer => SignupPurpose.propertyDevelopmentCompany,
    ProType.construction => SignupPurpose.constructionCompany,
    ProType.architecture => SignupPurpose.buildingArchitecture,
    ProType.interiorExterior => SignupPurpose.interiorExteriorDesign,
  };

  /// Only developers have the formal `projects` create/edit experience.
  bool get hasProjects => this == ProType.developer;
}

ProType? proTypeOfPurpose(SignupPurpose? p) => switch (p) {
  SignupPurpose.propertyDevelopmentCompany => ProType.developer,
  SignupPurpose.constructionCompany => ProType.construction,
  SignupPurpose.buildingArchitecture => ProType.architecture,
  SignupPurpose.interiorExteriorDesign => ProType.interiorExterior,
  _ => null,
};

ProType? proTypeOfName(String? n) =>
    ProType.values.where((t) => t.name == n).firstOrNull;

/// Project lifecycle as the server reports it. Unknown values are preserved in
/// [DbProject.rawStatus] and never coerced to "approved".
enum ProjectStatus {
  draft,
  underReview,
  approved,
  changesRequested,
  rejected,
  unknown,
}

ProjectStatus projectStatusFromServer(String? raw) => switch (raw) {
  'draft' => ProjectStatus.draft,
  'pending_verification' ||
  'under_review' ||
  'pending' => ProjectStatus.underReview,
  'approved' => ProjectStatus.approved,
  'resubmission_required' ||
  'changes_requested' => ProjectStatus.changesRequested,
  'rejected' => ProjectStatus.rejected,
  _ => ProjectStatus.unknown,
};

extension ProjectStatusX on ProjectStatus {
  String get key => 'db.ps.$name';
  String get explainKey => 'db.ps.$name.x';

  /// Editing and resubmission are offered only where the workflow allows it.
  bool get canEdit =>
      this == ProjectStatus.draft ||
      this == ProjectStatus.changesRequested ||
      this == ProjectStatus.approved;
  bool get canResubmit =>
      this == ProjectStatus.changesRequested || this == ProjectStatus.draft;
  bool get isPublic => this == ProjectStatus.approved;
}

/// A professional or company in the public directory (approved only).
class DbProfessional {
  final String id;
  final String name;
  final ProType type;
  final InteriorExteriorServiceType? serviceType;
  final String bio;
  final String locationLabel;
  final String governorate;
  final double? latitude, longitude;
  final String? logoUrl;
  final List<String> mediaUrls;
  final bool verified;

  /// Server-derived aggregates. Never computed on the client.
  final double? rating;
  final int? reviewCount;

  /// Contact fields exactly as the profile provides them (may be absent).
  final String? phone, whatsapp;

  const DbProfessional({
    required this.id,
    required this.name,
    required this.type,
    this.serviceType,
    this.bio = '',
    required this.locationLabel,
    this.governorate = 'Muscat',
    this.latitude,
    this.longitude,
    this.logoUrl,
    this.mediaUrls = const [],
    this.verified = true,
    this.rating,
    this.reviewCount,
    this.phone,
    this.whatsapp,
  });

  String? get cover => mediaUrls.isNotEmpty ? mediaUrls.first : logoUrl;

  /// Maps the shared business record into a directory entry. Brokers and maintenance
  /// providers are not part of Development & Building.
  static DbProfessional? fromBusiness(Business b) {
    final cats = b.categories;
    final ProType? t;
    if (cats.contains(BusinessCategory.propertyDevelopment)) {
      t = ProType.developer;
    } else if (cats.contains(BusinessCategory.construction)) {
      t = ProType.construction;
    } else if (cats.contains(BusinessCategory.architecture)) {
      t = ProType.architecture;
    } else if (cats.contains(BusinessCategory.interiorDesign) ||
        cats.contains(BusinessCategory.exteriorDesign)) {
      t = ProType.interiorExterior;
    } else {
      t = null;
    }
    if (t == null) return null;
    final inter = cats.contains(BusinessCategory.interiorDesign);
    final exter = cats.contains(BusinessCategory.exteriorDesign);
    return DbProfessional(
      id: b.id,
      name: b.name,
      type: t,
      serviceType: t != ProType.interiorExterior
          ? null
          : (inter && exter
                ? InteriorExteriorServiceType.both
                : (inter
                      ? InteriorExteriorServiceType.interior
                      : InteriorExteriorServiceType.exterior)),
      bio: b.description,
      locationLabel: b.locationLabel,
      logoUrl: b.logoUrl,
      mediaUrls: b.galleryUrls,
      verified: b.verification.isVerified,
      rating: b.rating,
      reviewCount: b.reviewCount,
    );
  }
}

/// A developer project as the contract defines it. SOURCE-CONFIRMED fields only;
/// description, cover, amenities, highlights and completion date are PROPOSED-EXTENSION
/// and deliberately not modelled.
class DbProject {
  final String id;
  final String orgId;
  final String name;
  final PropertyType propertyType;
  final int? bedrooms, bathrooms;

  /// Metric, as the contract names them (`land_sqm`, `area_sqm`).
  final double? landSqm, areaSqm;
  final String governorate, wilayat, area;
  final double? latitude, longitude;
  final ProjectStatus status;
  final String rawStatus;

  /// Reviewer text exactly as received.
  final String? reviewerFeedback;
  final DateTime updatedAt;

  /// Approved project media. Empty until the contract carries project media.
  final List<String> mediaUrls;

  const DbProject({
    required this.id,
    required this.orgId,
    required this.name,
    required this.propertyType,
    this.bedrooms,
    this.bathrooms,
    this.landSqm,
    this.areaSqm,
    required this.governorate,
    required this.wilayat,
    this.area = '',
    this.latitude,
    this.longitude,
    required this.status,
    required this.rawStatus,
    this.reviewerFeedback,
    required this.updatedAt,
    this.mediaUrls = const [],
  });

  String get locationLabel =>
      [if (area.isNotEmpty) area, wilayat, governorate].join(', ');

  DbProject copyWith({
    ProjectStatus? status,
    String? rawStatus,
    String? reviewerFeedback,
    bool clearFeedback = false,
    DateTime? updatedAt,
  }) => DbProject(
    id: id,
    orgId: orgId,
    name: name,
    propertyType: propertyType,
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    landSqm: landSqm,
    areaSqm: areaSqm,
    governorate: governorate,
    wilayat: wilayat,
    area: area,
    latitude: latitude,
    longitude: longitude,
    status: status ?? this.status,
    rawStatus: rawStatus ?? this.rawStatus,
    reviewerFeedback: clearFeedback
        ? null
        : (reviewerFeedback ?? this.reviewerFeedback),
    updatedAt: updatedAt ?? this.updatedAt,
    mediaUrls: mediaUrls,
  );

  ProjectDraft toDraft() => ProjectDraft(
    id: id,
    name: name,
    type: propertyType,
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    landSqm: landSqm,
    areaSqm: areaSqm,
    governorate: governorate,
    wilayat: wilayat,
    area: area,
    latitude: latitude,
    longitude: longitude,
  );
}

/// Property types a project can be. Land has no rooms or built-up area.
const projectTypes = [
  PropertyType.villa,
  PropertyType.apartment,
  PropertyType.townhouse,
  PropertyType.building,
  PropertyType.commercialBuilding,
  PropertyType.mixedUse,
  PropertyType.residentialLand,
  PropertyType.agriculturalLand,
];

bool typeHasRooms(PropertyType? t) =>
    t != null &&
    !const {
      PropertyType.residentialLand,
      PropertyType.agriculturalLand,
      PropertyType.commercialBuilding,
      PropertyType.mixedUse,
      PropertyType.building,
    }.contains(t);
bool typeIsLand(PropertyType? t) =>
    t == PropertyType.residentialLand || t == PropertyType.agriculturalLand;

/// The five wizard steps, in order.
enum ProjectStep { basic, details, media, location, review }

/// Form state for the create/edit wizard. Mutable on purpose: steps edit it in place and the
/// draft survives back-navigation. Only contract-supported fields live here.
class ProjectDraft {
  String? id;
  String name;
  PropertyType? type;
  int? bedrooms, bathrooms;
  double? landSqm, areaSqm;
  String? governorate, wilayat;
  String area;
  double? latitude, longitude;

  ProjectDraft({
    this.id,
    this.name = '',
    this.type,
    this.bedrooms,
    this.bathrooms,
    this.landSqm,
    this.areaSqm,
    this.governorate,
    this.wilayat,
    this.area = '',
    this.latitude,
    this.longitude,
  });

  /// Field-keyed error keys for one step. Empty means the step is valid.
  Map<String, String> validate(ProjectStep step) {
    final e = <String, String>{};
    switch (step) {
      case ProjectStep.basic:
        if (name.trim().length < 3) e['name'] = 'db.err.name';
        if (type == null) e['type'] = 'db.err.type';
      case ProjectStep.details:
        if (type == null) e['type'] = 'db.err.type';
        if (typeHasRooms(type)) {
          if (bedrooms == null) e['beds'] = 'db.err.beds';
          if (bathrooms == null) e['baths'] = 'db.err.baths';
        }
        if (typeIsLand(type)) {
          if ((landSqm ?? 0) <= 0) e['land'] = 'db.err.land';
        } else {
          if ((areaSqm ?? 0) <= 0) e['area'] = 'db.err.area';
        }
      case ProjectStep.media:
        break;
      case ProjectStep.location:
        if (governorate == null) e['gov'] = 'db.err.gov';
        if (wilayat == null) e['wil'] = 'db.err.wil';
        // Coordinates are optional but must be a complete pair inside Oman's bounds.
        if ((latitude == null) != (longitude == null)) {
          e['coords'] = 'db.err.coordsPair';
        } else if (latitude != null &&
            (latitude! < 16 ||
                latitude! > 27 ||
                longitude! < 51 ||
                longitude! > 60)) {
          e['coords'] = 'db.err.coordsRange';
        }
      case ProjectStep.review:
        break;
    }
    return e;
  }

  /// Every required field across the steps that carry data.
  Map<ProjectStep, Map<String, String>> validateAll() {
    final out = <ProjectStep, Map<String, String>>{};
    for (final s in const [
      ProjectStep.basic,
      ProjectStep.details,
      ProjectStep.location,
    ]) {
      final e = validate(s);
      if (e.isNotEmpty) out[s] = e;
    }
    return out;
  }

  /// Typed payload: only fields the project contract names.
  Map<String, Object?> toPayload() => {
    'name': name.trim(),
    'property_type': type?.name,
    if (typeHasRooms(type)) 'bedrooms': bedrooms,
    if (typeHasRooms(type)) 'bathrooms': bathrooms,
    if (typeIsLand(type)) 'land_sqm': landSqm else 'area_sqm': areaSqm,
    'governorate': governorate,
    'wilayat': wilayat,
    if (area.trim().isNotEmpty) 'area': area.trim(),
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}

/// A server-side validation failure, keyed by field, with the draft left intact.
class ProjectValidationException implements Exception {
  final Map<String, String> fields;
  const ProjectValidationException(this.fields);
}

/// The caller does not own this organisation's data.
class PermissionDeniedException implements Exception {
  const PermissionDeniedException();
}

enum ContactChannel { call, whatsapp }

/// A logged Call/WhatsApp tap. Not a conversation, not a customer enquiry.
class ContactEvent {
  final String id;
  final ContactChannel channel;
  final String targetLabel;
  final DateTime at;
  const ContactEvent({
    required this.id,
    required this.channel,
    required this.targetLabel,
    required this.at,
  });
}

/// A published review. Pending and removed reviews are never delivered to the client.
class DbReview {
  final String id;
  final int rating;
  final String body;
  final String author;
  final DateTime at;
  const DbReview({
    required this.id,
    required this.rating,
    required this.body,
    required this.author,
    required this.at,
  });
}

/// What the current API contract supports. Anything false is shown as unavailable, never faked.
class DbCapabilities {
  final bool projectMedia,
      projectAmenities,
      leadEvents,
      engagements,
      portfolio,
      reviewReplies,
      profileEdit;
  const DbCapabilities({
    this.projectMedia = false,
    this.projectAmenities = false,
    this.leadEvents = false,
    this.engagements = false,
    this.portfolio = false,
    this.reviewReplies = false,
    this.profileEdit = false,
  });
}

/// Editable supported profile fields.
class ProfileEdit {
  final String bio;
  final String? phone, whatsapp;
  final InteriorExteriorServiceType? serviceType;
  final String governorate;
  const ProfileEdit({
    required this.bio,
    this.phone,
    this.whatsapp,
    this.serviceType,
    required this.governorate,
  });
}

/// Result of a profile save: what the server says about visibility.
enum ProfileSaveState { live, awaitingReview }

/// Engagement awaiting confirmation. Fields come from the API when it exists.
enum EngagementState {
  awaitingMyConfirmation,
  awaitingClient,
  confirmedByBoth,
  expired,
}

class Engagement {
  final String id;
  final String clientLabel;
  final EngagementState state;
  final DateTime? confirmByDeadline;
  const Engagement({
    required this.id,
    required this.clientLabel,
    required this.state,
    this.confirmByDeadline,
  });
}

/// Oman Governorate → Wilayat taxonomy (official administrative divisions).
const omanGovernorates = <String, List<String>>{
  'Muscat': ['Muscat', 'Muttrah', 'Bawshar', 'As Seeb', 'Al Amrat', 'Qurayyat'],
  'Dhofar': [
    'Salalah',
    'Taqah',
    'Mirbat',
    'Sadah',
    'Rakhyut',
    'Dhalkut',
    'Muqshin',
    'Shalim and the Hallaniyat Islands',
    'Thumrait',
    'Al Mazyona',
  ],
  'Musandam': ['Khasab', 'Bukha', 'Dibba', 'Madha'],
  'Al Buraimi': ['Al Buraimi', 'Mahdah', 'As Sinainah'],
  'Ad Dakhiliyah': [
    'Nizwa',
    'Bahla',
    'Manah',
    'Al Hamra',
    'Adam',
    'Izki',
    'Samail',
    'Bidbid',
    'Jabal Akhdar',
  ],
  'Al Batinah North': [
    'Sohar',
    'Shinas',
    'Liwa',
    'Saham',
    'Al Khaburah',
    'As Suwayq',
  ],
  'Al Batinah South': [
    'Rustaq',
    'Al Awabi',
    'Nakhal',
    'Wadi Al Maawil',
    'Barka',
    'Al Musannah',
  ],
  'Ash Sharqiyah North': [
    'Ibra',
    'Al Mudhaibi',
    'Bidiyah',
    'Al Qabil',
    'Wadi Bani Khalid',
    'Dima Wa Attaiyyin',
    'Samad Ash Shan',
  ],
  'Ash Sharqiyah South': [
    'Sur',
    'Al Kamil Wal Wafi',
    'Jalan Bani Bu Ali',
    'Jalan Bani Bu Hassan',
    'Masirah',
  ],
  'Al Dhahirah': ['Ibri', 'Yanqul', 'Dhank'],
  'Al Wusta': ['Haima', 'Mahut', 'Duqm', 'Al Jazir'],
};

const omanGovernorateAr = <String, String>{
  'Muscat': 'مسقط',
  'Dhofar': 'ظفار',
  'Musandam': 'مسندم',
  'Al Buraimi': 'البريمي',
  'Ad Dakhiliyah': 'الداخلية',
  'Al Batinah North': 'شمال الباطنة',
  'Al Batinah South': 'جنوب الباطنة',
  'Ash Sharqiyah North': 'شمال الشرقية',
  'Ash Sharqiyah South': 'جنوب الشرقية',
  'Al Dhahirah': 'الظاهرة',
  'Al Wusta': 'الوسطى',
};

/// Approximate governorate centres, used only to centre a map when a record has no coordinates.
const omanGovernorateCentre = <String, (double, double)>{
  'Muscat': (23.5880, 58.3829),
  'Dhofar': (17.0151, 54.0924),
  'Musandam': (26.1990, 56.2460),
  'Al Buraimi': (24.2500, 55.7930),
  'Ad Dakhiliyah': (22.9333, 57.5333),
  'Al Batinah North': (24.3420, 56.7290),
  'Al Batinah South': (23.6990, 57.4290),
  'Ash Sharqiyah North': (22.5700, 58.5300),
  'Ash Sharqiyah South': (22.5667, 59.5289),
  'Al Dhahirah': (23.2250, 56.5160),
  'Al Wusta': (19.6600, 56.4800),
};
