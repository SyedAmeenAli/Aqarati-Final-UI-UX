import 'dart:ui' as ui;
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'aq_primitives.dart';
import 'aq_tokens.dart';
import 'aq_typography.dart';

/// Full-bleed photograph with smooth tonal washes (never a cropped rectangle).
/// [quiet] lowers the photograph for technical steps where reading matters.
class AQBackdrop extends StatelessWidget {
  final String asset;
  final Alignment alignment;
  final bool quiet;
  const AQBackdrop({super.key, required this.asset, this.alignment = Alignment.bottomCenter, this.quiet = false});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final bg = c.background;
    final stops = quiet ? const [0.0, 0.4, 0.75, 1.0] : const [0.0, 0.42, 0.60, 0.70, 0.74, 0.84, 1.0];
    final alphas = quiet ? const [0.8, 0.66, 0.66, 0.84] : const [0.97, 0.94, 0.70, 0.0, 0.0, 0.78, 0.94];
    return RepaintBoundary(
      child: Stack(fit: StackFit.expand, children: [
        ColoredBox(color: bg),
        Opacity(
          opacity: quiet ? (c.isDark ? 0.4 : 0.5) : (c.isDark ? 0.55 : 1),
          child: Image.asset(asset, fit: BoxFit.cover, alignment: alignment, filterQuality: FilterQuality.medium, errorBuilder: (_, _, _) => const SizedBox.shrink()),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [for (final a in alphas) bg.withValues(alpha: a)], stops: stops),
          ),
        ),
      ]),
    );
  }
}

/// Fade + small rise driven by a shared controller (staggered by interval).
class AQReveal extends StatelessWidget {
  final Animation<double> animation;
  final double begin, end, dy;
  final Widget child;
  const AQReveal({super.key, required this.animation, required this.begin, required this.end, this.dy = 10, required this.child});

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: animation, curve: Interval(begin, end, curve: AQMotion.emphasized));
    return AnimatedBuilder(
      animation: a,
      builder: (context, c) => Opacity(opacity: a.value, child: Transform.translate(offset: Offset(0, (1 - a.value) * dy), child: c)),
      child: child,
    );
  }
}

/// Top bar: back (optional) and a quiet text action. 48 pt targets.
class AQTopBar extends StatelessWidget {
  final VoidCallback? onBack;
  final String? backLabel;
  final String? actionLabel;
  final String? actionSemantics;
  final VoidCallback? onAction;
  const AQTopBar({super.key, this.onBack, this.backLabel, this.actionLabel, this.actionSemantics, this.onAction});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AQControl.tap,
      child: Row(children: [
        if (onBack != null) AQIconButton(icon: 'chevron-left', semanticsLabel: backLabel ?? 'Back', onPressed: onBack) else const SizedBox(width: AQControl.tap),
        const Spacer(),
        if (actionLabel != null)
          Semantics(
            button: true,
            label: actionSemantics ?? actionLabel,
            excludeSemantics: true,
            child: AQTextButton(label: actionLabel!, trailingIcon: 'chevron-right', onPressed: onAction),
          ),
      ]),
    );
  }
}

/// Role / choice tile. Tonal at rest; selection = accent ring + warm tint + icon lift.
class AQChoiceTile extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  const AQChoiceTile({super.key, required this.icon, required this.title, required this.description, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      hint: description,
      excludeSemantics: true,
      child: AQPressable(
        onTap: () {
          AQHaptics.selection();
          onTap();
        },
        child: AnimatedContainer(
          duration: AQMotion.scaled(context, AQMotion.fast),
          curve: AQMotion.standardCurve,
          padding: const EdgeInsetsDirectional.fromSTEB(AQSpacing.x4, AQSpacing.x4, AQSpacing.x3, AQSpacing.x4),
          decoration: BoxDecoration(
            color: selected ? c.surfaceSelected : c.surface,
            borderRadius: BorderRadius.circular(AQRadius.medium),
            // Border only carries the selection signal (not decoration).
            border: Border.all(color: selected ? c.accent : Colors.transparent, width: 1.5),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                AnimatedSlide(
                  duration: AQMotion.scaled(context, AQMotion.fast),
                  curve: AQMotion.standardCurve,
                  offset: Offset(0, selected ? -0.08 : 0),
                  child: AQIcon(icon, size: AQIconSize.role, color: selected ? c.accentDeep : c.accent),
                ),
                const SizedBox(height: AQSpacing.x3),
                Text(title, style: AQTypography.of(context, AQText.titleSmall)),
                const SizedBox(height: AQSpacing.x1),
                Text(description, style: AQTypography.of(context, AQText.bodySmall, soft: true), maxLines: 3),
              ]),
            ),
            AnimatedSlide(
              duration: AQMotion.scaled(context, AQMotion.fast),
              offset: Offset(selected ? (Directionality.of(context) == TextDirection.rtl ? -0.2 : 0.2) : 0, 0),
              child: AQIcon('chevron-right', size: AQIconSize.small, directional: true, color: selected ? c.accent : c.inkFaint.withValues(alpha: 0.6)),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Bottom sheet: large top radius, drag handle, safe area, keyboard inset, tonal surface.
Future<T?> showAQSheet<T>(BuildContext context, {required WidgetBuilder builder, bool dismissible = true}) {
  final c = AQColors.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    sheetAnimationStyle: AnimationStyle(duration: AQMotion.slow, reverseDuration: AQMotion.standard, curve: AQMotion.spring),
    builder: (sheetContext) {
      final bottom = MediaQuery.of(sheetContext).viewInsets.bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: const BorderRadius.vertical(top: Radius.circular(AQRadius.large)), boxShadow: AQElevation.modal),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: AQSpacing.x3),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: c.hairline, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: AQSpacing.x2),
              builder(sheetContext),
              const SizedBox(height: AQSpacing.x3),
            ]),
          ),
        ),
      );
    },
  );
}

