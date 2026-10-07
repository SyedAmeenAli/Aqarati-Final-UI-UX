import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/verification_badge.dart';
import '../../data/repositories/app_state_providers.dart';
import '../verification/verification_center_screen.dart';
import 'owner_state.dart';
import 'property_creation_flow.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(ownerListingsProvider);
    final enquiries = ref.watch(enquiriesProvider);
    final bookings = ref.watch(bookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Properties'),
            Tab(text: 'Enquiries'),
            Tab(text: 'Viewings'),
            Tab(text: 'Verification'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PropertyCreationFlow()),
        ),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add property', style: TextStyle(color: Colors.white)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          listings.isEmpty
              ? const AqaratiEmptyState(
                  icon: Icons.home_work_outlined,
                  title: 'No properties listed yet',
                  message: 'Add your first property to start reaching buyers.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: listings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final p = listings[i];
                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.title, style: Theme.of(context).textTheme.titleSmall),
                                Text(p.priceLabel, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary)),
                              ],
                            ),
                          ),
                          VerificationBadge(status: p.verification.status),
                        ],
                      ),
                    );
                  },
                ),
          enquiries.isEmpty
              ? const AqaratiEmptyState(
                  icon: Icons.forum_outlined,
                  title: 'No enquiries yet',
                  message: 'Buyer enquiries about your listings will show up here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: enquiries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final e = enquiries[enquiries.length - 1 - i];
                    return _SimpleTile(title: e.propertyTitle, subtitle: e.message);
                  },
                ),
          bookings.isEmpty
              ? const AqaratiEmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'No viewings scheduled',
                  message: 'Confirmed viewings for your properties appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: bookings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final b = bookings[bookings.length - 1 - i];
                    return _SimpleTile(title: b.contextTitle, subtitle: '${b.date.day}/${b.date.month} · ${b.timeSlotLabel}');
                  },
                ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verify your identity and properties to build buyer trust.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const VerificationCenterScreen()),
                  ),
                  child: const Text('Open Verification Centre'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SimpleTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
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
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
