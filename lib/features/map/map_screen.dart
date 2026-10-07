import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/config/maps_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_asset_image.dart';
import '../../core/widgets/aqarati_map_view.dart';
import '../../core/widgets/states.dart';
import '../../data/models/enums.dart';
import '../../data/models/property.dart';

const _muscatFallback = LatLng(23.5880, 58.3829);

/// Matches 19.05/19.06-map-markers: search field, Buy/Rent/Lease pill
/// toggle (Home's segment style, not Results' underline — this screen's
/// reference genuinely uses the filled-pill treatment), price-pill
/// markers, current-location + filter circular controls, a bottom
/// preview card on marker selection, and a "List View" pill back to
/// Results. The map surface is a real Google Map (AqaratiMapView).
/// On native (Android/iOS with a configured key), the AQARATI price-pill
/// markers are an overlay positioned from the map's own screen-coordinate
/// projection, pixel-locked to real lat/lng as the map pans/zooms. On web
/// the map is a real but opaque keyless iframe embed with no camera API,
/// so the price pills instead sit in a horizontal strip above it — tapping
/// one recenters the embed on that property's real coordinates.
class MapScreen extends StatefulWidget {
  final List<Property> properties;

  const MapScreen({super.key, required this.properties});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Property? _selected;
  TransactionType _transaction = TransactionType.buy;
  GoogleMapController? _mapController;
  final Map<String, Offset> _pinPositions = {};

  List<Property> get _located => widget.properties.where((p) => p.latitude != null && p.longitude != null).toList();

  Future<void> _refreshPinPositions() async {
    // Web has no GoogleMapController (real map is an opaque keyless iframe
    // embed with no coordinate-projection API) — pins are handled by the
    // scrollable price-pill strip instead, see build().
    if (kIsWeb) return;
    final controller = _mapController;
    if (controller == null || !mounted) return;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final next = <String, Offset>{};
    for (final property in _located) {
      final screen = await controller.getScreenCoordinate(LatLng(property.latitude!, property.longitude!));
      next[property.id] = Offset(screen.x / dpr, screen.y / dpr);
    }
    if (mounted) {
      setState(() {
        _pinPositions
          ..clear()
          ..addAll(next);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.properties.isEmpty) {
      return Scaffold(
        body: AqaratiEmptyState(
          icon: Icons.map_outlined,
          title: 'Nothing to show nearby',
          message: 'Try a different location or clear your filters.',
        ),
      );
    }

    final located = _located;
    final focus = _selected ?? (located.isNotEmpty ? located.first : null);
    final center = focus != null ? LatLng(focus.latitude!, focus.longitude!) : _muscatFallback;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AqaratiMapView(
              // On web the map is a real keyless iframe embed with no camera
              // API, so it's rebuilt centered on whichever property is
              // selected (see the price-pill strip below) rather than
              // panned interactively.
              key: kIsWeb ? ValueKey(focus?.id) : null,
              initialCenter: center,
              initialZoom: kIsWeb ? 14 : 12,
              borderRadius: BorderRadius.zero,
              onMapCreated: (controller) {
                _mapController = controller;
                _refreshPinPositions();
              },
              onCameraMove: _refreshPinPositions,
              onCameraIdle: _refreshPinPositions,
            ),
          ),
          if (kIsWeb)
            Positioned(
              left: 0,
              right: 0,
              top: 150,
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: located.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final property = located[i];
                    final selected = _selected?.id == property.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = property),
                      child: _PricePin(label: property.price.compact, selected: selected),
                    );
                  },
                ),
              ),
            )
          else if (kGoogleMapsConfigured)
            ...located.map((property) {
              final offset = _pinPositions[property.id];
              if (offset == null) return const SizedBox.shrink();
              final selected = _selected?.id == property.id;
              return Positioned(
                left: offset.dx - 40,
                top: offset.dy - 36,
                child: GestureDetector(
                  onTap: () => setState(() => _selected = property),
                  child: _PricePin(label: property.price.compact, selected: selected),
                ),
              );
            }),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md)),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.properties.first.area.isNotEmpty ? widget.properties.first.area : 'Muscat',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _TransactionPillToggle(selected: _transaction, onChanged: (t) => setState(() => _transaction = t)),
                ],
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.lg,
            // On web the price-pill strip sits at top:150, height 44 — push
            // these below it so they don't collide with the last pill at
            // narrow widths (found and fixed live: they overlapped).
            top: kIsWeb ? 205 : 120,
            child: Column(
              children: [
                _MapCircleButton(icon: Icons.my_location_rounded, onTap: () {}),
                const SizedBox(height: AppSpacing.sm),
                _MapCircleButton(icon: Icons.tune_rounded, onTap: () {}),
              ],
            ),
          ),
          if (_selected != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _PreviewCard(
                property: _selected!,
                onView: () => context.push('/property/${_selected!.id}'),
              ),
            )
          else
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.lg,
              child: Center(
                child: _ListViewPill(onTap: () => Navigator.of(context).maybePop()),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransactionPillToggle extends StatelessWidget {
  final TransactionType selected;
  final ValueChanged<TransactionType> onChanged;

  const _TransactionPillToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TransactionType.values.map((t) {
          final isSelected = t == selected;
          return GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                t.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: isSelected ? Colors.white : AppColors.slate),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MapCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Icon(icon, size: AppIconSize.compact, color: AppColors.charcoal),
        ),
      ),
    );
  }
}

class _ListViewPill extends StatelessWidget {
  final VoidCallback onTap;

  const _ListViewPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutral900,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.reorder_rounded, color: Colors.white, size: AppIconSize.compact),
              const SizedBox(width: AppSpacing.sm),
              Text('List View', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricePin extends StatelessWidget {
  final String label;
  final bool selected;

  const _PricePin({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: [BoxShadow(color: AppColors.ink.withValues(alpha: 0.12), blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            const Icon(Icons.circle, size: 6, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: selected ? Colors.white : AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final Property property;
  final VoidCallback onView;

  const _PreviewCard({required this.property, required this.onView});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: property.imageUrls.isEmpty
                        ? Container(color: AppColors.sand)
                        : AqaratiAssetImage(property.imageUrls.first, displayWidth: 88),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (property.verification.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(AppRadius.sm)),
                          child: Text('VERIFIED PROPERTY', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.secondary, fontWeight: FontWeight.w700)),
                        ),
                      Text(property.title, style: theme.textTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(property.priceLabel, style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      Text(property.locationLabel.split(',').take(2).join(','), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: AppSpacing.md,
                    children: [
                      if (property.bedrooms != null) _Fact(icon: Icons.bed_outlined, label: '${property.bedrooms} Beds'),
                      if (property.bathrooms != null) _Fact(icon: Icons.bathtub_outlined, label: '${property.bathrooms} Baths'),
                      _Fact(icon: Icons.square_foot_outlined, label: '${property.areaSqm.toInt()} m²'),
                    ],
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: onView,
                  child: const Text('View'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Fact({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.slate),
        const SizedBox(width: 3),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

