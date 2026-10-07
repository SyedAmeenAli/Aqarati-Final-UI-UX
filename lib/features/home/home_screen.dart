import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_asset_image.dart';
import '../../core/widgets/aqarati_category_card.dart';
import '../../core/widgets/aqarati_map_view.dart';
import '../../core/widgets/aqarati_logo.dart';
import '../../core/widgets/aqarati_search_field.dart';
import '../../core/widgets/property_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/states.dart';
import '../../data/datasources/mock_project_data.dart';
import '../../data/models/business.dart';
import '../../data/models/enums.dart';
import '../../data/models/project.dart';
import '../../data/models/property.dart';
import '../../data/repositories/app_state_providers.dart';
import '../../data/repositories/providers.dart';
import '../../data/datasources/mock_business_data.dart';
import '../map/map_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  TransactionType _selected = TransactionType.buy;

  static const _categories = [
    (AppIcons.properties, 'Properties'),
    (AppIcons.developments, 'Developments'),
    (AppIcons.agents, 'Agents'),
    (AppIcons.construction, 'Construction'),
    (AppIcons.architecture, 'Architecture'),
    (AppIcons.design, 'Design'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final featured = ref.watch(featuredPropertiesProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HomeTopBar(),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Find your place.', style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Homes, properties and trusted professionals across Oman.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AqaratiSearchField(
                      hint: 'Search properties, locations or services',
                      readOnly: true,
                      onTap: () => context.push('/search/start'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _TransactionToggle(
                      selected: _selected,
                      onChanged: (t) => setState(() => _selected = t),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text('Explore Aqarati', style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 2.2,
                      children: _categories
                          .map((c) => AqaratiCategoryCard(icon: c.$1, label: c.$2, onTap: () => context.push('/search')))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Near you',
                actionLabel: 'See all',
                onAction: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute(builder: (context) => MapScreen(properties: featured.value ?? const [])),
                ),
              ),
            ),
            featured.when(
              data: (properties) {
                if (properties.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
                final nearest = properties.first;
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NearYouMapPreview(
                          property: nearest,
                          onTap: () => Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(builder: (context) => MapScreen(properties: properties)),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _NearbyRow(
                          property: nearest,
                          onTap: () => context.push('/property/${nearest.id}'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox()),
              error: (err, st) => const SliverToBoxAdapter(child: SizedBox()),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Verified properties',
                actionLabel: 'See all',
                onAction: () => context.push('/search'),
              ),
            ),
            featured.when(
              data: (properties) {
                if (properties.isEmpty) {
                  return SliverToBoxAdapter(
                    child: AqaratiEmptyState(
                      icon: Icons.home_work_outlined,
                      title: 'No properties yet',
                      message: 'Verified listings will appear here as they become available.',
                    ),
                  );
                }
                return SliverToBoxAdapter(
                  child: SizedBox(
                    height: 246,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: properties.length,
                      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                      itemBuilder: (context, i) {
                        final property = properties[i];
                        final savedIds = ref.watch(savedPropertyIdsProvider);
                        return PropertyCard(
                          property: property,
                          width: 200,
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
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: AqaratiLoadingLine(label: 'Finding properties...'),
              ),
              error: (err, st) => SliverToBoxAdapter(
                child: AqaratiErrorState(onRetry: () => ref.invalidate(featuredPropertiesProvider)),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Trusted professionals',
                actionLabel: 'See all',
                onAction: () => context.push('/professionals'),
              ),
            ),
            ref.watch(businessesProvider).when(
                  data: (businesses) => SliverToBoxAdapter(
                    child: SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        itemCount: businesses.length,
                        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                        itemBuilder: (context, i) => _ProfessionalCard(
                          business: businesses[i],
                          onTap: () => context.push('/business/${businesses[i].id}'),
                        ),
                      ),
                    ),
                  ),
                  loading: () => const SliverToBoxAdapter(child: SizedBox()),
                  error: (err, st) => const SliverToBoxAdapter(child: SizedBox()),
                ),
            featured.when(
              data: (properties) {
                if (properties.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
                final spotlight = properties.first;
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Featured Spotlight', style: theme.textTheme.titleSmall),
                        const SizedBox(height: AppSpacing.sm),
                        _FeaturedSpotlightCard(
                          property: spotlight,
                          onTap: () => context.push('/property/${spotlight.id}'),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(child: SizedBox()),
              error: (err, st) => const SliverToBoxAdapter(child: SizedBox()),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                child: _SponsoredCard(),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(title: 'Latest projects'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: mockProjects.map((p) => _ProjectRow(project: p)).toList(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AqaratiLogoMark(height: 26),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
          ),
          icon: const Icon(AppIcons.notification, color: AppColors.charcoal, size: AppIconSize.md),
        ),
        InkWell(
          onTap: () => context.go('/profile'),
          customBorder: const CircleBorder(),
          child: const CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.sand,
            child: Icon(AppIcons.profile, size: 16, color: AppColors.slate),
          ),
        ),
      ],
    );
  }
}

class _TransactionToggle extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  const _TransactionToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TransactionType.values.map((t) {
        final isSelected = t == selected;
        return Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: InkWell(
            onTap: () => onChanged(t),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.sand,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                t.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      color: isSelected ? Colors.white : AppColors.slate,
                    ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Compact real Google Map preview centered on the nearest property. Same
/// footprint as the earlier painted stand-in; only the map surface is real.
class _NearYouMapPreview extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const _NearYouMapPreview({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lat = property.latitude ?? 23.5880;
    final lng = property.longitude ?? 58.3829;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        height: 120,
        child: IgnorePointer(
          child: AqaratiMapView(
            initialCenter: LatLng(lat, lng),
            initialZoom: 13,
            interactive: false,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            markers: {
              Marker(markerId: MarkerId(property.id), position: LatLng(lat, lng)),
            },
          ),
        ),
      ),
    );
  }
}

class _NearbyRow extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const _NearbyRow({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 80,
              height: 80,
              child: property.imageUrls.isEmpty
                  ? Container(color: AppColors.sand)
                  : AqaratiAssetImage(property.imageUrls.first, displayWidth: 80),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (property.verification.isVerified)
                  Text('VERIFIED', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
                Text(property.priceLabel, style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                Text(property.title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  '${property.locationLabel.split(',').first} · ${property.bedrooms ?? '-'} BR · ${property.bathrooms ?? '-'} BA · ${property.areaSqm.toInt()} sqm',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final Business business;
  final VoidCallback onTap;

  const _ProfessionalCard({required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 168,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.sand,
              child: Text(business.name.isNotEmpty ? business.name[0] : '?', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(business.name, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (business.verification.isVerified) ...[
                        const SizedBox(width: 2),
                        const Icon(AppIcons.verified, size: 13, color: AppColors.verified),
                      ],
                    ],
                  ),
                  Text(
                    business.categories.isNotEmpty ? business.categories.first.label : '',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (business.rating != null)
                    Row(
                      children: [
                        const Icon(AppIcons.star, size: 13, color: AppColors.sand600),
                        const SizedBox(width: 2),
                        Text(
                          '${business.rating!.toStringAsFixed(1)} (${business.reviewCount} reviews)',
                          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.slate),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedSpotlightCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const _FeaturedSpotlightCard({required this.property, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: property.imageUrls.isEmpty
                  ? Container(color: AppColors.sand)
                  : AqaratiAssetImage(property.imageUrls.first, displayWidth: 420),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.sm)),
                      child: Text('FEATURED', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, letterSpacing: 0.6)),
                    ),
                    const SizedBox(height: 4),
                    Text(property.title, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                    Text(
                      property.locationLabel,
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(property.priceLabel, style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsoredCard extends StatelessWidget {
  const _SponsoredCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.neutral900, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Row(
        children: [
          const Icon(AppIcons.flight, color: AppColors.sand300, size: AppIconSize.md),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SPONSORED', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.neutral500, letterSpacing: 0.6)),
                Text('Fly with Oman Air', style: theme.textTheme.titleSmall?.copyWith(color: Colors.white)),
                Text("Fly premium to Muscat's finest destinations.", style: theme.textTheme.bodySmall?.copyWith(color: AppColors.neutral400)),
                const SizedBox(height: 4),
                Text('Book First Class', style: theme.textTheme.labelMedium?.copyWith(color: AppColors.sand300, decoration: TextDecoration.underline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final DevelopmentProject project;

  const _ProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final developer = mockBusinesses.firstWhere((b) => b.id == project.developerBusinessId);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 64,
              height: 64,
              child: project.galleryUrls.isEmpty
                  ? Container(color: AppColors.sand)
                  : AqaratiAssetImage(project.galleryUrls.first, displayWidth: 64),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name, style: theme.textTheme.titleSmall),
                Text('Developments · BY ${developer.name.toUpperCase()}', style: theme.textTheme.bodySmall),
                Row(
                  children: [
                    const Icon(AppIcons.verified, size: 13, color: AppColors.verified),
                    const SizedBox(width: 2),
                    Text('Verified', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.verified)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
