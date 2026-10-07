/// "My Home" — long-term personal workspace for an owned/rented property.
class Home {
  final String id;
  final String propertyId;
  final String label; // e.g. "Al Khoudh Villa"
  final DateTime addedAt;

  const Home({
    required this.id,
    required this.propertyId,
    required this.label,
    required this.addedAt,
  });
}
