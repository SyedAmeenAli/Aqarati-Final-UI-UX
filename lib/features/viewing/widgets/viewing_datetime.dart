import 'package:flutter/material.dart';
import '../../../core/aq/aq_primitives.dart';
import '../../../core/aq/aq_tokens.dart';
import '../../../core/aq/aq_typography.dart';
import '../../../core/localization/viewing_strings.dart';
import '../domain/viewing_models.dart';
import 'viewing_format.dart';

/// One selectable day. Availability is shown by marker AND text, never colour alone.
class AQViewingDateChip extends StatelessWidget {
  final AvailabilityDay day;
  final bool selected;
  final bool showCount;
  final VoidCallback? onTap;
  const AQViewingDateChip({super.key, required this.day, required this.selected, this.onTap, this.showCount = false});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final v = ViewingStrings.of(context);
    final enabled = day.bookable;
    final fg = selected ? c.onAccent : (enabled ? c.ink : c.inkFaint);
    final soft = selected ? c.onAccent.withValues(alpha: 0.85) : (enabled ? c.inkSoft : c.inkFaint);
    final state = !enabled ? v.t('vw.legend.unavailable') : (day.load == DayLoad.limited ? v.t('vw.legend.limited') : v.t('vw.legend.available'));
    Widget marker() {
      if (!enabled) return Text('–', style: AQTypography.of(context, AQText.labelMedium, color: soft));
      if (showCount) {
        return Text(day.freeCount == 1 ? v.t('vw.slot1') : v.t('vw.slots', {'n': VFmt.n(context, day.freeCount)}), style: AQTypography.of(context, AQText.bodySmall, color: soft).copyWith(fontSize: 11));
      }
      return Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? c.onAccent : (day.load == DayLoad.limited ? c.warning : c.success)));
    }

    return Semantics(
      button: true,
      focusable: true,
      onFocus: () {},
      enabled: enabled,
      selected: selected,
      label: v.t('vw.a11y.date', {'date': VFmt.fullDate(context, day.date), 'state': selected ? '$state, ${v.t('vw.a11y.selected')}' : state}),
      excludeSemantics: true,
      onTap: enabled ? () => onTap?.call() : null,
      child: AQPressable(
        onTap: enabled
            ? () {
                AQHaptics.selection();
                onTap?.call();
              }
            : null,
        child: AnimatedScale(
          scale: selected ? 1.03 : 1,
          duration: AQMotion.scaled(context, AQMotion.fast),
          curve: AQMotion.spring,
          child: AnimatedContainer(
            duration: AQMotion.scaled(context, AQMotion.fast),
            curve: AQMotion.standardCurve,
            constraints: BoxConstraints(minWidth: showCount ? 66 : 60, minHeight: AQControl.tap + 24),
            padding: const EdgeInsets.symmetric(horizontal: AQSpacing.x2, vertical: AQSpacing.x3),
            decoration: BoxDecoration(
              color: selected ? c.accent : (enabled ? c.surface : c.ink.withValues(alpha: c.isDark ? 0.06 : 0.04)),
              borderRadius: BorderRadius.circular(AQRadius.medium),
              boxShadow: selected ? AQElevation.subtle : null,
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(VFmt.weekdayShort(context, day.date), style: AQTypography.of(context, AQText.bodySmall, color: soft)),
              const SizedBox(height: 2),
              Text(VFmt.dayNum(context, day.date), style: AQTypography.of(context, AQText.titleLarge, color: fg)),
              Text(VFmt.monthShort(context, day.date), style: AQTypography.of(context, AQText.bodySmall, color: soft)),
              const SizedBox(height: AQSpacing.x2),
              marker(),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Horizontal date rail with month context. [showNav] adds earlier/later arrows.
class AQViewingDatePicker extends StatefulWidget {
  final List<AvailabilityDay> days;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  final bool showCount;
  final bool showNav;
  const AQViewingDatePicker({super.key, required this.days, required this.selected, required this.onSelect, this.showCount = false, this.showNav = false});

  @override
  State<AQViewingDatePicker> createState() => _AQViewingDatePickerState();
}

class _AQViewingDatePickerState extends State<AQViewingDatePicker> {
  late final ScrollController _scroll;

  @override
  void initState() {
    super.initState();
    final i = widget.selected == null ? 0 : widget.days.indexWhere((d) => _same(d.date, widget.selected!));
    _scroll = ScrollController(initialScrollOffset: i <= 1 ? 0 : (i - 1) * 70.0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _same(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _nudge(double dx) {
    if (!_scroll.hasClients) return;
    _scroll.animateTo((_scroll.offset + dx).clamp(0, _scroll.position.maxScrollExtent), duration: AQMotion.scaled(context, AQMotion.standard), curve: AQMotion.standardCurve);
  }

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final v = ViewingStrings.of(context);
    final month = widget.selected ?? (widget.days.isEmpty ? DateTime.now() : widget.days.first.date);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text(VFmt.monthYear(context, month), style: AQTypography.of(context, AQText.titleSmall, color: c.accentDeep))),
        if (widget.showNav) ...[
          AQIconButton(icon: 'chevron-left', semanticsLabel: v.t('vw.prevWeek'), onPressed: () => _nudge(rtl ? 280 : -280)),
          AQIconButton(icon: 'chevron-right', semanticsLabel: v.t('vw.nextWeek'), onPressed: () => _nudge(rtl ? -280 : 280)),
        ],
      ]),
      const SizedBox(height: AQSpacing.x2),
      SingleChildScrollView(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final d in widget.days) ...[
              AQViewingDateChip(day: d, selected: widget.selected != null && _same(d.date, widget.selected!), showCount: widget.showCount, onTap: () => widget.onSelect(d.date)),
              const SizedBox(width: AQSpacing.x2),
            ],
          ]),
        ),
      ),
    ]);
  }
}

