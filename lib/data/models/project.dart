import 'money.dart';

/// A development project (property-development company object).
/// Distinct from an individual Property listing.
class DevelopmentProject {
  final String id;
  final String name;
  final String developerBusinessId;
  final String locationLabel;
  final Money startingPrice;
  final int totalUnits;
  final int availableUnits;
  final List<String> amenities;
  final List<String> galleryUrls;
  final String description;

  const DevelopmentProject({
    required this.id,
    required this.name,
    required this.developerBusinessId,
    required this.locationLabel,
    required this.startingPrice,
    required this.totalUnits,
    required this.availableUnits,
    this.amenities = const [],
    this.galleryUrls = const [],
    this.description = '',
  });
}
