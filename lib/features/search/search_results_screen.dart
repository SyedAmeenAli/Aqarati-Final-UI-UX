import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_search_field.dart';
import '../../core/widgets/property_card.dart';
import '../../core/widgets/states.dart';
import '../../data/models/enums.dart';
import '../../data/models/property.dart';
import '../../data/repositories/app_state_providers.dart';
import '../../data/repositories/providers.dart';
import 'filter_sheet.dart';
import 'search_filters.dart';

/// Matches 18.01-results-buy-default: search bar with back button, an
/// underline Buy/Rent/Lease tab row (distinct from Home's filled-button
/// segment — the reference genuinely differs per screen, not guessed),
/// a "N properties" + Filter/Sort row, then bordered PropertyCard.list.
class SearchResultsScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const SearchResultsScreen({super.key, this.initialQuery});

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  final _filters = SearchFilters();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
  }

  List<Property> _applyFilters(List<Property> properties) {
    final queryWords = _query.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    var results = properties.where((p) {
      final haystack = '${p.title} ${p.locationLabel} ${p.type.label}'.toLowerCase();
      final matchesQuery = queryWords.isEmpty || queryWords.any(haystack.contains);
      final matchesTransaction =
          _filters.transactionType == null || p.transactionType == _filters.transactionType;
      final matchesType = _filters.propertyTypes.isEmpty || _filters.propertyTypes.contains(p.type);
      final matchesBedrooms = _filters.minBedrooms == null ||
          (p.bedrooms != null && p.bedrooms! >= _filters.minBedrooms!);
      final matchesBathrooms = _filters.minBathrooms == null ||
          (p.bathrooms != null && p.bathrooms! >= _filters.minBathrooms!);
      final matchesVerified = !_filters.verifiedOnly || p.verification.isVerified;
      return matchesQuery &&
          matchesTransaction &&
          matchesType &&
          matchesBedrooms &&
          matchesBathrooms &&
          matchesVerified;
    }).toList();

    switch (_filters.sort) {
      case SortOption.priceLowHigh:
        results.sort((a, b) => a.price.amount.compareTo(b.price.amount));
      case SortOption.priceHighLow:
        results.sort((a, b) => b.price.amount.compareTo(a.price.amount));
      case SortOption.largestArea:
        results.sort((a, b) => b.areaSqm.compareTo(a.areaSqm));
      case SortOption.recommended:
      case SortOption.newest:
      case SortOption.mostViewed:
        break;
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allProperties = ref.watch(propertyRepositoryProvider);

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Property>>(
          future: allProperties.search(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const AqaratiLoadingLine(label: 'Finding properties...');
            }
            final results = _applyFilters(snapshot.data!);
            return Column(
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
                          initialValue: widget.initialQuery,
                          onChanged: (v) => setState(() => _query = v),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                  child: _TransactionTabs(
                    selected: _filters.transactionType,
                    onChanged: (t) => setState(() => _filters.transactionType = t),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                  child: Row(
                    children: [
                      Text('${results.length} properties', style: theme.textTheme.titleMedium),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => showFilterSheet(context, _filters, () => setState(() {})),
                        icon: const Icon(Icons.tune_rounded, size: AppIconSize.compact),
                        label: Text(_filters.activeCount == 0 ? 'Filter' : 'Filter (${_filters.activeCount})'),
                      ),
                      TextButton.icon(
                        onPressed: () => showSortSheet(context, _filters, () => setState(() {})),
                        icon: const Icon(Icons.swap_vert_rounded, size: AppIconSize.compact),
                        label: const Text('Sort'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: results.isEmpty
                      ? AqaratiEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No results found',
                          message: 'Try a different property, location or service.',
                          ctaLabel: 'Clear filters',
                          onCta: () => setState(() {
                            _filters.transactionType = null;
                            _filters.propertyTypes.clear();
                            _filters.minBedrooms = null;
                            _filters.minBathrooms = null;
                            _filters.verifiedOnly = false;
                          }),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: results.length,
                          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, i) {
                            final property = results[i];
                            final savedIds = ref.watch(savedPropertyIdsProvider);
                            return PropertyCard(
                              property: property,
                              variant: PropertyCardVariant.list,
                              onTap: () => context.push('/property/${property.id}'),
                              isSaved: savedIds.contains(property.id),
                              onSaveToggle: () => ref.read(savedPropertyIdsProvider.notifier).update((state) {
                                final next = {...state};
                                savedIds.contains(property.id) ? next.remove(property.id) : next.add(property.id);
                                return next;
                              }),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TransactionTabs extends StatelessWidget {
  final TransactionType? selected;
  final ValueChanged<TransactionType?> onChanged;

  const _TransactionTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: TransactionType.values.map((t) {
        final isSelected = t == selected || (selected == null && t == TransactionType.buy);
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          child: InkWell(
            onTap: () => onChanged(t),
            child: Container(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent, width: 2)),
              ),
              child: Text(
                t.label,
                style: theme.textTheme.titleSmall?.copyWith(color: isSelected ? AppColors.primary : AppColors.slate),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