class AQViewingAvailabilityLegend extends StatelessWidget {
  const AQViewingAvailabilityLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final v = ViewingStrings.of(context);
    Widget item(Widget mark, String text) => Row(mainAxisSize: MainAxisSize.min, children: [mark, const SizedBox(width: 6), Text(text, style: AQTypography.of(context, AQText.bodySmall, soft: true))]);
    Widget dot(Color col) => Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: col));
    return Wrap(spacing: AQSpacing.x4, runSpacing: AQSpacing.x1, children: [
      item(dot(c.success), v.t('vw.legend.available')),
      item(dot(c.warning), v.t('vw.legend.limited')),
      item(Text('–', style: AQTypography.of(context, AQText.labelMedium, color: c.inkFaint)), v.t('vw.legend.unavailable')),
    ]);
  }
}

/// A single time. [detailed] adds a state line and a check when selected.
class AQViewingTimeSlot extends StatelessWidget {
  final SlotInfo info;
  final bool selected;
  final bool detailed;
  final VoidCallback? onTap;
  const AQViewingTimeSlot({super.key, required this.info, required this.selected, this.detailed = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final v = ViewingStrings.of(context);
    final st = info.state;
    final enabled = st != SlotState.unavailable;
    final fg = selected ? c.onAccent : (enabled ? c.ink : c.inkFaint);
    final stateText = switch (st) { SlotState.available => v.t('vw.legend.available'), SlotState.limited => v.t('vw.legend.limited'), SlotState.unavailable => v.t('vw.legend.unavailable') };
    final dot = st == SlotState.limited ? c.warning : c.success;
    final time = VFmt.time(context, info.slot.start);
    return Semantics(
      button: true,
      focusable: true,
      onFocus: () {},
      enabled: enabled,
      selected: selected,
      label: v.t('vw.a11y.slot', {'time': time, 'state': selected ? '$stateText, ${v.t('vw.a11y.selected')}' : stateText}),
      excludeSemantics: true,
      onTap: enabled ? () => onTap?.call() : null,
      child: AQPressable(
        onTap: enabled
            ? () {
                AQHaptics.selection();
                onTap?.call();
              }
            : null,
        child: AnimatedScale(
          scale: selected ? 1.02 : 1,
          duration: AQMotion.scaled(context, AQMotion.fast),
          curve: AQMotion.spring,
          child: AnimatedContainer(
            duration: AQMotion.scaled(context, AQMotion.fast),
            curve: AQMotion.standardCurve,
            constraints: const BoxConstraints(minHeight: AQControl.tap + 4),
            padding: EdgeInsets.symmetric(horizontal: aqLargeText(context) ? AQSpacing.x2 : AQSpacing.x3, vertical: AQSpacing.x2 + 2),
            decoration: BoxDecoration(
              color: selected ? c.accent : (enabled ? c.surface : c.ink.withValues(alpha: c.isDark ? 0.06 : 0.04)),
              borderRadius: BorderRadius.circular(AQRadius.medium),
              boxShadow: selected ? AQElevation.subtle : null,
            ),
            child: detailed
                ? Row(children: [
                    if (enabled) Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? c.onAccent : dot)) else Text('–', style: AQTypography.of(context, AQText.labelMedium, color: fg)),
                    const SizedBox(width: AQSpacing.x2),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(time, style: AQTypography.of(context, AQText.titleSmall, color: fg)),
                        Text(stateText, style: AQTypography.of(context, AQText.bodySmall, color: selected ? c.onAccent.withValues(alpha: 0.85) : (enabled ? (st == SlotState.limited ? c.warning : c.success) : c.inkFaint)).copyWith(fontSize: 12)),
                      ]),
                    ),
                    if (selected) AQIcon('check', size: 18, color: c.onAccent),
                  ])
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(time, textAlign: TextAlign.center, style: AQTypography.of(context, AQText.titleSmall, color: fg)),
                    const SizedBox(height: 4),
                    if (enabled) Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? c.onAccent : dot)) else Text('–', style: AQTypography.of(context, AQText.labelMedium, color: c.inkFaint)),
                  ]),
          ),
        ),
      ),
    );
  }
}

