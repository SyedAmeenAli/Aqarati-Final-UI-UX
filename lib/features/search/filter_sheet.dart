import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';
import '../../data/models/enums.dart';
import 'search_filters.dart';

Future<void> showFilterSheet(BuildContext context, SearchFilters filters, VoidCallback onApply) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _FilterSheet(filters: filters, onApply: onApply),
  );
}

class _FilterSheet extends StatefulWidget {
  final SearchFilters filters;
  final VoidCallback onApply;

  const _FilterSheet({required this.filters, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters', style: theme.textTheme.headlineSmall),
                  TextButton(
                    onPressed: () => setState(() {
                      widget.filters.transactionType = null;
                      widget.filters.propertyTypes.clear();
                      widget.filters.minBedrooms = null;
                      widget.filters.minBathrooms = null;
                      widget.filters.verifiedOnly = false;
                    }),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text('TRANSACTION', style: theme.textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: TransactionType.values.map((t) {
                        final selected = widget.filters.transactionType == t;
                        return ChoiceChip(
                          label: Text(t.label),
                          selected: selected,
                          onSelected: (_) => setState(() => widget.filters.transactionType = t),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('PROPERTY TYPE', style: theme.textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        PropertyType.villa,
                        PropertyType.apartment,
                        PropertyType.townhouse,
                        PropertyType.residentialLand,
                        PropertyType.office,
                        PropertyType.shop,
                        PropertyType.warehouse,
                      ].map((t) {
                        final selected = widget.filters.propertyTypes.contains(t);
                        return FilterChip(
                          label: Text(t.label),
                          selected: selected,
                          onSelected: (_) => setState(() {
                            selected ? widget.filters.propertyTypes.remove(t) : widget.filters.propertyTypes.add(t);
                          }),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('BEDROOMS', style: theme.textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [null, 1, 2, 3, 4].map((n) {
                        final selected = widget.filters.minBedrooms == n;
                        return ChoiceChip(
                          label: Text(n == null ? 'Any' : n == 4 ? '4+' : '$n'),
                          selected: selected,
                          onSelected: (_) => setState(() => widget.filters.minBedrooms = n),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('BATHROOMS', style: theme.textTheme.labelMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [null, 1, 2, 3, 4].map((n) {
                        final selected = widget.filters.minBathrooms == n;
                        return ChoiceChip(
                          label: Text(n == null ? 'Any' : n == 4 ? '4+' : '$n'),
                          selected: selected,
                          onSelected: (_) => setState(() => widget.filters.minBathrooms = n),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Verified properties only'),
                      value: widget.filters.verifiedOnly,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => widget.filters.verifiedOnly = v),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: AqaratiButton(
                  label: 'Apply filters',
                  fullWidth: true,
                  onPressed: () {
                    widget.onApply();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showSortSheet(BuildContext context, SearchFilters filters, VoidCallback onApply) {
  return showModalBottomSheet(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort by', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              ...SortOption.values.map((option) => RadioListTile<SortOption>(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                    title: Text(option.label),
                    value: option,
                    groupValue: filters.sort,
                    onChanged: (v) {
                      filters.sort = v!;
                      onApply();
                      Navigator.of(context).pop();
                    },
                  )),
            ],
          ),
        ),
      );
    },
  );
}
