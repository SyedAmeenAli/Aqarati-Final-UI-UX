import '../../data/models/enums.dart';

enum SortOption { recommended, newest, priceLowHigh, priceHighLow, largestArea, mostViewed }

extension SortOptionLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.recommended:
        return 'Recommended';
      case SortOption.newest:
        return 'Newest listings';
      case SortOption.priceLowHigh:
        return 'Price: low to high';
      case SortOption.priceHighLow:
        return 'Price: high to low';
      case SortOption.largestArea:
        return 'Largest area';
      case SortOption.mostViewed:
        return 'Most viewed';
    }
  }
}

class SearchFilters {
  TransactionType? transactionType;
  final Set<PropertyType> propertyTypes = {};
  int? minBedrooms;
  int? minBathrooms;
  bool verifiedOnly = false;
  SortOption sort = SortOption.recommended;

  int get activeCount =>
      (transactionType != null ? 1 : 0) +
      propertyTypes.length +
      (minBedrooms != null ? 1 : 0) +
      (minBathrooms != null ? 1 : 0) +
      (verifiedOnly ? 1 : 0);
}
