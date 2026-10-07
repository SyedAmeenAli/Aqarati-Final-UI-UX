import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter/services.dart';
import 'aq_primitives.dart';
import 'aq_tokens.dart';
import 'aq_typography.dart';

/// Premium text field: calm tonal surface, hairline at rest, strong accent focus,
/// quiet helper, clear inline error. The label floats above the value (also the
/// accessible name).
class AQTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final String? error;
  final TextInputType? keyboardType;
  final TextInputAction action;
  final List<TextInputFormatter>? formatters;
  final Iterable<String>? autofill;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscure;
  final bool enabled;
  final Widget? prefix;
  final Widget? suffix;
  final FocusNode? focusNode;
  /// Quiet confirmation (a small check) once the value is acceptable.
  final bool valid;
  const AQTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.error,
    this.keyboardType,
    this.action = TextInputAction.next,
    this.formatters,
    this.autofill,
    this.onChanged,
    this.onSubmitted,
    this.obscure = false,
    this.enabled = true,
    this.prefix,
    this.suffix,
    this.focusNode,
    this.valid = false,
  });

  @override
  State<AQTextField> createState() => _AQTextFieldState();
}

class _AQTextFieldState extends State<AQTextField> {
  late final FocusNode _focus = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() => _focused = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final hasError = widget.error != null;
    // Resting: tonal fill, no outline. Focus/error: a single soft ring. One look for every field.
    final borderColor = hasError ? c.danger : (_focused ? c.accent : Colors.transparent);
    const width = 1.5;
    return Padding(
      padding: const EdgeInsets.only(bottom: AQSpacing.x4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedContainer(
          duration: AQMotion.scaled(context, AQMotion.fast),
          curve: AQMotion.standardCurve,
          constraints: const BoxConstraints(minHeight: AQControl.field),
          decoration: BoxDecoration(
            // Opaque on the page colour so every field is the same tone whatever photo sits behind it.
            color: Color.alphaBlend(widget.enabled ? c.surface : c.surface.withValues(alpha: 0.5), c.background),
            borderRadius: BorderRadius.circular(AQRadius.medium),
            border: Border.all(color: borderColor, width: width),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            if (widget.prefix != null) Padding(padding: const EdgeInsetsDirectional.only(start: AQSpacing.x4), child: widget.prefix),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                obscureText: widget.obscure,
                keyboardType: widget.keyboardType,
                textInputAction: widget.action,
                inputFormatters: widget.formatters,
                autofillHints: widget.autofill,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                enableSuggestions: !widget.obscure,
                autocorrect: false,
                cursorColor: c.accent,
                // Keep the active field clear of the keyboard and the pinned action.
                scrollPadding: const EdgeInsets.only(bottom: 160),
                style: AQTypography.of(context, AQText.bodyLarge),
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: AQTypography.of(context, AQText.labelMedium, color: hasError ? c.danger : (_focused ? c.accent : c.inkSoft)),
                  floatingLabelStyle: AQTypography.of(context, AQText.labelMedium, color: hasError ? c.danger : (_focused ? c.accent : c.inkSoft)),
                  hintStyle: AQTypography.of(context, AQText.bodyLarge, color: c.inkFaint),
                  // The app theme fills inputs; the container already paints the surface.
                  filled: false,
                  fillColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsetsDirectional.fromSTEB(AQSpacing.x4, AQSpacing.x5, AQSpacing.x4, AQSpacing.x3),
                ),
              ),
            ),
            if (widget.suffix != null)
              Padding(padding: const EdgeInsetsDirectional.only(end: AQSpacing.x1), child: widget.suffix)
            else
              AnimatedSwitcher(
                duration: AQMotion.scaled(context, AQMotion.fast),
                child: (widget.valid && !hasError)
                    ? Padding(key: const ValueKey('valid'), padding: const EdgeInsetsDirectional.only(end: AQSpacing.x4), child: Semantics(label: 'valid', excludeSemantics: true, child: AQIcon('check', size: AQIconSize.small, color: c.success)))
                    : const SizedBox.shrink(key: ValueKey('none')),
              ),
          ]),
        ),
        AnimatedSize(
          duration: AQMotion.scaled(context, AQMotion.fast),
          alignment: Alignment.topCenter,
          child: (hasError || widget.helper != null)
              ? Padding(
                  padding: const EdgeInsets.only(top: AQSpacing.x2, left: AQSpacing.x1, right: AQSpacing.x1),
                  child: Semantics(
                    liveRegion: hasError,
                    child: Text(widget.error ?? widget.helper!, style: AQTypography.of(context, AQText.bodySmall, color: hasError ? c.danger : c.inkSoft)),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ]),
    );
  }
}

class AQPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String showLabel, hideLabel;
  final String? error, helper;
  final TextInputAction action;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool newPassword;
  const AQPasswordField({super.key, required this.label, required this.controller, required this.showLabel, required this.hideLabel, this.error, this.helper, this.action = TextInputAction.next, this.onChanged, this.onSubmitted, this.newPassword = false});

  @override
  State<AQPasswordField> createState() => _AQPasswordFieldState();
}

class _AQPasswordFieldState extends State<AQPasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return AQTextField(
      label: widget.label,
      controller: widget.controller,
      obscure: _hidden,
      error: widget.error,
      helper: widget.helper,
      action: widget.action,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      autofill: [widget.newPassword ? AutofillHints.newPassword : AutofillHints.password],
      suffix: AQIconButton(
        icon: _hidden ? 'eye' : 'eye-off',
        semanticsLabel: _hidden ? widget.showLabel : widget.hideLabel,
        directional: false,
        color: c.inkSoft,
        onPressed: () => setState(() => _hidden = !_hidden),
      ),
    );
  }
}

/// Oman mobile field: +968 prefix, 8 digits.
class AQPhoneField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final String? error;
  final bool valid;
  final ValueChanged<String>? onChanged;
  const AQPhoneField({super.key, required this.label, required this.hint, required this.controller, this.error, this.onChanged, this.valid = false});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return AQTextField(
      label: label,
      controller: controller,
      hint: hint,
      error: error,
      valid: valid,
      keyboardType: TextInputType.phone,
      autofill: const [AutofillHints.telephoneNumberNational],
      formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
      onChanged: onChanged,
      prefix: Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(top: AQSpacing.x4, end: AQSpacing.x3),
          child: Text('+968', style: AQTypography.of(context, AQText.titleSmall, color: c.inkSoft)),
        ),
      ),
    );
  }
}

/// Live password policy checklist (8+ characters, one uppercase letter, one number).
class AQRequirementList extends StatelessWidget {
  final List<({String label, bool met})> items;
  const AQRequirementList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AQSpacing.x4, left: AQSpacing.x1),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final i in items)
          Semantics(
            label: '${i.label}: ${i.met ? 'met' : 'not met'}',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                AnimatedSwitcher(duration: AQMotion.scaled(context, AQMotion.fast), child: AQIcon(i.met ? 'check' : 'info', key: ValueKey(i.met), size: AQIconSize.small, color: i.met ? c.success : c.inkFaint)),
                const SizedBox(width: AQSpacing.x2),
                Expanded(child: Text(i.label, style: AQTypography.of(context, AQText.bodySmall, color: i.met ? c.success : c.inkSoft))),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// Custom checkbox row (no Material checkbox).
class AQCheckRow extends StatelessWidget {
  final bool value;
  final String label;
  final String? error;
  final ValueChanged<bool> onChanged;
  /// Optional rich label (e.g. tappable links). [label] stays the accessible name.
  final Widget? richLabel;
  final Map<CustomSemanticsAction, VoidCallback>? actions;
  const AQCheckRow({super.key, required this.value, required this.label, required this.onChanged, this.error, this.richLabel, this.actions});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AQSpacing.x4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Semantics(
          checked: value,
          label: label,
          customSemanticsActions: actions,
          excludeSemantics: true,
          child: AQPressable(
            pressedScale: 0.99,
            onTap: () {
              AQHaptics.selection();
              onChanged(!value);
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AQControl.tap),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                AnimatedContainer(
                  duration: AQMotion.scaled(context, AQMotion.fast),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: value ? c.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(AQRadius.small - 3),
                    border: Border.all(color: error != null ? c.danger : (value ? c.accent : c.inkFaint), width: 1.5),
                  ),
                  child: value ? Center(child: AQIcon('check', size: 16, color: c.onAccent)) : null,
                ),
                const SizedBox(width: AQSpacing.x3),
                Expanded(child: richLabel ?? Text(label, style: AQTypography.of(context, AQText.bodyMedium, soft: true))),
              ]),
            ),
          ),
        ),
        if (error != null) Padding(padding: const EdgeInsets.only(left: AQSpacing.x1), child: Text(error!, style: AQTypography.of(context, AQText.bodySmall, color: c.danger))),
      ]),
    );
  }
}

