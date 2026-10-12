import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/localization/flow_strings.dart';
import '../../data/models/enums.dart';
import '../../data/models/property.dart';
import '../../data/repositories/providers.dart';
import '../flow/widgets/flow_common.dart' show AQSkeleton;
import '../viewing/widgets/viewing_format.dart';
import '../viewing/widgets/viewing_scaffold.dart';
import '../workspace/aq_home.dart' show aqImg;

final _compareProvider = FutureProvider.autoDispose
    .family<List<Property>, String>((ref, ids) async {
      final all = await ref.watch(propertyRepositoryProvider).search();
      return [
        for (final id in ids.split(','))
          ...all.where((p) => p.id == id).take(1),
      ];
    });

/// Side-by-side facts for the properties picked in Saved. Every value comes from the listing; a
/// missing value reads "Not listed" instead of a dash.
class CompareScreen extends ConsumerWidget {
  final List<String> propertyIds;
  const CompareScreen({super.key, required this.propertyIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final data = ref.watch(_compareProvider(propertyIds.join(',')));
    final count = data.valueOrNull?.length;
    return AQViewingScaffold(
      title: f.t('cmp.title'),
      subtitle: count == null
          ? null
          : f.t('cmp.sub', {'n': VFmt.n(context, count)}),
      backLabel: f.t('common.back'),
      onBack: () => Navigator.of(context).maybePop(),
      children: [
        data.when(
          loading: () => const AQSkeleton(),
          error: (_, _) => _Note(icon: 'alert', text: f.t('cmp.err')),
          data: (list) => list.isEmpty
              ? _Note(
                  icon: 'info',
                  title: f.t('cmp.empty.t'),
                  text: f.t('cmp.empty.b'),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final p in list) ...[
                          _Column(property: p),
                          if (p != list.last)
                            const SizedBox(width: AQSpacing.x3),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final String icon, text;
  final String? title;
  const _Note({required this.icon, required this.text, this.title});
  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return AQSurface(
      padding: const EdgeInsets.all(AQSpacing.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AQIcon(icon, size: AQIconSize.medium, color: c.accent),
          const SizedBox(width: AQSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: AQTypography.of(context, AQText.titleMedium),
                  ),
                if (title != null) const SizedBox(height: AQSpacing.x1),
                Text(
                  text,
                  style: AQTypography.of(
                    context,
                    AQText.bodyMedium,
                    soft: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Column extends StatelessWidget {
  final Property property;
  const _Column({required this.property});

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final p = property;
    final na = f.t('cmp.na');
    String n(num? v, [String suffix = '']) =>
        v == null ? na : '${VFmt.n(context, v.round())}$suffix';
    String txLabel() => switch (p.transactionType) {
      TransactionType.buy => f.t('cmp.tx.buy'),
      TransactionType.rent => f.t('cmp.tx.rent'),
      TransactionType.lease => f.t('cmp.tx.lease'),
    };
    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: AQTypography.of(context, AQText.bodySmall, soft: true),
            ),
          ),
          const SizedBox(width: AQSpacing.x2),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AQTypography.of(context, AQText.bodyMedium),
            ),
          ),
        ],
      ),
    );
    return SizedBox(
      width: 260,
      child: AQSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AQRadius.medium),
              ),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: ExcludeSemantics(
                  child: p.imageUrls.isEmpty
                      ? ColoredBox(color: c.surfaceSelected)
                      : aqImg(p.imageUrls.first, cacheWidth: 520),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AQSpacing.x4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p.verification.status == VerificationStatus.verified)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AQSpacing.x2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AQIcon('verified', size: 16, color: c.accent),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                f.t('cmp.verified'),
                                style: AQTypography.of(
                                  context,
                                  AQText.labelMedium,
                                  color: c.accentDeep,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      p.priceLabel,
                      style: AQTypography.of(
                        context,
                        AQText.titleLarge,
                        color: c.accentDeep,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      VFmt.iso(p.title),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AQTypography.of(context, AQText.titleSmall),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      VFmt.iso(p.locationLabel),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AQTypography.of(
                        context,
                        AQText.bodySmall,
                        soft: true,
                      ),
                    ),
                    const SizedBox(height: AQSpacing.x3),
                    Divider(height: 1, color: c.hairline),
                    const SizedBox(height: AQSpacing.x2),
                    row(
                      f.t('cmp.type'),
                      FlowStrings.keys.contains('ptype.${p.type.name}')
                          ? f.t('ptype.${p.type.name}')
                          : p.type.label,
                    ),
                    row(f.t('cmp.beds'), n(p.bedrooms)),
                    row(f.t('cmp.baths'), n(p.bathrooms)),
                    row(f.t('cmp.area'), n(p.areaSqm, ' m²')),
                    row(f.t('cmp.parking'), n(p.parkingSpaces)),
                    row(f.t('cmp.tx'), txLabel()),
                    const SizedBox(height: AQSpacing.x2),
                    Divider(height: 1, color: c.hairline),
                    const SizedBox(height: AQSpacing.x3),
                    Text(
                      f.t('cmp.amen'),
                      style: AQTypography.of(
                        context,
                        AQText.labelMedium,
                        color: c.inkSoft,
                      ),
                    ),
                    const SizedBox(height: AQSpacing.x2),
                    if (p.amenities.isEmpty)
                      Text(
                        f.t('cmp.none'),
                        style: AQTypography.of(
                          context,
                          AQText.bodySmall,
                          soft: true,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final a in p.amenities)
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.surfaceSelected,
                                borderRadius: BorderRadius.circular(
                                  AQRadius.small,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AQSpacing.x2,
                                  vertical: 5,
                                ),
                                child: Text(
                                  a,
                                  style: AQTypography.of(
                                    context,
                                    AQText.labelMedium,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    const Spacer(),
                    const SizedBox(height: AQSpacing.x4),
                    AQSecondaryButton(
                      label: f.t('cmp.open'),
                      trailingChevron: false,
                      onPressed: () => context.push('/property/${p.id}'),
                    ),
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
