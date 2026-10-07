import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/property_card.dart';
import '../../core/widgets/states.dart';
import '../../data/models/property.dart';
import '../../data/models/saved.dart';
import '../../data/repositories/app_state_providers.dart';
import '../../data/repositories/providers.dart';
import '../compare/compare_screen.dart';

class SavedScreen extends ConsumerStatefulWidget {
  const SavedScreen({super.key});

  @override
  ConsumerState<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends ConsumerState<SavedScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  final Set<String> _selectedForCompare = {};

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final savedIds = ref.watch(savedPropertyIdsProvider);
    final savedSearches = ref.watch(savedSearchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Properties'), Tab(text: 'Searches')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProperties(savedIds),
          _buildSearches(savedSearches),
        ],
      ),
      floatingActionButton: _selectedForCompare.length >= 2
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CompareScreen(propertyIds: _selectedForCompare.toList()),
                ),
              ),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
              label: Text('Compare (${_selectedForCompare.length})', style: const TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildProperties(Set<String> savedIds) {
    if (savedIds.isEmpty) {
      return AqaratiEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'Save properties you want to revisit',
        message: 'Your saved properties will appear here.',
        ctaLabel: 'Explore properties',
        onCta: () => context.go('/home'),
      );
    }
    final propertyRepo = ref.watch(propertyRepositoryProvider);
    return FutureBuilder<List<Property>>(
      future: propertyRepo.search(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AqaratiLoadingLine(label: 'Loading saved properties...');
        }
        final properties = snapshot.data!.where((p) => savedIds.contains(p.id)).toList();
        return Column(
          children: [
            if (properties.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select up to 3 to compare',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: properties.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, i) {
                  final property = properties[i];
                  final selected = _selectedForCompare.contains(property.id);
                  return Stack(
                    children: [
                      PropertyCard(
                        property: property,
                        isSaved: true,
                        onTap: () => context.push('/property/${property.id}'),
                        onSaveToggle: () {
                          ref.read(savedPropertyIdsProvider.notifier).update((state) {
                            final next = {...state}..remove(property.id);
                            return next;
                          });
                          _selectedForCompare.remove(property.id);
                        },
                      ),
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm + 40,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            if (selected) {
                              _selectedForCompare.remove(property.id);
                            } else if (_selectedForCompare.length < 3) {
                              _selectedForCompare.add(property.id);
                            }
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 18,
                              color: selected ? AppColors.primary : AppColors.charcoal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearches(List<SavedSearch> savedSearches) {
    if (savedSearches.isEmpty) {
      return AqaratiEmptyState(
        icon: Icons.search_outlined,
        title: 'Save a search',
        message: 'Save your filters from Search Results to get notified of new matches.',
        ctaLabel: 'Start searching',
        onCta: () => context.push('/search'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: savedSearches.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final search = savedSearches[i];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(search.label, style: Theme.of(context).textTheme.titleSmall),
              ),
              IconButton(
                onPressed: () => ref.read(savedSearchesProvider.notifier).update(
                      (state) => state.where((s) => s.id != search.id).toList(),
                    ),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.mist),
              ),
            ],
          ),
        );
      },
    );
  }
}