/// Segmented single-choice control (service type etc.).
class AQSegmented<T> extends StatelessWidget {
  final List<({T value, String label})> options;
  final T? selected;
  final ValueChanged<T> onChanged;
  final String? label;
  final String? error;
  const AQSegmented({super.key, required this.options, required this.selected, required this.onChanged, this.label, this.error});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AQSpacing.x4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (label != null) Padding(padding: const EdgeInsets.only(bottom: AQSpacing.x2, left: AQSpacing.x1), child: Text(label!, style: AQTypography.of(context, AQText.labelMedium, soft: true))),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AQRadius.medium), border: Border.all(color: error != null ? c.danger : c.hairline)),
          child: Row(children: [
            for (final o in options)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: o.value == selected,
                  label: o.label,
                  excludeSemantics: true,
                  child: AQPressable(
                    pressedScale: 0.98,
                    onTap: () {
                      AQHaptics.selection();
                      onChanged(o.value);
                    },
                    child: AnimatedContainer(
                      duration: AQMotion.scaled(context, AQMotion.fast),
                      constraints: const BoxConstraints(minHeight: 44),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: o.value == selected ? c.accent : Colors.transparent, borderRadius: BorderRadius.circular(AQRadius.medium - 4)),
                      child: Text(o.label, style: AQTypography.of(context, AQText.titleSmall, color: o.value == selected ? c.onAccent : c.ink)),
                    ),
                  ),
                ),
              ),
          ]),
        ),
        if (error != null) Padding(padding: const EdgeInsets.only(top: AQSpacing.x2, left: AQSpacing.x1), child: Text(error!, style: AQTypography.of(context, AQText.bodySmall, color: c.danger))),
      ]),
    );
  }
}

enum AQBannerTone { error, info, success }

