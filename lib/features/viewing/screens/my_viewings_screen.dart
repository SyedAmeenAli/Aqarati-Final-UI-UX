import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/aq/aq_forms.dart';
import '../../../core/aq/aq_primitives.dart';
import '../../../core/aq/aq_tokens.dart';
import '../../../core/aq/aq_typography.dart';
import '../../../core/localization/viewing_strings.dart';
import '../data/viewing_repository.dart';
import '../domain/viewing_models.dart';
import '../domain/viewing_presentation.dart';
import '../widgets/viewing_components.dart';
import '../widgets/viewing_format.dart';
import 'viewing_kit.dart';

/// Screens 50 and 51: a personal appointment archive. Lives in the Activity tab, so it
/// has no back button; the glass nav provides the way out.
class MyViewingsScreen extends ConsumerStatefulWidget {
  const MyViewingsScreen({super.key});
  @override
  ConsumerState<MyViewingsScreen> createState() => _MyViewingsScreenState();
}

class _MyViewingsScreenState extends ConsumerState<MyViewingsScreen> {
  ViewingFilter _filter = ViewingFilter.all;

  String _group(DateTime today, Viewing x) {
    final d = DateTime(x.slot.start.year, x.slot.start.month, x.slot.start.day);
    final diff = d.difference(today).inDays;
    if (diff < 0) return 'vw.g.earlier';
    if (diff == 0) return 'vw.g.today';
    if (diff == 1) return 'vw.g.tomorrow';
    if (diff <= 7) return 'vw.g.thisWeek';
    return 'vw.g.later';
  }

  @override
  Widget build(BuildContext context) {
    final v = ViewingStrings.of(context);
    final c = AQColors.of(context);
    final async = ref.watch(viewingsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Non-list states render as one block; the list itself is built lazily by a sliver.
    final rows = <Widget Function()>[];
    Widget? block;
    async.when(
      loading: () => block = const Column(children: [AQViewingSkeleton(height: 108), AQViewingSkeleton(height: 108), AQViewingSkeleton(height: 108)]),
      error: (_, _) => block = AQErrorBanner(text: v.t('vw.my.error'), action: AQTextButton(label: v.t('vw.retry'), color: c.accent, onPressed: () => ref.invalidate(viewingsProvider))),
      data: (all) {
        if (all.isEmpty) {
          block = Padding(
            padding: const EdgeInsets.only(top: AQSpacing.x4),
            child: AQEmptyViewingState(
              title: v.t('vw.empty.title'),
              body: v.t('vw.empty.sub'),
              action: AQPrimaryButton(label: v.t('vw.browse'), leadingIcon: 'search', trailingChevron: false, onPressed: () => context.push('/search')),
            ),
          );
          return;
        }
        final shown = all.where(_filter.matches).toList()..sort((a, b) => _filter == ViewingFilter.past || _filter == ViewingFilter.cancelled ? b.slot.start.compareTo(a.slot.start) : a.slot.start.compareTo(b.slot.start));
        if (shown.isEmpty) {
          final key = switch (_filter) { ViewingFilter.upcoming => 'vw.empty.upcoming', ViewingFilter.past => 'vw.empty.past', ViewingFilter.cancelled => 'vw.empty.cancelled', ViewingFilter.all => 'vw.empty.title' };
          block = Padding(padding: const EdgeInsets.only(top: AQSpacing.x4), child: AQNoticeCard(icon: 'calendar', title: v.t(key), body: ''));
          return;
        }
        final grouped = shown.length > 3 && _filter != ViewingFilter.cancelled;
        String? last;
        for (final x in shown) {
          final g = _group(today, x);
          if (grouped && g != last) {
            final first = last == null;
            rows.add(() => Padding(padding: EdgeInsets.only(top: first ? 0 : AQSpacing.x4, bottom: AQSpacing.x2), child: Semantics(header: true, child: Text(v.t(g), style: AQTypography.of(context, AQText.labelMedium, color: c.inkFaint)))));
            last = g;
          }
          rows.add(() => Padding(padding: const EdgeInsets.only(bottom: AQSpacing.x3), child: _Row(viewing: x)));
        }
      },
    );

    final counts = async.valueOrNull;
    int count(ViewingFilter f) => counts == null ? 0 : counts.where(f.matches).length;

    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AQSpacing.maxContent + AQSpacing.gutter * 2),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AQSpacing.gutter, AQSpacing.x6, AQSpacing.gutter, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Semantics(header: true, child: Text(v.t('vw.my.title'), style: AQTypography.of(context, AQText.displaySmall))),
                    const SizedBox(height: AQSpacing.x2),
                    Text(v.t('vw.my.sub'), style: AQTypography.of(context, AQText.bodyMedium, soft: true)),
                    const SizedBox(height: AQSpacing.x5),
                    Wrap(spacing: AQSpacing.x2, runSpacing: AQSpacing.x2, children: [
                      for (final f in ViewingFilter.values) _FilterChip(label: '${v.t('vw.f.${f.name}')} (${VFmt.n(context, count(f))})', selected: f == _filter, onTap: () => setState(() => _filter = f)),
                    ]),
                    const SizedBox(height: AQSpacing.x4),
                    if (block != null) AnimatedSwitcher(duration: AQMotion.scaled(context, AQMotion.standard), child: KeyedSubtree(key: ValueKey('${_filter.name}-${async.isLoading}-${async.hasError}'), child: block!)),
                  ]),
                ),
              ),
              if (rows.isNotEmpty) SliverPadding(padding: const EdgeInsets.symmetric(horizontal: AQSpacing.gutter), sliver: SliverList.builder(itemCount: rows.length, itemBuilder: (context, i) => rows[i]())),
              const SliverToBoxAdapter(child: SizedBox(height: 128)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

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

class _Row extends ConsumerWidget {
  final Viewing viewing;
  const _Row({required this.viewing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final property = ref.watch(viewingPropertyProvider(viewing.propertyId)).valueOrNull;
    return AQMyViewingRow(viewing: viewing, property: property, onTap: () => context.push('/viewings/${viewing.id}'));
  }
}