/// Selectable row for sheets (language, filters, contextual choices).
class AQSheetRow extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  const AQSheetRow({super.key, required this.title, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      excludeSemantics: true,
      child: AQPressable(
        onTap: () {
          AQHaptics.selection();
          onTap();
        },
        pressedScale: 0.99,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: AQSpacing.x6),
          child: Row(children: [
            Expanded(child: Text(title, style: AQTypography.of(context, selected ? AQText.titleMedium : AQText.bodyLarge))),
            if (selected) AQIcon('check', size: AQIconSize.medium, color: c.accent),
          ]),
        ),
      ),
    );
  }
}

/// Screen transitions. Families: [AQRoute.forward] (shared axis: fade + small rise + very slight scale),
/// [AQRoute.fade] (calm cross-fade for same-level swaps).
class AQRoute {
  AQRoute._();

  static Page<T> forward<T>({required LocalKey key, required Widget child}) => CustomTransitionPage<T>(
        key: key,
        child: child,
        transitionDuration: AQMotion.page,
        reverseTransitionDuration: AQMotion.standard,
        transitionsBuilder: (context, animation, secondary, child) {
          if (AQMotion.reduced(context)) return FadeTransition(opacity: animation, child: child);
          final inCurve = CurvedAnimation(parent: animation, curve: AQMotion.emphasized);
          final outCurve = CurvedAnimation(parent: secondary, curve: AQMotion.emphasized);
          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: animation, curve: const Interval(0, 0.7))),
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(inCurve),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.992, end: 1).animate(inCurve),
                // The page underneath eases back very slightly while a new one arrives.
                child: FadeTransition(opacity: Tween<double>(begin: 1, end: 0.0).animate(outCurve), child: child),
              ),
            ),
          );
        },
      );

  static Page<T> fade<T>({required LocalKey key, required Widget child}) => CustomTransitionPage<T>(
        key: key,
        child: child,
        transitionDuration: AQMotion.standard,
        transitionsBuilder: (context, animation, secondary, child) => FadeTransition(opacity: CurvedAnimation(parent: animation, curve: AQMotion.standardCurve), child: child),
      );
}

/// Floating glass navigation (Home / Explore / Activity / Account): the only glass in the app.
/// Minimises while scrolling down and expands on scroll up or interaction.
class AQNavController extends ChangeNotifier {
  bool _compact = false;
  bool get compact => _compact;
  void setCompact(bool v) {
    if (v != _compact) {
      _compact = v;
      notifyListeners();
    }
  }

  /// Feed from a ScrollNotification listener.
  bool onScroll(ScrollNotification n) {
    if (n is UserScrollNotification) {
      if (n.direction == ScrollDirection.reverse) setCompact(true);
      if (n.direction == ScrollDirection.forward) setCompact(false);
    }
    return false;
  }
}

class AQNavItem {
  final String icon, label;
  const AQNavItem(this.icon, this.label);
}

class AQGlassNav extends StatelessWidget {
  final List<AQNavItem> items;
  final int index;
  final ValueChanged<int> onSelected;
  final AQNavController controller;
  const AQGlassNav({super.key, required this.items, required this.index, required this.onSelected, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final compact = controller.compact;
        final tint = c.isDark ? const Color(0xAA2A231D) : const Color(0xB3F7EFE4);
        return SafeArea(
          minimum: const EdgeInsets.only(bottom: AQSpacing.x3),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: compact ? () => controller.setCompact(false) : null,
              child: AnimatedContainer(
                duration: AQMotion.scaled(context, AQMotion.standard),
                curve: AQMotion.spring,
                margin: const EdgeInsets.symmetric(horizontal: AQSpacing.x4),
                height: compact ? 52 : 68,
                constraints: BoxConstraints(maxWidth: compact ? 232 : 420),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(compact ? 26 : AQRadius.large),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: tint, border: Border.all(color: c.hairline), borderRadius: BorderRadius.circular(compact ? 26 : AQRadius.large)),
                      child: Row(children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: Semantics(
                              button: true,
                              selected: i == index,
                              label: items[i].label,
                              excludeSemantics: true,
                              child: AQPressable(
                                onTap: () {
                                  AQHaptics.selection();
                                  onSelected(i);
                                },
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  AQIcon(items[i].icon, size: AQIconSize.medium, color: i == index ? c.accent : c.inkSoft),
                                  if (!compact) ...[
                                    const SizedBox(height: 3),
                                    Text(items[i].label, style: AQTypography.of(context, AQText.labelMedium, color: i == index ? c.accent : c.inkSoft).copyWith(fontSize: 11)),
                                  ],
                                ]),
                              ),
                            ),
                          ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Convenience used by screens: pop if possible, else go to [fallback].
void aqBack(BuildContext context, String fallback) => context.canPop() ? context.pop() : context.go(fallback);
