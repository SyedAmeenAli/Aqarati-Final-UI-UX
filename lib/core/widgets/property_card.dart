import 'package:flutter/material.dart';
import '../../data/models/property.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'aqarati_asset_image.dart';

/// AQARATI property card. Two reference-matched compositions:
///  - `feed`/`compact`: Home's borderless card (15.01-home-guest) — small
///    VERIFIED text tag below the image, heart overlaid on the photo.
///  - `list`: Search Results' bordered card (18.01-results-buy-default) —
///    solid VERIFIED pill overlaid on the photo, heart beside the price in
///    the content row, a divider before the facts line.
/// Both read the same Property model; nothing invents a second data shape.
enum PropertyCardVariant { feed, compact, list }

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback? onSaveToggle;
  final bool isSaved;
  final PropertyCardVariant variant;
  final double? width;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.onSaveToggle,
    this.isSaved = false,
    this.variant = PropertyCardVariant.feed,
    this.width,
  });

  String get _factsLine {
    final parts = <String>[];
    if (property.bedrooms != null) parts.add('${property.bedrooms} Beds');
    if (property.bathrooms != null) parts.add('${property.bathrooms} Baths');
    parts.add('${property.areaSqm.toInt()} m²');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    if (variant == PropertyCardVariant.list) return _buildList(context);
    return _buildFeed(context);
  }

  Widget _buildFeed(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = variant == PropertyCardVariant.compact;
    final imageWidth = width ?? (isCompact ? 160 : 200);

    final card = GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AspectRatio(
                  aspectRatio: isCompact ? 4 / 3 : 3 / 2,
                  child: property.imageUrls.isEmpty
                      ? _imagePlaceholder()
                      : AqaratiAssetImage(
                          property.imageUrls.first,
                          displayWidth: imageWidth,
                          errorBuilder: (context, error, stack) => _imagePlaceholder(),
                        ),
                ),
              ),
              if (onSaveToggle != null)
                Positioned(top: AppSpacing.sm, right: AppSpacing.sm, child: _SaveButton(isSaved: isSaved, onTap: onSaveToggle!)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (property.verification.isVerified) ...[
            const _VerifiedTextTag(),
            const SizedBox(height: 2),
          ],
          Text(property.priceLabel, style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          Text(property.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
          const SizedBox(height: 1),
          Text(
            '${property.locationLabel.split(',').first} · $_factsLine',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate),
          ),
        ],
      ),
    );

    if (width == null) return card;
    return SizedBox(width: width, child: card);
  }

  Widget _buildList(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: property.imageUrls.isEmpty
                      ? _imagePlaceholder()
                      : AqaratiAssetImage(
                          property.imageUrls.first,
                          displayWidth: width ?? 380,
                          errorBuilder: (context, error, stack) => _imagePlaceholder(),
                        ),
                ),
                if (property.verification.isVerified)
                  const Positioned(top: AppSpacing.sm, left: AppSpacing.sm, child: _VerifiedSolidPill()),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(property.priceLabel, style: theme.textTheme.titleLarge?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      if (onSaveToggle != null) _SaveButton(isSaved: isSaved, onTap: onSaveToggle!, onLightSurface: true),
                    ],
                  ),
                  Text(property.title, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(property.locationLabel.split(',').take(2).join(','), style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate)),
                  const Divider(height: AppSpacing.lg),
                  Text(_factsLine, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.charcoal)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        color: AppColors.sand,
        child: const Icon(Icons.landscape_outlined, size: 32, color: AppColors.mist),
      );
}

class _VerifiedTextTag extends StatelessWidget {
  const _VerifiedTextTag();

  @override
  Widget build(BuildContext context) {
    // Home reference (15.01-home-guest) — small red text tag, no fill icon.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        'VERIFIED',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _VerifiedSolidPill extends StatelessWidget {
  const _VerifiedSolidPill();

  @override
  Widget build(BuildContext context) {
    // Results reference (18.01-results-buy-default) — solid red pill over
    // the photo with a check glyph, distinct from Home's text-only tag.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text('VERIFIED', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaved;
  final VoidCallback onTap;
  final bool onLightSurface;

  const _SaveButton({required this.isSaved, required this.onTap, this.onLightSurface = false});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      key: ValueKey(isSaved),
      size: onLightSurface ? 22 : 16,
      color: isSaved ? AppColors.error : AppColors.charcoal,
    );
    if (onLightSurface) {
      return InkWell(onTap: onTap, customBorder: const CircleBorder(), child: Padding(padding: const EdgeInsets.all(4), child: icon));
    }
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 150), child: icon),
        ),
      ),
    );
  }
}
