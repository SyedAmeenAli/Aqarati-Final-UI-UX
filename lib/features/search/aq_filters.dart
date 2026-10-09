import '../../data/models/enums.dart';
import '../../data/models/property.dart';

/// The four browse groups used by Home, Explore and Properties.
enum PropCategory { residential, commercial, agriculture, industrial }

extension PropCategoryX on PropCategory {
  String get key => 'cat.$name';
  bool matches(PropertyType t) => switch (this) {
        PropCategory.residential => const {PropertyType.apartment, PropertyType.villa, PropertyType.house, PropertyType.townhouse, PropertyType.penthouse, PropertyType.building, PropertyType.residentialLand, PropertyType.chalet, PropertyType.guesthouse}.contains(t),
        PropCategory.commercial => const {PropertyType.office, PropertyType.shop, PropertyType.showroom, PropertyType.commercialBuilding, PropertyType.hotel, PropertyType.resort, PropertyType.mixedUse}.contains(t),
        PropCategory.agriculture => const {PropertyType.agriculturalLand, PropertyType.farm}.contains(t),
        PropCategory.industrial => const {PropertyType.industrial, PropertyType.warehouse}.contains(t),
      };
  String get image => switch (this) {
        PropCategory.residential => 'assets/properties/p1/08_Contemporary_villa_front_facade_.jpg',
        PropCategory.commercial => 'assets/properties/p6/04_Modern_commercial_building_exterior.jpg',
        PropCategory.agriculture => 'assets/properties/p3/05_Vacant_plot_facing_distant_hills.jpg',
        PropCategory.industrial => 'assets/properties/p6/05_Rear_utility_area_of_shop.jpg',
      };
}

enum AQSort { recommended, priceLow, priceHigh, largest }

/// Property types offered as chips in the filter sheet.
const aqFilterTypes = [
  PropertyType.villa,
  PropertyType.apartment,
  PropertyType.townhouse,
  PropertyType.residentialLand,
  PropertyType.agriculturalLand,
  PropertyType.farm,
  PropertyType.office,
  PropertyType.shop,
  PropertyType.warehouse,
];

const _stop = {'in', 'for', 'near', 'me', 'the', 'and', 'a', 'at', 'of'};

/// Everything a property list can be narrowed by. Mutable so the sheet can edit a copy
/// and hand it back only when the person confirms.
class AQFilters {
  TransactionType? tx;
  PropCategory? category;
  final Set<PropertyType> types;
  final Set<String> areas;
  final Set<String> amenities;
  double? minPrice, maxPrice;
  int? beds, baths, minArea;
  bool verifiedOnly;
  AQSort sort;

  AQFilters({this.tx, this.category, Set<PropertyType>? types, Set<String>? areas, Set<String>? amenities, this.minPrice, this.maxPrice, this.beds, this.baths, this.minArea, this.verifiedOnly = false, this.sort = AQSort.recommended})
      : types = types ?? {},
        areas = areas ?? {},
        amenities = amenities ?? {};

  AQFilters copy() => AQFilters(tx: tx, category: category, types: {...types}, areas: {...areas}, amenities: {...amenities}, minPrice: minPrice, maxPrice: maxPrice, beds: beds, baths: baths, minArea: minArea, verifiedOnly: verifiedOnly, sort: sort);

  /// Clears every narrowing choice; keeps the sort order.
  void reset() {
    tx = null;
    category = null;
    types.clear();
    areas.clear();
    amenities.clear();
    minPrice = maxPrice = null;
    beds = baths = minArea = null;
    verifiedOnly = false;
  }

  /// Groups in use, shown as the badge on the Filters button. Purpose and category are
  /// visible on screen already, so they are not counted.
  int get activeCount =>
      (types.isNotEmpty || category != null ? 1 : 0) +
      (areas.isNotEmpty ? 1 : 0) +
      (amenities.isNotEmpty ? 1 : 0) +
      (minPrice != null || maxPrice != null ? 1 : 0) +
      (beds != null ? 1 : 0) +
      (baths != null ? 1 : 0) +
      (minArea != null ? 1 : 0) +
      (verifiedOnly ? 1 : 0);

  static bool _matchesQuery(Property p, String query) {
    final words = query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty && !_stop.contains(w));
    if (words.isEmpty) return true;
    final tx = switch (p.transactionType) { TransactionType.buy => 'buy sale sell', TransactionType.rent => 'rent rental', TransactionType.lease => 'lease' };
    final hay = '${p.title} ${p.locationLabel} ${p.type.label} ${p.amenities.join(' ')} $tx'.toLowerCase();
    return words.every((w) => hay.contains(w) || (w.length > 3 && w.endsWith('s') && hay.contains(w.substring(0, w.length - 1))));
  }

  bool matches(Property p, {String query = ''}) =>
      (tx == null || p.transactionType == tx) &&
      (category == null || category!.matches(p.type)) &&
      (types.isEmpty || types.contains(p.type)) &&
      (areas.isEmpty || areas.contains(p.area)) &&
      (minPrice == null || p.price.amount >= minPrice!) &&
      (maxPrice == null || p.price.amount <= maxPrice!) &&
      (beds == null || (p.bedrooms ?? 0) >= beds!) &&
      (baths == null || (p.bathrooms ?? 0) >= baths!) &&
      (minArea == null || p.areaSqm >= minArea!) &&
      (amenities.isEmpty || amenities.every(p.amenities.contains)) &&
      (!verifiedOnly || p.verification.isVerified) &&
      _matchesQuery(p, query);

  List<Property> apply(List<Property> all, {String query = ''}) {
    final out = all.where((p) => matches(p, query: query)).toList();
    switch (sort) {
      case AQSort.priceLow:
        out.sort((a, b) => a.price.amount.compareTo(b.price.amount));
      case AQSort.priceHigh:
        out.sort((a, b) => b.price.amount.compareTo(a.price.amount));
      case AQSort.largest:
        out.sort((a, b) => b.areaSqm.compareTo(a.areaSqm));
      case AQSort.recommended:
        break;
    }
    return out;
  }
}

/// Price extent of the listings for a purpose (rent and sale live on very different scales).
(double min, double max) aqPriceBounds(List<Property> all, TransactionType? tx) {
  final prices = [for (final p in all) if (tx == null || p.transactionType == tx) p.price.amount];
  if (prices.isEmpty) return (0, 1);
  prices.sort();
  final lo = prices.first.floorToDouble();
  final hi = prices.last.ceilToDouble();
  return (lo, hi <= lo ? lo + 1 : hi);
}
