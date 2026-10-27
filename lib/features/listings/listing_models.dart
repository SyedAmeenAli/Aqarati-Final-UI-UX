import '../../data/models/enums.dart';

/// Agent listing lifecycle. The first block is the documented item state machine (architecture v2.6
/// section 6: draft, pending_verification, approved, resubmission_required, rejected, hidden) plus the
/// documented expiry (90 days) and the status endpoint (sold, rented, withdrawn). [paused] is a
/// client-confirmed addition that the service contract does not list yet: see the source-gap doc.
enum ListingStatus {
  draft,
  pendingVerification,
  approved,
  resubmissionRequired,
  rejected,
  hidden,
  expired,
  paused,
  withdrawn,
  sold,
  rented,
}

/// Property markets from the product taxonomy.
enum PropertyMarket { residential, commercial, agriculture, industrial }

/// Which property types belong to each market (front-end grouping of the existing taxonomy).
const Map<PropertyMarket, List<PropertyType>> kMarketTypes = {
  PropertyMarket.residential: [
    PropertyType.apartment,
    PropertyType.villa,
    PropertyType.house,
    PropertyType.townhouse,
    PropertyType.penthouse,
    PropertyType.building,
    PropertyType.residentialLand,
  ],
  PropertyMarket.commercial: [
    PropertyType.office,
    PropertyType.shop,
    PropertyType.showroom,
    PropertyType.commercialBuilding,
    PropertyType.hotel,
    PropertyType.resort,
    PropertyType.chalet,
    PropertyType.guesthouse,
    PropertyType.mixedUse,
    PropertyType.commercialLand,
  ],
  PropertyMarket.agriculture: [
    PropertyType.agriculturalLand,
    PropertyType.farm,
  ],
  PropertyMarket.industrial: [
    PropertyType.warehouse,
    PropertyType.industrial,
    PropertyType.investmentLand,
  ],
};

PropertyMarket marketOf(PropertyType t) =>
    kMarketTypes.entries.firstWhere((e) => e.value.contains(t)).key;

/// Which factual fields apply to a property type. The service's attribute matrix (architecture
/// section 27.5) is not in the repository, so this is a front-end default: land and farms have no
/// rooms, and only buildings with rooms ask for them.
class ListingAttributes {
  final bool bedrooms, bathrooms, parking;
  const ListingAttributes({
    this.bedrooms = false,
    this.bathrooms = false,
    this.parking = false,
  });
}

ListingAttributes attributesFor(PropertyType t) {
  switch (t) {
    case PropertyType.apartment:
    case PropertyType.villa:
    case PropertyType.house:
    case PropertyType.townhouse:
    case PropertyType.penthouse:
    case PropertyType.chalet:
      return const ListingAttributes(
        bedrooms: true,
        bathrooms: true,
        parking: true,
      );
    case PropertyType.guesthouse:
    case PropertyType.hotel:
    case PropertyType.resort:
      return const ListingAttributes(bedrooms: true, bathrooms: true);
    case PropertyType.building:
    case PropertyType.office:
    case PropertyType.commercialBuilding:
    case PropertyType.mixedUse:
      return const ListingAttributes(parking: true);
    case PropertyType.shop:
    case PropertyType.showroom:
      return const ListingAttributes(bathrooms: true);
    case PropertyType.residentialLand:
    case PropertyType.agriculturalLand:
    case PropertyType.farm:
    case PropertyType.warehouse:
    case PropertyType.industrial:
    case PropertyType.commercialLand:
    case PropertyType.investmentLand:
      return const ListingAttributes();
  }
}

/// A photo that is already stored, or one picked on this device and not yet uploaded.
class ListingPhoto {
  final String id;
  final String name;

  /// Bytes of a picked photo (demo storage and previews only).
  final List<int>? bytes;
  const ListingPhoto({required this.id, required this.name, this.bytes});
}

class AgentListing {
  final String id;
  final String ownerId;
  final String? agencyId;
  final String title, description;
  final PropertyType type;
  final TransactionType transaction;
  final double priceOmr;
  final String governorate, wilayat, area;
  final double sizeSqm;
  final int? bedrooms, bathrooms, parking;