/// Lays slots out in 3 columns, 2 at large text, so times never clip.
class AQViewingSlotGrid extends StatelessWidget {
  final List<SlotInfo> slots;
  final ViewingSlot? selected;
  final ValueChanged<ViewingSlot> onSelect;
  final bool detailed;
  const AQViewingSlotGrid({super.key, required this.slots, required this.selected, required this.onSelect, this.detailed = false});

  @override
  Widget build(BuildContext context) {
    final large = aqLargeText(context);
    return LayoutBuilder(builder: (context, box) {
      final cols = (large || (detailed && box.maxWidth < 340)) ? 2 : 3;
      const gap = AQSpacing.x2;
      final w = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: gap, children: [
        for (final s in slots) SizedBox(width: w, child: AQViewingTimeSlot(info: s, selected: s.slot == selected, detailed: detailed, onTap: () => onSelect(s.slot))),
      ]);
    });
  }
}

String periodIcon(ViewingPeriod p) => switch (p) { ViewingPeriod.morning => 'sunrise', ViewingPeriod.afternoon => 'sun', ViewingPeriod.evening => 'moon' };

String periodKey(ViewingPeriod p) => switch (p) { ViewingPeriod.morning => 'vw.period.morning', ViewingPeriod.afternoon => 'vw.period.afternoon', ViewingPeriod.evening => 'vw.period.evening' };

/// Period range text derived from the slots actually offered (never hard-coded).
String periodRange(BuildContext context, List<SlotInfo> slots) {
  if (slots.isEmpty) return '';
  return '${VFmt.hour(context, slots.first.slot.start)} – ${VFmt.hour(context, slots.last.slot.end)}';
}
