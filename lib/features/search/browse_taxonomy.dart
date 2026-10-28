import '../../data/models/enums.dart';
import 'aq_filters.dart';

/// The property types offered at the type step of Buy and Rent, per category, in display order.
/// Each entry is the existing property type that carries the client's wording:
/// Shops = shop, Offices = office, Building = commercialBuilding, Storage = warehouse,
/// Factory = industrial, Farmhouse = farm.
const Map<PropCategory, List<(PropertyType, String)>> kBrowseTypes = {
  PropCategory.residential: [
    (
      PropertyType.villa,
      'assets/properties/p4/02_Contemporary_villa_at_sunset.jpg',
    ),
    (
      PropertyType.apartment,
      'assets/properties/p2/02_Apartment_buildings_in_Muscat.jpg',
    ),
    (
      PropertyType.residentialLand,
      'assets/properties/p3/01_Aerial_view_of_residential_plot.jpg',
    ),
  ],
  PropCategory.commercial: [
    (
      PropertyType.shop,
      'assets/properties/p6/01_Commercial_strip_architectural_p.jpg',
    ),
    (
      PropertyType.office,
      'assets/properties/p6/03_Empty_retail_interior_floor_plan.jpg',
    ),
    (
      PropertyType.commercialBuilding,
      'assets/properties/p6/04_Modern_commercial_building_exterior.jpg',
    ),
    (
      PropertyType.warehouse,
      'assets/properties/p6/05_Rear_utility_area_of_shop.jpg',
    ),
    (
      PropertyType.commercialLand,
      'assets/properties/p3/02_Elevated_view_of_vacant_plot.jpg',
    ),
  ],
  PropCategory.industrial: [
    (
      PropertyType.investmentLand,
      'assets/properties/p3/03_Street_frontage_of_residential_plot.jpg',
    ),
    (
      PropertyType.industrial,
      'assets/location/15_Sohar_coastal_landscape_development.jpg',
    ),
  ],
  PropCategory.agriculture: [
    (
      PropertyType.agriculturalLand,
      'assets/properties/p3/05_Vacant_plot_facing_distant_hills.jpg',
    ),
    (
      PropertyType.farm,
      'assets/properties/p4/07_Family_garden_view_at_villa.jpg',
    ),
  ],
};

/// Property types that cannot be rented. Source: the earlier prototype's explicit rental
/// configuration: Residential Land and Commercial Land are sale only; Land to invest and
/// Agricultural Land have rental ranges, so they can be rented; every other type has a supported
/// rent configuration. The architecture documents do not restate this, so it is still to be
/// confirmed against any newer product rule (see FINAL_GAP_AUDIT.md). This one list is the only
/// place the rule lives, and a missing data flag on a listing never decides it.
const Set<PropertyType> kSaleOnlyTypes = {
  PropertyType.residentialLand,
  PropertyType.commercialLand,
};

bool isRentable(PropertyType t) => !kSaleOnlyTypes.contains(t);

/// The types to offer for a category and transaction.
List<(PropertyType, String)> browseTypesFor(
  PropCategory cat,
  TransactionType tx,
) => [
  for (final e in kBrowseTypes[cat]!)
    if (tx != TransactionType.rent || isRentable(e.$1)) e,
];
