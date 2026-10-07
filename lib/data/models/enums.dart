/// Shared domain enums. Fixed vocab per AQARATI product spec — do not invent categories.
library;

enum PropertyType {
  apartment,
  villa,
  house,
  townhouse,
  penthouse,
  building,
  residentialLand,
  agriculturalLand,
  farm,
  office,
  shop,
  warehouse,
  showroom,
  commercialBuilding,
  hotel,
  resort,
  chalet,
  guesthouse,
  industrial,
  mixedUse,
}

enum TransactionType { buy, rent, lease }

enum VerificationStatus {
  unverified,
  submitted,
  underReview,
  needsAttention,
  verified,
}

enum BusinessCategory {
  realEstateAgent,
  construction,
  propertyDevelopment,
  architecture,
  interiorDesign,
  exteriorDesign,
  maintenance,
}

enum ServiceCategory {
  architecture,
  construction,
  interiorDesign,
  exteriorDesign,
  ac,
  plumbing,
  electrical,
  painting,
  cleaning,
  pestControl,
  landscaping,
  generalMaintenance,
}

enum BookingContext { propertyViewing, architecture, construction, interior, exterior, maintenance }

enum QuoteStatus { pending, accepted, changesRequested, declined, expired }

enum BookingStatus { pending, confirmed, completed, cancelled }

enum PaymentStatus { pending, processing, succeeded, failed }

extension PropertyTypeLabel on PropertyType {
  String get label {
    switch (this) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.house:
        return 'House';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.penthouse:
        return 'Penthouse';
      case PropertyType.building:
        return 'Building';
      case PropertyType.residentialLand:
        return 'Residential Land';
      case PropertyType.agriculturalLand:
        return 'Agricultural Land';
      case PropertyType.farm:
        return 'Farm';
      case PropertyType.office:
        return 'Office';
      case PropertyType.shop:
        return 'Shop';
      case PropertyType.warehouse:
        return 'Warehouse';
      case PropertyType.showroom:
        return 'Showroom';
      case PropertyType.commercialBuilding:
        return 'Commercial Building';
      case PropertyType.hotel:
        return 'Hotel';
      case PropertyType.resort:
        return 'Resort';
      case PropertyType.chalet:
        return 'Chalet';
      case PropertyType.guesthouse:
        return 'Guesthouse';
      case PropertyType.industrial:
        return 'Industrial';
      case PropertyType.mixedUse:
        return 'Mixed-use';
    }
  }
}

extension TransactionTypeLabel on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.buy:
        return 'Buy';
      case TransactionType.rent:
        return 'Rent';
      case TransactionType.lease:
        return 'Lease';
    }
  }

  /// e.g. "/ month" for rent — makes price period obvious.
  String? get pricePeriodSuffix {
    switch (this) {
      case TransactionType.rent:
        return '/ month';
      case TransactionType.lease:
        return '/ year';
      case TransactionType.buy:
        return null;
    }
  }

  /// Property Detail's transaction pill, e.g. "FOR SALE" (20.01-property-default).
  String get forSaleLabel {
    switch (this) {
      case TransactionType.buy:
        return 'FOR SALE';
      case TransactionType.rent:
        return 'FOR RENT';
      case TransactionType.lease:
        return 'FOR LEASE';
    }
  }
}

extension BusinessCategoryLabel on BusinessCategory {
  String get label {
    switch (this) {
      case BusinessCategory.realEstateAgent:
        return 'Real Estate Agent';
      case BusinessCategory.construction:
        return 'Construction';
      case BusinessCategory.propertyDevelopment:
        return 'Property Development';
      case BusinessCategory.architecture:
        return 'Architecture';
      case BusinessCategory.interiorDesign:
        return 'Interior Design';
      case BusinessCategory.exteriorDesign:
        return 'Exterior Design';
      case BusinessCategory.maintenance:
        return 'Maintenance';
    }
  }
}

extension ServiceCategoryLabel on ServiceCategory {
  String get label {
    switch (this) {
      case ServiceCategory.architecture:
        return 'Architecture';
      case ServiceCategory.construction:
        return 'Construction';
      case ServiceCategory.interiorDesign:
        return 'Interior Design';
      case ServiceCategory.exteriorDesign:
        return 'Exterior Design';
      case ServiceCategory.ac:
        return 'AC';
      case ServiceCategory.plumbing:
        return 'Plumbing';
      case ServiceCategory.electrical:
        return 'Electrical';
      case ServiceCategory.painting:
        return 'Painting';
      case ServiceCategory.cleaning:
        return 'Cleaning';
      case ServiceCategory.pestControl:
        return 'Pest Control';
      case ServiceCategory.landscaping:
        return 'Landscaping';
      case ServiceCategory.generalMaintenance:
        return 'General Maintenance';
    }
  }
}

extension VerificationStatusLabel on VerificationStatus {
  /// Human, non-robotic copy per AQARATI verification language rules.
  String get humanMessage {
    switch (this) {
      case VerificationStatus.unverified:
        return 'Not yet verified';
      case VerificationStatus.submitted:
        return "We've received your documents.";
      case VerificationStatus.underReview:
        return 'Our team is reviewing them.';
      case VerificationStatus.needsAttention:
        return 'One or more documents need your attention.';
      case VerificationStatus.verified:
        return 'Verified';
    }
  }
}
