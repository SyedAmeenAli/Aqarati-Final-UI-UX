import '../datasources/mock_business_data.dart';
import '../models/business.dart';

abstract class BusinessRepository {
  Future<List<Business>> getAll();
  Future<Business?> getById(String id);
}

class MockBusinessRepository implements BusinessRepository {
  @override
  Future<List<Business>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return mockBusinesses;
  }

  @override
  Future<Business?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      return mockBusinesses.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
