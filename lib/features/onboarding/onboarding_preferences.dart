import '../../data/models/enums.dart';

enum BudgetBucket { under50k, from50to150k, from150to300k, custom }

/// Local-only draft of onboarding answers. Persisted nowhere yet — wire to
/// a real preferences repository once the backend exists.
class OnboardingPreferences {
  TransactionType? transactionType;
  final Set<PropertyType> propertyTypes = {};
  final Set<BusinessCategory> services = {};
  final Set<String> locations = {};
  BudgetBucket? budget;
  int? bedrooms; // null = "Any"

  bool get hasAnyAnswer =>
      transactionType != null ||
      propertyTypes.isNotEmpty ||
      services.isNotEmpty ||
      locations.isNotEmpty ||
      budget != null;
}

const List<String> omanPopularLocations = [
  'Muscat',
  'Seeb',
  'Bawshar',
  'Qurum',
  'Al Mouj',
  'Sohar',
  'Salalah',
  'Nizwa',
];

const List<PropertyType> onboardingPropertyTypes = [
  PropertyType.villa,
  PropertyType.apartment,
  PropertyType.townhouse,
  PropertyType.residentialLand,
  PropertyType.penthouse,
  PropertyType.commercialBuilding,
];

extension BudgetBucketLabel on BudgetBucket {
  String get label {
    switch (this) {
      case BudgetBucket.under50k:
        return 'Under OMR 50,000';
      case BudgetBucket.from50to150k:
        return 'OMR 50,000 - 150,000';
      case BudgetBucket.from150to300k:
        return 'OMR 150,000 - 300,000+';
      case BudgetBucket.custom:
        return 'Custom';
    }
  }
}
