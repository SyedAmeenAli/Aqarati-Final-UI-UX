import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/aq/aq_primitives.dart';
import '../../../core/aq/aq_scene.dart';
import '../../../core/aq/aq_tokens.dart';
import '../../../core/aq/aq_typography.dart';
import '../../../core/localization/entry_strings.dart';
import '../models/signup_purpose.dart';
import '../widgets/entry_common.dart' show MasterLogo;

/// Captures sign-up intent only: nothing is created, sent or persisted here,
/// and choosing a role does not mean the person is verified. The journey length
/// depends on the role, so no fixed "step x of 3" is shown.
class PurposeSelectionScreen extends StatefulWidget {
  const PurposeSelectionScreen({super.key});

  @override
  State<PurposeSelectionScreen> createState() => _PurposeSelectionScreenState();
}

class _PurposeSelectionScreenState extends State<PurposeSelectionScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  SignupPurpose? _selected;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(vsync: this, duration: AQMotion.reveal);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (AQMotion.reduced(context)) {
        _enter.value = 1;
      } else {
        _enter.forward();
      }
    });
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  Alignment _cropFor(SignupPurpose? p) => switch (p) {
        SignupPurpose.realEstateAgent => const Alignment(-0.5, 1),
        SignupPurpose.constructionCompany => const Alignment(0.5, 0.7),
        SignupPurpose.propertyDevelopmentCompany => const Alignment(0.9, 0.9),
        SignupPurpose.buildingArchitecture => const Alignment(0.2, 0.5),
        SignupPurpose.interiorExteriorDesign => const Alignment(-0.9, 0.8),
        _ => Alignment.bottomCenter,
      };

  void _continue(EntryStrings s) {
    final selected = _selected;
    if (selected == null) return;
    final option = signupPurposeOptions.firstWhere((o) => o.id == selected);
    try {
      AQHaptics.confirm();
      context.push(option.route);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s.navFailed, style: AQTypography.of(context, AQText.bodyMedium, color: Colors.white)),
        action: SnackBarAction(label: s.retry, onPressed: () => _continue(s)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = EntryStrings.of(context);
    final c = AQColors.of(context);
    final compact = AQLayout.compact(context);
    final selected = _selected == null ? null : signupPurposeOptions.firstWhere((o) => o.id == _selected);
    final logoWidth = (AQLayout.contentWidth(context) * (compact ? 0.24 : 0.26)).clamp(96.0, 150.0);

    final rows = <Widget>[];
    for (var i = 0; i < signupPurposeOptions.length; i += 2) {
      final a = signupPurposeOptions[i], b = signupPurposeOptions[i + 1];
      Widget tile(SignupPurposeOption o) => AQChoiceTile(icon: o.icon, title: o.title(s), description: o.description(s), selected: _selected == o.id, onTap: () => setState(() => _selected = o.id));
      rows.add(AQReveal(
        animation: _enter,
        begin: 0.28 + i * 0.05,
        end: 0.82 + i * 0.03,
        dy: 8,
        child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: tile(a)), const SizedBox(width: AQSpacing.x3), Expanded(child: tile(b))])),
      ));
      if (i + 2 < signupPurposeOptions.length) rows.add(const SizedBox(height: AQSpacing.x3));
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: c.isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: c.isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: c.background,
        body: Stack(fit: StackFit.expand, children: [
          // The photograph re-frames very slightly for the chosen role; one scene, one language.
          TweenAnimationBuilder<Alignment>(
            tween: AlignmentTween(end: _cropFor(_selected)),
            duration: AQMotion.scaled(context, AQMotion.slow),
            curve: AQMotion.standardCurve,
            builder: (context, a, _) => AQBackdrop(asset: 'assets/entry/oman_terrace_2k.jpg', alignment: a),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AQSpacing.maxContent + AQSpacing.gutter * 2),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AQSpacing.x4),
                    child: AQTopBar(onBack: () => aqBack(context, '/entry'), backLabel: s.back),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(AQSpacing.gutter, 0, AQSpacing.gutter, AQSpacing.x4),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Center(child: AQReveal(animation: _enter, begin: 0, end: 0.45, dy: 10, child: MasterLogo(width: logoWidth))),
                        SizedBox(height: compact ? AQSpacing.x4 : AQSpacing.x6),
                        AQReveal(animation: _enter, begin: 0.08, end: 0.55, dy: 8, child: Semantics(header: true, child: Text(s.purposeTitle, style: AQTypography.of(context, AQText.displaySmall)))),
                        const SizedBox(height: AQSpacing.x3),
                        AQReveal(animation: _enter, begin: 0.16, end: 0.65, dy: 6, child: Text(s.purposeSub, style: AQTypography.of(context, AQText.bodyMedium, soft: true))),
                        SizedBox(height: compact ? AQSpacing.x5 : AQSpacing.x6),
                        ...rows,
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AQSpacing.gutter, AQSpacing.x2, AQSpacing.gutter, AQSpacing.x4),
                    child: AQReveal(
                      animation: _enter,
                      begin: 0.55,
                      end: 1,
                      dy: 6,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        // Supportive line for the chosen role (reserved height so nothing jumps).
                        SizedBox(
                          height: compact ? 40 : 48,
                          child: AnimatedSwitcher(
                            duration: AQMotion.scaled(context, AQMotion.standard),
                            child: selected == null
                                ? const SizedBox.shrink(key: ValueKey('none'))
                                : Align(
                                    key: ValueKey(selected.id),
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(selected.tagline(s), maxLines: 2, overflow: TextOverflow.fade, style: AQTypography.of(context, AQText.bodyMedium, color: c.accentDeep, italic: true)),
                                  ),
                          ),
                        ),
                      AQPrimaryButton(
                        compact: compact,
                        label: s.continueLabel,
                        semanticsLabel: selected == null ? s.continueLabel : s.continueWith(selected.title(s)),
                        onPressed: selected == null ? null : () => _continue(s),
                      ),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
