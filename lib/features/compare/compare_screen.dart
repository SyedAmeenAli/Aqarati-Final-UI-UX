import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/verification_badge.dart';
import '../../data/models/enums.dart';
import '../../data/models/property.dart';
import '../../data/repositories/providers.dart';

class CompareScreen extends ConsumerWidget {
  final List<String> propertyIds;

  const CompareScreen({super.key, required this.propertyIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyRepo = ref.watch(propertyRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Compare Properties')),
      body: FutureBuilder<List<Property>>(
        future: propertyRepo.search(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AqaratiLoadingLine(label: 'Loading comparison...');
          }
          final properties = propertyIds
              .map((id) => snapshot.data!.where((p) => p.id == id).firstOrNull)
              .whereType<Property>()
              .toList();
          if (properties.isEmpty) {
            return AqaratiEmptyState(
              icon: Icons.compare_arrows_rounded,
              title: 'Nothing to compare',
              message: 'Select properties from Saved to compare them here.',
            );
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: properties.map((p) => _CompareColumn(property: p)).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _CompareColumn extends StatelessWidget {
  final Property property;

  const _CompareColumn({required this.property});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: const Icon(Icons.landscape_outlined, color: AppColors.mist),
          ),
          const SizedBox(height: AppSpacing.md),
          VerificationBadge(status: property.verification.status),
          const SizedBox(height: AppSpacing.sm),
          Text(property.priceLabel, style: theme.textTheme.titleLarge?.copyWith(color: AppColors.primary)),
          Text(property.title, style: theme.textTheme.titleSmall),
          Text(property.locationLabel, style: theme.textTheme.bodySmall),
          const Divider(height: AppSpacing.xxl),
          _Row('Type', property.type.label),
          _Row('Bedrooms', '${property.bedrooms ?? '-'}'),
          _Row('Bathrooms', '${property.bathrooms ?? '-'}'),
          _Row('Area', '${property.areaSqm.toInt()} m²'),
          _Row('Parking', '${property.parkingSpaces ?? '-'}'),
          _Row('Transaction', property.transactionType.label),
          const Divider(height: AppSpacing.xxl),
          Text('Amenities', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: property.amenities.isEmpty
                ? [Text('None listed', style: theme.textTheme.bodySmall)]
                : property.amenities.map((a) => Chip(label: Text(a, style: theme.textTheme.labelSmall))).toList(),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
