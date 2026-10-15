import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/aq/aq_documents.dart' show AQStatusBadge;
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_scene.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/domain/account_models.dart';
import '../../core/localization/flow_strings.dart';
import '../devbuild/db_widgets.dart' show DbFit, DbIcon;
import '../entry/widgets/entry_common.dart' show MasterLogo;
import '../workspace/aq_home.dart' show aqImg;
import 'role_home_model.dart';

/// Role accents stay inside the AQARATI warm family. They tint small details only (rules,
/// selected segments, chips); surfaces, text and the logo keep the real theme tokens.
Color roleAccent(BuildContext context, HomeRole role) {
  final dark = AQColors.of(context).isDark;
  return switch (role) {
    HomeRole.agent => dark ? const Color(0xFFD0A470) : const Color(0xFF5A3E2B),
    HomeRole.construction => dark ? const Color(0xFFD0925F) : const Color(0xFF9A5B34),
    HomeRole.developer => dark ? const Color(0xFFD9B56A) : const Color(0xFF8F6F2F),
    HomeRole.architecture => dark ? const Color(0xFFB9A592) : const Color(0xFF7D6858),
    HomeRole.interiorExterior => dark ? const Color(0xFFB3B57F) : const Color(0xFF6F7350),
    HomeRole.buyer => AQColors.of(context).accent,
  };
}

/// The scrolling frame shared by the role homes. Only the frame is shared: every home chooses
/// its own sections, order, density and imagery.
class RoleHomePage extends StatelessWidget {
  final List<Widget> children;
  const RoleHomePage({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AQSpacing.maxContent + AQSpacing.gutter * 2),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AQSpacing.gutter, AQSpacing.x2, AQSpacing.gutter, 128),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
          ),
        ),
      ),
    );
  }
}

/// First-entry fade and rise. Plays once per mounted screen, staggers by [index] (capped at 5),
/// and is skipped when the system asks for reduced motion.
class RoleReveal extends StatefulWidget {
  final int index;
  final Widget child;
  const RoleReveal({super.key, this.index = 0, required this.child});
  @override
  State<RoleReveal> createState() => _RoleRevealState();
}

class _RoleRevealState extends State<RoleReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final double _begin;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final delay = 45 * widget.index.clamp(0, 5);
    final total = 240 + delay;
    _begin = delay / total;
    _c = AnimationController(vsync: this, duration: Duration(milliseconds: total));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AQMotion.reduced(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AQReveal(animation: _c, begin: _begin, end: 1, dy: 8, child: widget.child);
}

/// Exact master logo, top of every role home.
class RoleHeader extends StatelessWidget {
  final Widget? trailing;
  const RoleHeader({super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AQSpacing.x4),
        child: Row(children: [const MasterLogo(width: 92), const Spacer(), ?trailing]),
      );
}

class RoleEyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const RoleEyebrow(this.text, {super.key, required this.color});
  @override
  Widget build(BuildContext context) => Text(text, style: AQTypography.of(context, AQText.labelSmall, color: color).copyWith(letterSpacing: 1.6));
}

/// Section heading with an optional action. 48 pt target for the action.
class RoleSection extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Color? accent;
  const RoleSection(this.title, {super.key, this.action, this.onAction, this.accent});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AQSpacing.x6, bottom: AQSpacing.x2),
      child: LayoutBuilder(
        builder: (context, box) => Row(children: [
          Expanded(child: Semantics(header: true, child: Text(title, style: AQTypography.of(context, AQText.headlineSmall)))),
          if (action != null && onAction != null)
            // The action never takes more than just over half the row; a long label scales down.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth * 0.55),
              child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerEnd, child: AQTextButton(label: action!, trailingIcon: 'chevron-right', color: accent ?? c.accentDeep, onPressed: onAction)),
            ),
        ]),
      ),
    );
  }
}

/// Buyer / Agent workspace switch. The thumb animates, the state change is real: the owner
/// updates the active workspace and the home beneath it changes. Reduced motion removes travel.
class RoleWorkspaceSwitcher extends StatelessWidget {
  final HomeWorkspace selected;
  final ValueChanged<HomeWorkspace> onChanged;
  const RoleWorkspaceSwitcher({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final f = FlowStrings.of(context);
    final accent = roleAccent(context, HomeRole.agent);
    final agent = selected == HomeWorkspace.agent;
    Widget seg(HomeWorkspace w, String label) {
      final on = selected == w;
      return Expanded(
        child: Semantics(
          button: true,
          selected: on,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: on
                ? null
                : () {
                    AQHaptics.selection();
                    onChanged(w);
                  },
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: AQSpacing.x2, vertical: AQSpacing.x2),
              alignment: Alignment.center,
              child: AnimatedDefaultTextStyle(
                duration: AQMotion.scaled(context, const Duration(milliseconds: 200)),
                style: AQTypography.of(context, AQText.labelLarge, color: on ? (c.isDark ? c.background : Colors.white) : c.inkSoft),
                child: Text(label, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: f.t('rh.switch.label'),
      hint: f.t('rh.switch.hint'),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: c.surfaceSelected, borderRadius: BorderRadius.circular(AQRadius.medium), border: Border.all(color: c.hairline)),
        child: Stack(children: [
          Positioned.fill(
            child: AnimatedAlign(
              duration: AQMotion.scaled(context, const Duration(milliseconds: 220)),
              curve: Curves.easeInOut,
              alignment: agent ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: DecoratedBox(decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(AQRadius.medium - 4))),
              ),
            ),
          ),
          IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [seg(HomeWorkspace.buyer, f.t('rh.switch.buyer')), seg(HomeWorkspace.agent, f.t('rh.switch.agent'))])),
        ]),
      ),
    );
  }
}

