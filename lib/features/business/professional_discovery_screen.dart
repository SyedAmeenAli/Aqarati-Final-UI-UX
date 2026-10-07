import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_search_field.dart';
import '../../core/widgets/business_card.dart';
import '../../core/widgets/states.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/providers.dart';

class ProfessionalDiscoveryScreen extends ConsumerStatefulWidget {
  const ProfessionalDiscoveryScreen({super.key});

  @override
  ConsumerState<ProfessionalDiscoveryScreen> createState() => _ProfessionalDiscoveryScreenState();
}

class _ProfessionalDiscoveryScreenState extends ConsumerState<ProfessionalDiscoveryScreen> {
  BusinessCategory? _category;
  bool _verifiedOnly = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final businesses = ref.watch(businessesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find Professionals')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: AqaratiSearchField(
              hint: 'Search professionals or businesses',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      label: const Text('Verified only'),
                      selected: _verifiedOnly,
                      avatar: const Icon(Icons.verified_rounded, size: AppIconSize.sm),
                      onSelected: (v) => setState(() => _verifiedOnly = v),
                    ),
                  ),
                  ...BusinessCategory.values.map((c) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: ChoiceChip(
                          label: Text(c.label),
                          selected: _category == c,
                          onSelected: (_) => setState(() => _category = _category == c ? null : c),
                        ),
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            child: businesses.when(
              data: (list) {
                final filtered = list.where((b) {
                  final matchesQuery = _query.isEmpty || b.name.toLowerCase().contains(_query.toLowerCase());
                  final matchesCategory = _category == null || b.categories.contains(_category);
                  final matchesVerified = !_verifiedOnly || b.verification.isVerified;
                  return matchesQuery && matchesCategory && matchesVerified;
                }).toList();

                if (filtered.isEmpty) {
                  return AqaratiEmptyState(
                    icon: Icons.groups_outlined,
                    title: 'No businesses found',
                    message: 'Try a different category or clear your filters.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final business = filtered[i];
                    return BusinessCard(
                      business: business,
                      onTap: () => context.push('/business/${business.id}'),
                    );
                  },
                );
              },
              loading: () => const AqaratiLoadingLine(label: 'Finding professionals...'),
              error: (err, st) => AqaratiErrorState(onRetry: () => ref.invalidate(businessesProvider)),
            ),
          ),
        ],
      ),
    );
  }
}
