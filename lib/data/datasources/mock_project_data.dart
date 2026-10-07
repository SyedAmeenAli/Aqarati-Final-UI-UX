import '../models/money.dart';
import '../models/project.dart';

/// Fictional demo development projects — distinct object from Property.
/// Kept coherent with the existing business roster (developerBusinessId
/// must resolve against mockBusinesses, never an invented one-off name).
final List<DevelopmentProject> mockProjects = [
  const DevelopmentProject(
    id: 'proj1',
    name: 'Al Mouj Residences',
    developerBusinessId: 'b2',
    locationLabel: 'Al Mouj, Muscat',
    startingPrice: Money(145000),
    totalUnits: 48,
    availableUnits: 12,
    galleryUrls: ['assets/properties/p1/07_Waterfront_villa_with_infinity_pool.jpg'],
    description: 'A waterfront residential development of villas and townhouses '
        'along the Al Mouj marina.',
  ),
];
