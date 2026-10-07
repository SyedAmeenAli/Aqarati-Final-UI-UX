import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_search_field.dart';
import '../../core/widgets/property_card.dart';
import '../../data/repositories/app_state_providers.dart';
import '../../data/repositories/providers.dart';

/// Matches 17.01-search-empty / 17.09-search-mixed: recent + popular search
/// entry point, then an inline mixed-result preview once a query is typed,
/// with "See all matching properties" handing off to the full Results list.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  static const _popularSearches = [
    'Villas in Muscat',
    'Apartments',
    'Land in Seeb',
    'Interior Designers',
    'Architecture',
  ];

  String _query = '';

  void _commit(String query) {
    if (query.trim().isEmpty) return;
    ref.read(recentSearchesProvider.notifier).update((state) {
      final next = [query, ...state.where((s) => s.toLowerCase() != query.toLowerCase())];
      return next.take(6).toList();
    });
    setState(() => _query = query);
  }

  void _openResults(String query) {
    _commit(query);
    context.push('/search?q=${Uri.encodeComponent(query)}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recent = ref.watch(recentSearchesProvider);
    final propertyRepo = ref.watch(propertyRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.surface,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(AppIcons.back, size: AppIconSize.compact, color: AppColors.charcoal),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AqaratiSearchField(
                      hint: 'Search properties, locations or services',
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      onSubmitted: _openResults,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.trim().isEmpty
                  ? _RecentAndPopular(
                      recent: recent,
                      popular: _popularSearches,
                      onTapTerm: _openResults,
                      onClearAll: () => ref.read(recentSearchesProvider.notifier).state = [],
                      onRemove: (term) => ref.read(recentSearchesProvider.notifier).update(
                            (state) => state.where((s) => s != term).toList(),
                          ),
                    )
                  : FutureBuilder(
                      future: propertyRepo.search(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final words = _query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
                        final matches = snapshot.data!
                            .where((p) => words.any('${p.title} ${p.locationLabel}'.toLowerCase().contains))
                            .take(2)
                            .toList();
                        return ListView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          children: [
                            Text('PROPERTIES', style: theme.textTheme.labelMedium),
                            const SizedBox(height: AppSpacing.sm),
                            if (matches.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                child: Text('No properties match "$_query" yet.', style: theme.textTheme.bodyMedium),
                              )
                            else ...[
                              for (final property in matches) ...[
                                PropertyCard(
                                  property: property,
                                  variant: PropertyCardVariant.list,
                                  onTap: () => context.push('/property/${property.id}'),
                                  isSaved: ref.watch(savedPropertyIdsProvider).contains(property.id),
                                  onSaveToggle: () => ref.read(savedPropertyIdsProvider.notifier).update((state) {
                                    final next = {...state};
                                    next.contains(property.id) ? next.remove(property.id) : next.add(property.id);
                                    return next;
                                  }),
                                ),
                                const SizedBox(height: AppSpacing.md),
                              ],
                              TextButton(
                                onPressed: () => _openResults(_query),
                                child: const Text('See all matching properties'),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentAndPopular extends StatelessWidget {
  final List<String> recent;
  final List<String> popular;
  final ValueChanged<String> onTapTerm;
  final VoidCallback onClearAll;
  final ValueChanged<String> onRemove;

  const _RecentAndPopular({
    required this.recent,
    required this.popular,
    required this.onTapTerm,
    required this.onClearAll,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (recent.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RECENT SEARCHES', style: theme.textTheme.labelMedium),
              TextButton(onPressed: onClearAll, child: const Text('Clear all')),
            ],
          ),
          for (final term in recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.history_rounded, color: AppColors.mist),
              title: Text(term, style: theme.textTheme.bodyMedium),
              trailing: IconButton(
                icon: const Icon(Icons.close_rounded, size: AppIconSize.compact, color: AppColors.mist),
                onPressed: () => onRemove(term),
              ),
              onTap: () => onTapTerm(term),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text('POPULAR SEARCHES', style: theme.textTheme.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: popular
              .map((term) => OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                    ),
                    onPressed: () => onTapTerm(term),
                    child: Text(term),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