/// Shown on the buyer home when the person has a business or agent application that is not
/// approved. Reads the real grant; no business tool is exposed.
class RoleStatusBanner extends StatelessWidget {
  final GrantState grant;
  final ReviewStage? stage;
  const RoleStatusBanner({super.key, required this.grant, this.stage});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final f = FlowStrings.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AQSpacing.x4),
      padding: const EdgeInsets.all(AQSpacing.x4),
      decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(AQRadius.medium), border: Border.all(color: c.hairline)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Align(alignment: AlignmentDirectional.centerStart, child: DbFit(AQStatusBadge(grant: grant, stage: stage))),
        const SizedBox(height: AQSpacing.x2),
        Semantics(header: true, child: Text(f.t('rh.banner.title'), style: AQTypography.of(context, AQText.titleMedium))),
        const SizedBox(height: 2),
        Text(f.t('rh.banner.body'), style: AQTypography.of(context, AQText.bodySmall, soft: true)),
        const SizedBox(height: AQSpacing.x1),
        AQTextButton(label: f.t('home.viewStatus'), trailingIcon: 'chevron-right', color: c.accent, onPressed: () => context.go('/verification')),
      ]),
    );
  }
}

/// A tile that does one real thing. When [unavailable] is set it never fakes an action: tapping
/// opens an inline explanation of what is missing.
class RoleTile extends StatefulWidget {
  final String icon;
  final String label;
  final String sub;
  final VoidCallback? onTap;
  final bool unavailable;
  final String? note;
  final Color? accent;
  const RoleTile({super.key, required this.icon, required this.label, required this.sub, this.onTap, this.unavailable = false, this.note, this.accent});
  @override
  State<RoleTile> createState() => _RoleTileState();
}

class _RoleTileState extends State<RoleTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final accent = widget.accent ?? c.accent;
    final dim = widget.unavailable;
    return Semantics(
      button: true,
      label: '${widget.label}. ${widget.sub}',
      expanded: dim ? _open : null,
      excludeSemantics: true,
      child: AQPressable(
        onTap: () {
          AQHaptics.selection();
          if (dim) {
            setState(() => _open = !_open);
          } else {
            widget.onTap?.call();
          }
        },
        child: AnimatedSize(
          duration: AQMotion.scaled(context, AQMotion.standard),
          curve: AQMotion.standardCurve,
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.all(AQSpacing.x3),
            decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(AQRadius.medium), border: Border.all(color: c.hairline)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AQRadius.small)),
                  child: Center(child: DbIcon(widget.icon, size: 20, color: dim ? c.inkFaint : accent)),
                ),
                const SizedBox(width: AQSpacing.x3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.label, style: AQTypography.of(context, AQText.titleSmall, color: dim ? c.inkSoft : null)),
                    Text(widget.sub, style: AQTypography.of(context, AQText.bodySmall, soft: true)),
                  ]),
                ),
              ]),
              if (dim && _open && widget.note != null) ...[
                const SizedBox(height: AQSpacing.x2),
                Text(widget.note!, style: AQTypography.of(context, AQText.bodySmall, color: c.inkSoft)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// A numbered essentials cell (01 Identity ...). Opens a real destination.
class RoleNumberCell extends StatelessWidget {
  final String number;
  final String label;
  final String sub;
  final VoidCallback onTap;
  final Color accent;
  const RoleNumberCell({super.key, required this.number, required this.label, required this.sub, required this.onTap, required this.accent});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Semantics(
      button: true,
      label: '$label. $sub',
      excludeSemantics: true,
      child: AQPressable(
        onTap: () {
          AQHaptics.selection();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.all(AQSpacing.x3),
          decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(AQRadius.medium), border: Border.all(color: c.hairline)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label.toUpperCase(), style: AQTypography.of(context, AQText.labelSmall, color: c.inkSoft).copyWith(letterSpacing: 1.3)),
            const SizedBox(height: 2),
            Text(number, style: AQTypography.of(context, AQText.headlineMedium, color: accent)),
            Text(sub, style: AQTypography.of(context, AQText.bodySmall, soft: true)),
          ]),
        ),
      ),
    );
  }
}