class AQErrorBanner extends StatelessWidget {
  final String text;
  final AQBannerTone tone;
  final Widget? action;
  const AQErrorBanner({super.key, required this.text, this.tone = AQBannerTone.error, this.action});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final (fg, icon) = switch (tone) {
      AQBannerTone.error => (c.danger, 'alert'),
      AQBannerTone.info => (c.inkSoft, 'info'),
      AQBannerTone.success => (c.success, 'check'),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: AQSpacing.x4),
        padding: const EdgeInsets.all(AQSpacing.x4),
        decoration: BoxDecoration(color: fg.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(AQRadius.medium)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AQIcon(icon, size: AQIconSize.medium, color: fg),
          const SizedBox(width: AQSpacing.x3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(text, style: AQTypography.of(context, AQText.bodyMedium, color: c.ink)),
              ?action,
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Segmented progress for real, role-dependent flows ("Step 2 of 4").
class AQProgressStepper extends StatelessWidget {
  final int step, total;
  final String label;
  const AQProgressStepper({super.key, required this.step, required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          for (var i = 0; i < total; i++) ...[
            Expanded(
              child: AnimatedContainer(
                duration: AQMotion.scaled(context, AQMotion.standard),
                curve: AQMotion.standardCurve,
                height: 3,
                decoration: BoxDecoration(color: i < step ? c.accent : c.accent.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            if (i < total - 1) const SizedBox(width: 4),
          ],
        ]),
        const SizedBox(height: AQSpacing.x2),
        Text(label, style: AQTypography.of(context, AQText.labelSmall, soft: true)),
      ]),
    );
  }
}

enum AQOtpState { idle, verifying, error, success }

/// Six-digit code field: visible boxes over one hidden input (paste, autofill,
/// one-time-code). Error = a gentle two-beat nudge, never an aggressive shake.
class AQOtpField extends StatefulWidget {
  final int length;
  final String label;
  final AQOtpState state;
  final bool enabled;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  const AQOtpField({super.key, this.length = 6, required this.label, required this.state, required this.enabled, required this.onCompleted, this.onChanged});

  @override
  State<AQOtpField> createState() => AQOtpFieldState();
}

class AQOtpFieldState extends State<AQOtpField> with SingleTickerProviderStateMixin {
  final _c = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _nudge = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

  void clear() {
    _c.clear();
    if (mounted) setState(() {});
  }

  void focus() => _focus.requestFocus();

  @override
  void didUpdateWidget(covariant AQOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != AQOtpState.error && widget.state == AQOtpState.error && !AQMotion.reduced(context)) _nudge.forward(from: 0);
  }

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    _nudge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    final text = _c.text;
    return LayoutBuilder(builder: (context, box) {
      const gap = 8.0;
      final w = math.min(56.0, (box.maxWidth - gap * (widget.length - 1)) / widget.length);
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _focus.requestFocus(),
        child: Stack(children: [
          AnimatedBuilder(
            animation: _nudge,
            builder: (context, child) => Transform.translate(offset: Offset(math.sin(_nudge.value * math.pi * 4) * 6 * (1 - _nudge.value), 0), child: child),
            child: ExcludeSemantics(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    AnimatedContainer(
                      duration: AQMotion.scaled(context, AQMotion.fast),
                      curve: AQMotion.standardCurve,
                      width: w,
                      height: 62,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.state == AQOtpState.success ? c.success.withValues(alpha: 0.14) : c.surface,
                        borderRadius: BorderRadius.circular(AQRadius.medium),
                        border: Border.all(
                          color: widget.state == AQOtpState.error ? c.danger : (widget.state == AQOtpState.success ? c.success : (i == text.length && _focus.hasFocus ? c.accent : (i < text.length ? c.accent.withValues(alpha: 0.5) : c.hairline))),
                          width: (i == text.length && _focus.hasFocus) || widget.state == AQOtpState.error ? 1.6 : 1,
                        ),
                      ),
                      child: widget.state == AQOtpState.success
                          ? AQIcon('check', size: AQIconSize.medium, color: c.success)
                          : AnimatedScale(
                              scale: i < text.length ? 1 : 0.8,
                              duration: AQMotion.scaled(context, AQMotion.micro),
                              child: Text(i < text.length ? text[i] : '', style: AQTypography.of(context, AQText.headlineLarge)),
                            ),
                    ),
                    if (i < widget.length - 1) const SizedBox(width: gap),
                  ],
                ]),
              ),
            ),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              alwaysIncludeSemantics: true,
              child: TextField(
                controller: _c,
                focusNode: _focus,
                autofocus: true,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(widget.length)],
                decoration: InputDecoration(labelText: widget.label, border: InputBorder.none),
                onChanged: (v) {
                  setState(() {});
                  widget.onChanged?.call(v);
                  if (v.length == widget.length) widget.onCompleted(v);
                },
              ),
            ),
          ),
        ]),
      );
    });
  }
}

/// Check that draws itself inside an accent disc (success moments).
class AQAnimatedCheck extends StatefulWidget {
  final double size;
  const AQAnimatedCheck({super.key, this.size = 88});

  @override
  State<AQAnimatedCheck> createState() => _AQAnimatedCheckState();
}

class _AQAnimatedCheckState extends State<AQAnimatedCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: AQMotion.hero);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AQMotion.reduced(context)) {
        _a.value = 1;
      } else {
        _a.forward();
        AQHaptics.success();
      }
    });
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return AnimatedBuilder(
      animation: _a,
      builder: (context, _) {
        final disc = Curves.easeOutBack.transform(Interval(0, 0.5).transform(_a.value).clamp(0.0, 1.0));
        final draw = AQMotion.emphasized.transform(Interval(0.35, 1).transform(_a.value).clamp(0.0, 1.0));
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(painter: _CheckPainter(disc: disc, draw: draw, color: c.accent, on: c.onAccent, halo: c.accent.withValues(alpha: 0.16))),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double disc, draw;
  final Color color, on, halo;
  _CheckPainter({required this.disc, required this.draw, required this.color, required this.on, required this.halo});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    canvas.drawCircle(center, r * disc, Paint()..color = halo);
    canvas.drawCircle(center, r * 0.72 * disc, Paint()..color = color);
    final p = Path()
      ..moveTo(size.width * 0.34, size.height * 0.52)
      ..lineTo(size.width * 0.45, size.height * 0.63)
      ..lineTo(size.width * 0.67, size.height * 0.40);
    final m = p.computeMetrics().first;
    canvas.drawPath(m.extractPath(0, m.length * draw), Paint()..color = on..style = PaintingStyle.stroke..strokeWidth = size.width * 0.045..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter o) => o.disc != disc || o.draw != draw || o.color != color;
}
