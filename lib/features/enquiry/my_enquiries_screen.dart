import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/states.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/app_state_providers.dart';

class MyEnquiriesScreen extends ConsumerStatefulWidget {
  const MyEnquiriesScreen({super.key});

  @override
  ConsumerState<MyEnquiriesScreen> createState() => _MyEnquiriesScreenState();
}

class _MyEnquiriesScreenState extends ConsumerState<MyEnquiriesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enquiries = ref.watch(enquiriesProvider);
    final offers = ref.watch(offersProvider);
    final bookings = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Enquiries'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate,
          indicatorColor: AppColors.primary,
          isScrollable: false,
          tabs: const [Tab(text: 'Enquiries'), Tab(text: 'Offers'), Tab(text: 'Viewings')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          enquiries.isEmpty
              ? const AqaratiEmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No enquiries yet',
                  message: 'Ask about a property to start a conversation with the owner.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: enquiries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final e = enquiries[enquiries.length - 1 - i];
                    return _RecordCard(
                      title: e.propertyTitle,
                      subtitle: e.message,
                      statusLabel: e.replied ? 'Replied' : 'Pending',
                      statusColor: e.replied ? AppColors.verified : AppColors.pending,
                    );
                  },
                ),
          offers.isEmpty
              ? const AqaratiEmptyState(
                  icon: Icons.local_offer_outlined,
                  title: 'No offers yet',
                  message: 'Make an offer on a property to track its status here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: offers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final o = offers[offers.length - 1 - i];
                    return _RecordCard(
                      title: o.propertyTitle,
                      subtitle: 'Your offer: ${o.offerPrice.formatted}',
                      statusLabel: _offerStatusLabel(o.status),
                      statusColor: _offerStatusColor(o.status),
                    );
                  },
                ),
          bookings.isEmpty
              ? const AqaratiEmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'No viewings scheduled',
                  message: 'Book a viewing on a property to see it here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: bookings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final b = bookings[bookings.length - 1 - i];
                    return _RecordCard(
                      title: b.contextTitle,
                      subtitle: '${b.date.day}/${b.date.month}/${b.date.year} · ${b.timeSlotLabel}',
                      statusLabel: 'Confirmed',
                      statusColor: AppColors.verified,
                    );
                  },
                ),
        ],
      ),
    );
  }

  String _offerStatusLabel(QuoteStatus s) {
    switch (s) {
      case QuoteStatus.pending:
        return 'Pending';
      case QuoteStatus.accepted:
        return 'Accepted';
      case QuoteStatus.changesRequested:
        return 'Counter offer';
      case QuoteStatus.declined:
        return 'Not accepted';
      case QuoteStatus.expired:
        return 'Expired';
    }
  }

  Color _offerStatusColor(QuoteStatus s) {
    switch (s) {
      case QuoteStatus.pending:
        return AppColors.pending;
      case QuoteStatus.accepted:
        return AppColors.verified;
      case QuoteStatus.changesRequested:
        return AppColors.sand700;
      case QuoteStatus.declined:
      case QuoteStatus.expired:
        return AppColors.error;
    }
  }
}

class _RecordCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusColor;

  const _RecordCard({
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(statusLabel, style: theme.textTheme.labelSmall?.copyWith(color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