/// A navigational row: label left, quiet value or action right. 48 pt minimum.
class RoleRow extends StatelessWidget {
  final String? leadingNumber;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  const RoleRow({super.key, this.leadingNumber, required this.label, this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Semantics(
      button: onTap != null,
      label: value == null ? label : '$label. $value',
      excludeSemantics: true,
      child: AQPressable(
        onTap: onTap == null
            ? null
            : () {
                AQHaptics.selection();
                onTap!();
              },
        child: Container(
          constraints: const BoxConstraints(minHeight: AQControl.tap),
          padding: const EdgeInsets.symmetric(vertical: AQSpacing.x2),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.hairline))),
          child: Row(children: [
            if (leadingNumber != null) ...[
              SizedBox(width: 28, child: Text(leadingNumber!, style: AQTypography.of(context, AQText.labelMedium, color: c.inkFaint))),
            ],
            Expanded(child: Text(label, style: AQTypography.of(context, AQText.bodyMedium))),
            if (value != null) Flexible(child: Text(value!, textAlign: TextAlign.end, style: AQTypography.of(context, AQText.bodySmall, soft: true))),
            if (onTap != null) ...[
              const SizedBox(width: AQSpacing.x1),
              AQIcon('chevron-right', size: 16, color: c.inkFaint, directional: true),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Photograph with a scrim that keeps white text readable in both themes. The image is only an
/// atmosphere: it never claims to be this company's work.
class RolePhotoPanel extends StatelessWidget {
  final String image;
  final String? kicker;
  final String title;
  final String? body;
  final double aspect;
  final Alignment alignment;
  final List<Widget> actions;
  final BorderRadius radius;
  const RolePhotoPanel({
    super.key,
    required this.image,
    this.kicker,
    required this.title,
    this.body,
    this.aspect = 1.1,
    this.alignment = Alignment.center,
    this.actions = const [],
    this.radius = const BorderRadius.all(Radius.circular(AQRadius.large)),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: LayoutBuilder(
        builder: (context, box) {
          // The picture sets a minimum height; long text or large type makes the panel taller
          // instead of being clipped.
          final minHeight = box.maxWidth.isFinite ? box.maxWidth / aspect : 0.0;
          return Stack(children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: Stack(fit: StackFit.expand, children: [
                  aqImg(image, cacheWidth: 900, alignment: alignment),
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x33000000), Color(0xB3000000)])),
                  ),
                ]),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Padding(
                padding: const EdgeInsets.all(AQSpacing.x4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                  if (kicker != null) Text(kicker!, style: AQTypography.of(context, AQText.labelSmall, color: const Color(0xFFF0DCC0)).copyWith(letterSpacing: 1.6)),
                  if (kicker != null) const SizedBox(height: AQSpacing.x1),
                  Semantics(header: true, child: Text(title, style: AQTypography.of(context, AQText.headlineLarge, color: Colors.white))),
                  if (body != null) ...[
                    const SizedBox(height: AQSpacing.x1),
                    Text(body!, style: AQTypography.of(context, AQText.bodySmall, color: const Color(0xFFF3EBDD))),
                  ],
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: AQSpacing.x3),
                    Wrap(spacing: AQSpacing.x2, runSpacing: AQSpacing.x2, children: actions),
                  ],
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}

/// Ivory pill used on top of photography.
class RolePhotoButton extends StatelessWidget {
  final String label;
  final String? icon;
  final VoidCallback onTap;
  const RolePhotoButton({super.key, required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: AQPressable(
        onTap: () {
          AQHaptics.selection();
          onTap();
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: AQControl.tap, minWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: AQSpacing.x4),
          decoration: BoxDecoration(color: const Color(0xFFFBF7F1), borderRadius: BorderRadius.circular(AQRadius.medium)),
          child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[DbIcon(icon!, size: 18, color: const Color(0xFF2D2823)), const SizedBox(width: 6)],
            Flexible(child: Text(label, style: AQTypography.of(context, AQText.labelLarge, color: const Color(0xFF2D2823)))),
          ]),
        ),
      ),
    );
  }
}

/// Small "chip" label (verified role etc.).
class RoleChip extends StatelessWidget {
  final String label;
  final String? icon;
  final Color color;
  const RoleChip(this.label, {super.key, this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AQSpacing.x3, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[AQIcon(icon!, size: 14, color: color), const SizedBox(width: 4)],
          Flexible(child: Text(label, style: AQTypography.of(context, AQText.labelSmall, color: color))),
        ]),
      );
}
