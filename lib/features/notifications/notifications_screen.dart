import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/states.dart';
import '../../data/models/app_notification.dart';

final List<AppNotification> _mockNotifications = [
  AppNotification(
    id: 'n1',
    title: 'New property match',
    body: 'A new Villa in Al Mouj matches your saved search.',
    deepLink: NotificationDeepLink.searchResults,
    deepLinkTargetId: '',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  AppNotification(
    id: 'n2',
    title: 'Enquiry sent',
    body: 'Your enquiry about 4-Bedroom Villa in Al Mouj was sent.',
    deepLink: NotificationDeepLink.conversation,
    deepLinkTargetId: '',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    read: true,
  ),
  AppNotification(
    id: 'n3',
    title: 'Viewing confirmed',
    body: 'Your viewing for Sea-View Apartment in Qurum is confirmed.',
    deepLink: NotificationDeepLink.booking,
    deepLinkTargetId: '',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    read: true,
  ),
];

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: _mockNotifications.isEmpty
          ? const AqaratiEmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications yet',
              message: "We'll let you know when something needs your attention.",
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _mockNotifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final n = _mockNotifications[i];
                return InkWell(
                  onTap: () => _handleTap(context, n),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: n.read ? AppColors.surface : AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_iconFor(n.deepLink), color: AppColors.primary),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(n.title, style: Theme.of(context).textTheme.titleSmall),
                              const SizedBox(height: 2),
                              Text(n.body, style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFor(NotificationDeepLink link) {
    switch (link) {
      case NotificationDeepLink.searchResults:
        return Icons.search_rounded;
      case NotificationDeepLink.conversation:
        return Icons.forum_outlined;
      case NotificationDeepLink.quote:
        return Icons.request_quote_outlined;
      case NotificationDeepLink.booking:
        return Icons.event_available_outlined;
      case NotificationDeepLink.receipt:
        return Icons.receipt_long_outlined;
      case NotificationDeepLink.verification:
        return Icons.verified_outlined;
    }
  }

  void _handleTap(BuildContext context, AppNotification n) {
    switch (n.deepLink) {
      case NotificationDeepLink.searchResults:
        context.push('/search');
      case NotificationDeepLink.conversation:
        context.push('/messages');
      case NotificationDeepLink.booking:
      case NotificationDeepLink.quote:
      case NotificationDeepLink.receipt:
      case NotificationDeepLink.verification:
        break;
    }
  }
}
