import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';
import '../../core/widgets/auth_gate_sheet.dart';
import '../../core/widgets/states.dart';
import '../../data/models/business.dart';
import '../../data/models/enums.dart';
import '../../data/models/property.dart';
import '../../data/repositories/app_state_providers.dart';
import '../../data/repositories/providers.dart';
import '../enquiry/book_viewing_screen.dart';
import '../enquiry/enquiry_screen.dart';
import '../enquiry/make_offer_screen.dart';
import 'property_gallery_screen.dart';

/// Matches 20.01-property-default: hero with back/counter/share/save
/// overlay, a green "VERIFIED LISTING" pill + red transaction pill below
/// the image (not on it), serif title, big red price + right-aligned
/// location, four bordered fact cards, "About" with Read more, a
/// Property Details key-value grid, then Book Viewing (outlined) / Ask
/// About Property (filled) as the sticky bar — reference's own hierarchy,
/// not assumed from Home/Results.
class PropertyDetailScreen extends ConsumerStatefulWidget {
  final String propertyId;

  const PropertyDetailScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  bool _descriptionExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final propertyRepo = ref.watch(propertyRepositoryProvider);

    return Scaffold(
      body: FutureBuilder<Property?>(
        future: propertyRepo.getById(widget.propertyId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AqaratiLoadingLine(label: 'Loading property...');
          }
          final property = snapshot.data;
          if (property == null) {
            return AqaratiErrorState(onRetry: () => setState(() {}));
          }
          return _buildDetail(context, theme, property);
        },
      ),
    );
  }

  Widget _buildDetail(BuildContext context, ThemeData theme, Property property) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Hero(property: property)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (property.verification.isVerified)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(AppRadius.sm)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.shield_rounded, size: 14, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text('VERIFIED LISTING', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(AppRadius.sm)),
                          child: Text(
                            property.transactionType.forSaleLabel,
                            style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(property.title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(property.priceLabel, style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.primary))),
                        Row(
                          children: [
                            const Icon(AppIcons.location, size: AppIconSize.compact, color: AppColors.slate),
                            const SizedBox(width: 2),
                            Text(property.locationLabel.split(',').take(2).join(','), style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.xxxl),
                    _FactCards(property: property),
                    const Divider(height: AppSpacing.xxxl),
                    Text('About this property', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      property.description.isEmpty ? 'No description provided yet.' : property.description,
                      style: theme.textTheme.bodyMedium,
                      maxLines: _descriptionExpanded ? null : 2,
                      overflow: _descriptionExpanded ? null : TextOverflow.ellipsis,
                    ),
                    if (!_descriptionExpanded && property.description.length > 90)
                      TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        onPressed: () => setState(() => _descriptionExpanded = true),
                        child: const Text('Read more'),
                      ),
                    const Divider(height: AppSpacing.xxxl),
                    Text('Property Details', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    _DetailsGrid(property: property),
                    if (property.amenities.isNotEmpty) ...[
                      const Divider(height: AppSpacing.xxxl),
                      Text('Amenities', style: theme.textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: property.amenities.map((a) => Chip(label: Text(a), backgroundColor: AppColors.sand)).toList(),
                      ),
                    ],
                    if (property.transactionType == TransactionType.buy) ...[
                      const Divider(height: AppSpacing.xxxl),
                      OutlinedButton.icon(
                        onPressed: () => showAuthGateSheet(
                          context,
                          actionLabel: 'make an offer',
                          onContinue: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => MakeOfferScreen(property: property)),
                          ),
                        ),
                        icon: const Icon(Icons.local_offer_outlined, size: AppIconSize.compact),
                        label: const Text('Make an offer'),
                      ),
                    ],
                    const Divider(height: AppSpacing.xxxl),
                    Text('Listed by', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    _ListerCard(businessId: property.listedByBusinessId),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(left: 0, right: 0, bottom: 0, child: _BookingBar(property: property)),
      ],
    );
  }
}

class _Hero extends ConsumerWidget {
  final Property property;

