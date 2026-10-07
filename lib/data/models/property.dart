import 'enums.dart';
import 'money.dart';
import 'property_verification.dart';

class Property {
  final String id;
  final String title;
  final String locationLabel; // e.g. "Al Mouj, Muscat, Oman"
  final String area; // e.g. "Muscat"
  final PropertyType type;
  final TransactionType transactionType;
  final Money price;
  final int? bedrooms;
  final int? bathrooms;
  final double areaSqm;
  final int? parkingSpaces;
  final PropertyVerification verification;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String listedByBusinessId;
  final List<String> amenities;
  final double? latitude;
  final double? longitude;
  final String description;

  const Property({
    required this.id,
    required this.title,
    required this.locationLabel,
    required this.area,
    required this.type,
    required this.transactionType,
    required this.price,
    this.bedrooms,
    this.bathrooms,
    required this.areaSqm,
    this.parkingSpaces,
    required this.verification,
    this.imageUrls = const [],
    this.videoUrls = const [],
    required this.listedByBusinessId,
    this.amenities = const [],
    this.latitude,
    this.longitude,
    this.description = '',
  });

  /// Full price string with period suffix when applicable, e.g. "OMR 950 / month".
  String get priceLabel {
    final suffix = transactionType.pricePeriodSuffix;
    return suffix == null ? price.formatted : '${price.formatted} $suffix';
  }
}
