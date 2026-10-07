import '../datasources/mock_property_data.dart';
import '../models/property.dart';

abstract class PropertyRepository {
  Future<List<Property>> getFeatured();
  Future<List<Property>> search({String? query, String? area});
  Future<Property?> getById(String id);
}

/// Mock repository backed by seeded demo data.
/// Replace with an API-backed implementation once the real backend exists —
/// callers only depend on [PropertyRepository].
class MockPropertyRepository implements PropertyRepository {
  @override
  Future<List<Property>> getFeatured() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockProperties.where((p) => p.verification.isVerified).toList();
  }

  @override
  Future<List<Property>> search({String? query, String? area}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return mockProperties.where((p) {
      final matchesQuery = query == null ||
          query.isEmpty ||
          p.title.toLowerCase().contains(query.toLowerCase()) ||
          p.locationLabel.toLowerCase().contains(query.toLowerCase());
      final matchesArea = area == null || area.isEmpty || p.area == area;
      return matchesQuery && matchesArea;
    }).toList();
  }

  @override
  Future<Property?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return mockProperties.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