  const _Hero({required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedPropertyIdsProvider);
    final saved = savedIds.contains(property.id);
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => PropertyGalleryScreen(property: property)),
            ),
            child: property.imageUrls.isEmpty
                ? Container(color: AppColors.sand, child: const Center(child: Icon(Icons.landscape_outlined, size: 64, color: AppColors.mist)))
                : Image.asset(
                    property.imageUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        Container(color: AppColors.sand, child: const Center(child: Icon(Icons.landscape_outlined, size: 64, color: AppColors.mist))),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  _HeroCircleButton(icon: AppIcons.back, onTap: () => Navigator.of(context).maybePop()),
                  const Spacer(),
                  if (property.imageUrls.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text('1/${property.imageUrls.length}', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
                    ),
                  const Spacer(),
                  _HeroCircleButton(icon: AppIcons.share, onTap: () {}),
                  const SizedBox(width: AppSpacing.sm),
                  _HeroCircleButton(
                    icon: saved ? AppIcons.saveFilled : AppIcons.save,
                    iconColor: saved ? AppColors.error : AppColors.charcoal,
                    onTap: () {
                      if (!saved) {
                        showAuthGateSheet(
                          context,
                          actionLabel: 'save this property',
                          onContinue: () => ref.read(savedPropertyIdsProvider.notifier).update((state) => {...state, property.id}),
                        );
                      } else {
                        ref.read(savedPropertyIdsProvider.notifier).update((state) => {...state}..remove(property.id));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _HeroCircleButton({required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, size: AppIconSize.compact, color: iconColor ?? AppColors.charcoal),
        ),
      ),
    );
  }
}

class _FactCards extends StatelessWidget {
  final Property property;

  const _FactCards({required this.property});

  @override
  Widget build(BuildContext context) {
    final facts = [
      if (property.bedrooms != null) (Icons.bed_outlined, '${property.bedrooms}', 'Beds'),
      if (property.bathrooms != null) (Icons.bathtub_outlined, '${property.bathrooms}', 'Baths'),
      (Icons.grid_view_rounded, '${property.areaSqm.toInt()} m²', 'Area'),
      if (property.parkingSpaces != null) (Icons.local_parking_outlined, '${property.parkingSpaces}', 'Parking'),
    ];
    return Row(
      children: facts
          .map((f) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(AppRadius.md)),
                  child: Column(
                    children: [
                      Icon(f.$1, size: AppIconSize.compact, color: AppColors.primary),
                      const SizedBox(height: 4),
                      Text(f.$2, style: Theme.of(context).textTheme.titleSmall),
                      Text(f.$3, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.slate)),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _DetailsGrid extends StatelessWidget {
  final Property property;

  const _DetailsGrid({required this.property});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Property Type', property.type.label),
      ('Transaction', property.transactionType.label),
      ('Area', '${property.areaSqm.toInt()} m²'),
    ];
    return Column(
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.$1, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.slate)),
                    Text(r.$2, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _ListerCard extends ConsumerWidget {
  final String businessId;

  const _ListerCard({required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessRepo = ref.watch(businessRepositoryProvider);
    return FutureBuilder<Business?>(
      future: businessRepo.getById(businessId),
      builder: (context, snapshot) {
        final business = snapshot.data;
        return InkWell(
          onTap: business == null ? null : () => context.push('/business/${business.id}'),
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
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.sand,
                  child: Text(business?.name.substring(0, 1) ?? '?', style: Theme.of(context).textTheme.titleMedium),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(business?.name ?? 'Unknown', style: Theme.of(context).textTheme.titleSmall),
                      if (business?.verification.isVerified == true)
                        Text('Verified Business', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.secondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BookingBar extends StatelessWidget {
  final Property property;

  const _BookingBar({required this.property});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: AppElevation.subtleAlpha), blurRadius: AppElevation.overlayBlur)],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => showAuthGateSheet(
                context,
                actionLabel: 'book a viewing',
                onContinue: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => BookViewingScreen(property: property)),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: AppIconSize.compact),
                    const SizedBox(width: AppSpacing.sm),
                    const Text('Book Viewing', maxLines: 1),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AqaratiButton(
              label: 'Ask About Property',
              icon: Icons.help_outline_rounded,
              fullWidth: true,
              onPressed: () => showAuthGateSheet(
                context,
                actionLabel: 'ask about this property',
                onContinue: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => EnquiryScreen(property: property)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
