enum NotificationDeepLink {
  searchResults,
  conversation,
  quote,
  booking,
  receipt,
  verification,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationDeepLink deepLink;
  final String deepLinkTargetId;
  final DateTime createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.deepLink,
    required this.deepLinkTargetId,
    required this.createdAt,
    this.read = false,
  });
}
