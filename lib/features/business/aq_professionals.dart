import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/aq/aq_forms.dart';
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_scene.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/localization/flow_strings.dart';
import '../../data/models/business.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/providers.dart';
import '../search/aq_filter_sheet.dart';
import '../search/aq_search.dart' show AQQueryField;
import '../viewing/widgets/viewing_format.dart';
import '../viewing/widgets/viewing_scaffold.dart';
import '../workspace/aq_home.dart' show aqImg, AQSkeletonBox, AQNoticeLine;

/// Professionals directory: developers, builders, architects, designers, agents and
/// maintenance providers. Opens a profile on tap.
class AQProfessionalsScreen extends ConsumerStatefulWidget {
  final String? query;
  final String? category;
  const AQProfessionalsScreen({super.key, this.query, this.category});
  @override
  ConsumerState<AQProfessionalsScreen> createState() => _AQProfessionalsScreenState();
}

class _AQProfessionalsScreenState extends ConsumerState<AQProfessionalsScreen> {
  late final _ctl = TextEditingController(text: widget.query ?? '');
  late BusinessCategory? _cat = BusinessCategory.values.where((c) => c.name == widget.category).firstOrNull;
  bool _verified = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final async = ref.watch(businessesProvider);
    final q = _ctl.text.trim().toLowerCase();
    // The page says what was asked for: Maintenance is not the generic professionals list.
    final maint = _cat == BusinessCategory.maintenance;
    return AQViewingScaffold(
      title: maint ? f.t('pro.maint.t') : (_cat == null ? f.t('pro.title') : f.t('bcat.${_cat!.name}')),
      subtitle: maint ? f.t('pro.maint.s') : f.t('pro.sub'),
      backLabel: f.t('common.back'),
      onBack: () => aqBack(context, '/app/explore'),
      children: [
        AQQueryField(controller: _ctl, hint: f.t('pro.search'), onChanged: (_) => setState(() {}), onSubmitted: (_) => setState(() {})),
        const SizedBox(height: AQSpacing.x4),
        Wrap(spacing: AQSpacing.x2, runSpacing: AQSpacing.x2, children: [
          AQChoicePill(label: f.t('flt.all'), selected: _cat == null, onTap: () => setState(() => _cat = null)),
          for (final k in BusinessCategory.values) AQChoicePill(label: f.t('bcat.${k.name}'), selected: _cat == k, onTap: () => setState(() => _cat = _cat == k ? null : k)),
        ]),
        const SizedBox(height: AQSpacing.x3),
        AQCheckToggle(label: f.t('pro.verified'), value: _verified, onChanged: (v) => setState(() => _verified = v)),
        const SizedBox(height: AQSpacing.x4),
        async.when(
          loading: () => const Column(children: [AQSkeletonBox(height: 140), SizedBox(height: AQSpacing.x3), AQSkeletonBox(height: 140)]),
          error: (_, _) => AQErrorBanner(text: f.t('pro.loadError'), action: AQTextButton(label: f.t('common.retry'), color: c.accent, onPressed: () => ref.invalidate(businessesProvider))),
          data: (all) {
            final shown = [
              for (final b in all)
                if ((q.isEmpty || '${b.name} ${b.description} ${b.categories.map((x) => x.label).join(' ')}'.toLowerCase().contains(q)) && (_cat == null || b.categories.contains(_cat)) && (!_verified || b.verification.isVerified)) b,
            ];
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(padding: const EdgeInsets.only(bottom: AQSpacing.x3), child: Semantics(liveRegion: true, child: Text(f.t('pro.count', {'n': VFmt.n(context, shown.length)}), style: AQTypography.of(context, AQText.titleMedium)))),
              if (shown.isEmpty)
                Column(children: [AQNoticeLine(text: f.t('pro.empty')), if (_cat != null || _verified || q.isNotEmpty) AQSecondaryButton(label: f.t('flt.clear'), trailingChevron: false, onPressed: () => setState(() {
                          _cat = null;
                          _verified = false;
                          _ctl.clear();
                        }))])
              else
                for (final b in shown) Padding(padding: const EdgeInsets.only(bottom: AQSpacing.x3), child: _ProCard(business: b)),
            ]);
          },
        ),
      ],
    );
  }
}

class _ProCard extends StatelessWidget {
  final Business business;
  const _ProCard({required this.business});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final f = FlowStrings.of(context);
    final b = business;
    final w = aqLargeText(context) ? 96.0 : 124.0;
    final cats = b.categories.map((k) => f.t('bcat.${k.name}')).join(' · ');
    final photo = b.galleryUrls.isNotEmpty ? b.galleryUrls.first : b.logoUrl;
    final rating = b.rating == null ? null : '${b.rating!.toStringAsFixed(1)} · ${f.t('pro.reviews', {'n': VFmt.n(context, b.reviewCount ?? 0)})}';
    return Semantics(
      button: true,
      focusable: true,
      onFocus: () {},
      label: '${b.name}, $cats, ${b.locationLabel}${b.verification.isVerified ? ', ${f.t('disc.verified')}' : ''}${rating == null ? '' : ', $rating'}',
      excludeSemantics: true,
      onTap: () => context.push('/business/${b.id}'),
      child: AQPressable(
        onTap: () => context.push('/business/${b.id}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AQRadius.large),
          child: DecoratedBox(
            decoration: BoxDecoration(color: c.surfaceRaised, border: Border.all(color: c.hairline), borderRadius: BorderRadius.circular(AQRadius.large)),
            child: Stack(children: [
              Padding(
                padding: EdgeInsetsDirectional.only(start: w),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 136),
                  child: Padding(
                    padding: const EdgeInsets.all(AQSpacing.x3),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (b.verification.isVerified)
                        Row(mainAxisSize: MainAxisSize.min, children: [AQIcon('verified', size: 14, color: c.accent), const SizedBox(width: 4), Flexible(child: Text(f.t('disc.verified'), style: AQTypography.of(context, AQText.labelSmall, color: c.accentDeep)))]),
                      Text(VFmt.iso(b.name), style: AQTypography.of(context, AQText.headlineSmall)),
                      const SizedBox(height: 2),
                      Text(cats, style: AQTypography.of(context, AQText.bodySmall, soft: true)),
                      const SizedBox(height: AQSpacing.x1),
                      Row(children: [AQIcon('pin', size: 14, color: c.accent), const SizedBox(width: 4), Flexible(child: Text(VFmt.iso(b.locationLabel), style: AQTypography.of(context, AQText.bodySmall, soft: true)))]),
                      if (rating != null) ...[
                        const SizedBox(height: AQSpacing.x1),
                        Row(children: [AQIcon('star-fill', size: 14, color: c.warning), const SizedBox(width: 4), Flexible(child: Text(rating, style: AQTypography.of(context, AQText.labelMedium)))]),
                      ],
                    ]),
                  ),
                ),
              ),
              PositionedDirectional(start: 0, top: 0, bottom: 0, width: w, child: ExcludeSemantics(child: photo == null ? ColoredBox(color: c.surfaceSelected) : aqImg(photo, cacheWidth: 400))),
            ]),
          ),
        ),
      ),
    );
  }
}
