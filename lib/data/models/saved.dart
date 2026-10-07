class SavedItem {
  final String id;
  final String propertyId;
  final DateTime savedAt;

  const SavedItem({
    required this.id,
    required this.propertyId,
    required this.savedAt,
  });
}

class SavedSearch {
  final String id;
  final String label; // e.g. "Villa in Al Mouj"
  final Map<String, String> filters;
  final DateTime createdAt;

  const SavedSearch({
    required this.id,
    required this.label,
    this.filters = const {},
    required this.createdAt,
  });
}
