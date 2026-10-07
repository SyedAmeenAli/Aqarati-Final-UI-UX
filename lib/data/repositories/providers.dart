import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'business_repository.dart';
import 'property_repository.dart';

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return MockPropertyRepository();
});

final businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return MockBusinessRepository();
});

final featuredPropertiesProvider = FutureProvider((ref) {
  return ref.watch(propertyRepositoryProvider).getFeatured();
});

final businessesProvider = FutureProvider((ref) {
  return ref.watch(businessRepositoryProvider).getAll();
});