  /// Title-deed number as the owner typed it (the service normalises and hashes it).
  final String titleDeed;
  final List<ListingPhoto> photos;
  final ListingStatus status;
  final DateTime createdAt, updatedAt;

  /// Reviewer feedback for resubmission_required / rejected, when the service returns it.
  final String? feedback;

  /// An edit to a live listing is reviewed as a change set while the approved version stays live
  /// (architecture glossary: change set). The exact rule for which edits count is not confirmed.
  final bool pendingChanges;
  const AgentListing({
    required this.id,
    required this.ownerId,
    this.agencyId,
    required this.title,
    required this.description,
    required this.type,
    required this.transaction,
    required this.priceOmr,
    required this.governorate,
    required this.wilayat,
    this.area = '',
    required this.sizeSqm,
    this.bedrooms,
    this.bathrooms,
    this.parking,
    required this.titleDeed,
    this.photos = const [],
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.feedback,
    this.pendingChanges = false,
  });

  PropertyMarket get market => marketOf(type);

  bool get canEdit => const {
    ListingStatus.draft,
    ListingStatus.approved,
    ListingStatus.paused,
    ListingStatus.resubmissionRequired,
  }.contains(status);
  bool get canPause => status == ListingStatus.approved;
  bool get canResume => status == ListingStatus.paused;
  bool get canRenew => status == ListingStatus.expired;
  bool get isLive => status == ListingStatus.approved;
  bool get inReview => status == ListingStatus.pendingVerification;

  String get locationLabel => [
    if (area.isNotEmpty) area,
    wilayat,
    governorate,
  ].where((s) => s.isNotEmpty).join(', ');

  AgentListing copyWith({
    ListingStatus? status,
    DateTime? updatedAt,
    String? feedback,
    bool? pendingChanges,
  }) => AgentListing(
    id: id,
    ownerId: ownerId,
    agencyId: agencyId,
    title: title,
    description: description,
    type: type,
    transaction: transaction,
    priceOmr: priceOmr,
    governorate: governorate,
    wilayat: wilayat,
    area: area,
    sizeSqm: sizeSqm,
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    parking: parking,
    titleDeed: titleDeed,
    photos: photos,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    feedback: feedback ?? this.feedback,
    pendingChanges: pendingChanges ?? this.pendingChanges,
  );
}

/// What the form submits (create or update).
class ListingInput {
  final String title, description;
  final PropertyType type;
  final TransactionType transaction;
  final double priceOmr;
  final String governorate, wilayat, area;
  final double sizeSqm;
  final int? bedrooms, bathrooms, parking;
  final String titleDeed;

  /// Existing photos the agent keeps (by id) and new ones picked on this device.
  final List<String> keepPhotoIds;
  final List<ListingPhoto> newPhotos;
  const ListingInput({
    required this.title,
    required this.description,
    required this.type,
    required this.transaction,
    required this.priceOmr,
    required this.governorate,
    required this.wilayat,
    this.area = '',
    required this.sizeSqm,
    this.bedrooms,
    this.bathrooms,
    this.parking,
    required this.titleDeed,
    this.keepPhotoIds = const [],
    this.newPhotos = const [],
  });
}

/// 409 DUPLICATE_LISTING: the same title deed and unit is already listed.
class DuplicateListingException implements Exception {
  const DuplicateListingException();
}

/// The photo upload failed; the listing record was not changed.
class ListingPhotoUploadException implements Exception {
  const ListingPhotoUploadException();
}

/// The action is not allowed for the listing's current status.
class ListingStatusConflictException implements Exception {
  const ListingStatusConflictException();
}

/// Title deed: letters and digits, 6 to 20 characters, after removing spaces and dashes.
String normaliseDeed(String raw) =>
    raw.replaceAll(RegExp(r'[\s\-]'), '').toUpperCase();
bool deedValid(String raw) =>
    RegExp(r'^[A-Z0-9]{6,20}$').hasMatch(normaliseDeed(raw));
