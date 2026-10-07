import 'enums.dart';

class Service {
  final String id;
  final ServiceCategory category;
  final String providerBusinessId;
  final String title;
  final String description;
  final String? startingPriceLabel; // kept as label; real quotes come via Quote flow

  const Service({
    required this.id,
    required this.category,
    required this.providerBusinessId,
    required this.title,
    this.description = '',
    this.startingPriceLabel,
  });
}
