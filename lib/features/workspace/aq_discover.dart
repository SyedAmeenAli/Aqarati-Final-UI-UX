import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/aq/aq_forms.dart';
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/localization/flow_strings.dart';
import '../../data/models/enums.dart';
import '../../data/models/property.dart';
import '../../data/repositories/providers.dart';
import '../viewing/widgets/viewing_format.dart';

/// Property card for Home and Explore: photograph, facts, price. Taps open the property.
class AQPropertyTile extends StatelessWidget {
  final Property property;
  const AQPropertyTile({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final f = FlowStrings.of(context);
    final p = property;
    final facts = [if (p.bedrooms != null) '${VFmt.n(context, p.bedrooms!)} ${f.t('disc.beds')}', '${VFmt.n(context, p.areaSqm.round())} m²'].join(' · ');
    final tx = p.transactionType == TransactionType.buy ? f.t('disc.sale') : f.t('disc.rent');
    return Semantics(
      button: true,
      label: '${p.title}, ${p.locationLabel}, $facts, ${p.priceLabel}',
      excludeSemantics: true,
      child: AQPressable(
        onTap: () => context.push('/property/${p.id}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AQRadius.large),
          child: DecoratedBox(
            decoration: BoxDecoration(color: c.surfaceRaised),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(fit: StackFit.expand, children: [
                  p.imageUrls.isEmpty ? ColoredBox(color: c.surfaceSelected) : Image.asset(p.imageUrls.first, fit: BoxFit.cover, cacheWidth: 900, errorBuilder: (_, _, _) => ColoredBox(color: c.surfaceSelected)),
                  Positioned(
                    left: AQSpacing.x3,
                    top: AQSpacing.x3,
                    child: Wrap(spacing: 6, children: [
                      _Pill(text: tx, dark: true),
                      if (p.verification.isVerified) _Pill(text: f.t('disc.verified'), icon: 'verified'),
                    ]),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(AQSpacing.x4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(VFmt.iso(p.title), style: AQTypography.of(context, AQText.headlineSmall)),
                  const SizedBox(height: AQSpacing.x1 + 2),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(padding: const EdgeInsets.only(top: 2), child: AQIcon('pin', size: 16, color: c.accent)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(VFmt.iso(p.locationLabel.split(',').take(2).join(',').trim()), style: AQTypography.of(context, AQText.bodySmall, soft: true))),
                  ]),
                  const SizedBox(height: AQSpacing.x1),
                  Text(facts, style: AQTypography.of(context, AQText.bodySmall, soft: true)),
                  const SizedBox(height: AQSpacing.x2),
                  Text(p.priceLabel, style: AQTypography.of(context, AQText.titleMedium, color: c.accentDeep)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final String? icon;
  final bool dark;
  const _Pill({required this.text, this.icon, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final fg = dark ? const Color(0xFFF1E8DB) : c.ink;
    return DecoratedBox(
      decoration: BoxDecoration(color: dark ? const Color(0xCC2D2823) : c.surfaceRaised.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(AQRadius.small)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AQSpacing.x2, vertical: 5),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[AQIcon(icon!, size: 14, color: c.accent), const SizedBox(width: 4)],
          Text(text, style: AQTypography.of(context, AQText.labelMedium, color: fg)),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: AQPressable(
        onTap: () {
          AQHaptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: AQMotion.scaled(context, AQMotion.fast),
          constraints: const BoxConstraints(minHeight: AQControl.tap - 4),
          padding: const EdgeInsets.symmetric(horizontal: AQSpacing.x4),
          decoration: BoxDecoration(color: selected ? c.accent : c.surface, borderRadius: BorderRadius.circular(AQControl.tap)),
          child: Center(widthFactor: 1, child: Text(label, style: AQTypography.of(context, AQText.labelMedium, color: selected ? c.onAccent : c.inkSoft))),
        ),
      ),
    );
  }
}

/// All properties, filterable by sale / rent and by area.
class AQPropertyBrowser extends ConsumerStatefulWidget {
  final bool featuredOnly;
  const AQPropertyBrowser({super.key, this.featuredOnly = false});
  @override
  ConsumerState<AQPropertyBrowser> createState() => _AQPropertyBrowserState();
}

class _AQPropertyBrowserState extends ConsumerState<AQPropertyBrowser> {
  TransactionType? _tx;
  String? _area;

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final async = ref.watch(_allPropertiesProvider);
    return async.when(
      loading: () => const Column(children: [AQSkeletonBlock(height: 280), AQSkeletonBlock(height: 280)]),
      error: (_, _) => AQErrorBanner(text: f.t('disc.loadError'), action: AQTextButton(label: f.t('common.retry'), color: c.accent, onPressed: () => ref.invalidate(_allPropertiesProvider))),
      data: (all) {
        final areas = {for (final p in all) p.area}.toList()..sort();
        final shown = all.where((p) => (_tx == null || p.transactionType == _tx) && (_area == null || p.area == _area) && (!widget.featuredOnly || p.verification.isVerified)).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!widget.featuredOnly) ...[
            Wrap(spacing: AQSpacing.x2, runSpacing: AQSpacing.x2, children: [
              _Chip(label: f.t('disc.all'), selected: _tx == null, onTap: () => setState(() => _tx = null)),
              _Chip(label: f.t('disc.sale'), selected: _tx == TransactionType.buy, onTap: () => setState(() => _tx = TransactionType.buy)),
              _Chip(label: f.t('disc.rent'), selected: _tx == TransactionType.rent, onTap: () => setState(() => _tx = TransactionType.rent)),
            ]),
            if (areas.length > 1) ...[
              const SizedBox(height: AQSpacing.x2),
              Wrap(spacing: AQSpacing.x2, runSpacing: AQSpacing.x2, children: [
                _Chip(label: f.t('disc.anywhere'), selected: _area == null, onTap: () => setState(() => _area = null)),
                for (final a in areas) _Chip(label: a, selected: _area == a, onTap: () => setState(() => _area = a)),
              ]),
            ],
            AQTextButton(label: f.t('disc.search'), color: c.accent, trailingIcon: 'chevron-right', onPressed: () => context.push('/search/start')),
            const SizedBox(height: AQSpacing.x2),
          ],
          if (shown.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: AQSpacing.x6), child: Text(f.t('disc.none'), style: AQTypography.of(context, AQText.bodyMedium, soft: true)))
          else
            for (final p in shown) Padding(padding: const EdgeInsets.only(bottom: AQSpacing.x4), child: AQPropertyTile(property: p)),
        ]);
      },
    );
  }
}

final _allPropertiesProvider = FutureProvider.autoDispose<List<Property>>((ref) => ref.watch(propertyRepositoryProvider).search());

class AQSkeletonBlock extends StatelessWidget {
  final double height;
  const AQSkeletonBlock({super.key, this.height = 96});
  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return ExcludeSemantics(child: Container(height: height, margin: const EdgeInsets.only(bottom: AQSpacing.x4), decoration: BoxDecoration(color: c.ink.withValues(alpha: c.isDark ? 0.08 : 0.05), borderRadius: BorderRadius.circular(AQRadius.large))));
  }
}
