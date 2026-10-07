import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';
import '../../core/widgets/states.dart';
import '../../data/models/home.dart';
import 'documents_screen.dart';

final myHomesProvider = StateProvider<List<Home>>((ref) => []);

class MyHomeScreen extends ConsumerWidget {
  const MyHomeScreen({super.key});

  static const _sections = [
    (Icons.home_work_outlined, 'Property', 'Details, specs and ownership documents'),
    (Icons.description_outlined, 'Documents', 'Title deed, contracts and warranties'),
    (Icons.build_outlined, 'Maintenance', 'Requests, history and providers'),
    (Icons.receipt_long_outlined, 'Expenses', 'Track spending on your home'),
    (Icons.brush_outlined, 'Renovations', 'Plan and track improvement projects'),
    (Icons.payments_outlined, 'Payments', 'Rent, service fees and receipts'),
    (Icons.groups_outlined, 'Providers', 'Professionals you have worked with'),
    (Icons.verified_outlined, 'Warranty', 'Appliance and structural warranties'),
    (Icons.history_rounded, 'History', 'Everything that has happened here'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homes = ref.watch(myHomesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Home')),
      body: homes.isEmpty ? _buildEmpty(context, ref) : _buildHome(context, homes.first),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return AqaratiEmptyState(
      icon: Icons.house_outlined,
      title: 'Add your home',
      message: 'Keep your property information, documents and maintenance in one place.',
      ctaLabel: 'Add your home',
      onCta: () => ref.read(myHomesProvider.notifier).update((state) => [
            ...state,
            Home(
              id: 'home1',
              propertyId: 'p3',
              label: 'Al Khoudh Villa',
              addedAt: DateTime.now(),
            ),
          ]),
    );
  }

  Widget _buildHome(BuildContext context, Home home) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: const Icon(Icons.villa_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(home.label, style: theme.textTheme.titleLarge),
                    Text('Everything about your home, in one place.', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        ..._sections.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () => s.$2 == 'Documents'
                    ? Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const DocumentsScreen()),
                      )
                    : ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${s.$2} — coming soon')),
                      ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      Icon(s.$1, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.$2, style: theme.textTheme.titleSmall),
                            Text(s.$3, style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.mist),
                    ],
                  ),
                ),
              ),
            )),
        const SizedBox(height: AppSpacing.lg),
        AqaratiButton(
          label: 'Request maintenance',
          variant: AqaratiButtonVariant.secondary,
          fullWidth: true,
          onPressed: () {},
        ),
      ],
    );
  }
}
