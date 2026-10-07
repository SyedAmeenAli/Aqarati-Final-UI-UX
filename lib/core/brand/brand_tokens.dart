import 'package:flutter/material.dart';

/// Brand-book tokens (Figma Brand Foundation, steps 08–09, 14–15). Values
/// mirror the AQARATI brand site's `tokens.css`.
class BrandColors {
  BrandColors._();
  static const Color mocha = Color(0xFF825C3F);
  static const Color mochaDeep = Color(0xFF674830);
  static const Color ivory = Color(0xFFECE3D7);
  /// Measured from frame 0 / last frame of the startup film; splash and
  /// intro share it so there is no colour jump.
  static const Color introIvory = Color(0xFFEDE1D4);
  static const Color ink = Color(0xFF2D2823);
  static const Color inkSoft = Color(0xFF655C52);
  static const Color line = Color(0xFFC9BFB2);
  static const Color card = Color(0xFFFBF7F1);
  static const Color mochaDisabled = Color(0xFFAE957F);
}

class BrandSpace {
  BrandSpace._();
  static const double s1 = 4, s2 = 8, s3 = 12, s4 = 16, s5 = 20, s6 = 24, s8 = 32, s10 = 40;
  /// Outer horizontal margin of the entry/onboarding content column.
  static const double gutter = 24;
  static const double maxContent = 520;
}

class BrandRadius {
  BrandRadius._();
  static const double md = 8, lg = 12, xl = 16, xxl = 20, hero = 24;
  static const double control = 20;
}

class BrandSize {
  BrandSize._();
  static const double control = 56;
  static const double tap = 48;
}

/// Display = Fraunces, UI = Plus Jakarta Sans, Arabic = IBM Plex Sans Arabic.
/// Every style carries the other script's bundled font as fallback, so mixed
/// text (e.g. the "العربية" language label in an English UI, or digits in
/// Arabic) never falls back to a system or downloaded font.
class BrandType {
  BrandType._();
  static const _latinFallback = ['PlusJakartaSans', 'Fraunces'];
  static const _arabicFallback = ['IBMPlexSansArabic'];

  static String familyFor(BuildContext c) => Directionality.of(c) == TextDirection.rtl ? 'IBMPlexSansArabic' : 'PlusJakartaSans';

  static TextStyle display(BuildContext c, {required double size, FontStyle? style, Color? color, double height = 1.12}) {
    final rtl = Directionality.of(c) == TextDirection.rtl;
    if (rtl) {
      return TextStyle(fontFamily: 'IBMPlexSansArabic', fontFamilyFallback: _latinFallback, fontSize: size * 0.92, fontWeight: FontWeight.w600, height: 1.35, color: color ?? BrandColors.ink);
    }
    return TextStyle(fontFamily: 'Fraunces', fontFamilyFallback: _arabicFallback, fontSize: size, fontWeight: FontWeight.w500, fontStyle: style, height: height, letterSpacing: -0.5, color: color ?? BrandColors.ink);
  }

  static TextStyle ui(BuildContext c, {double size = 16, FontWeight weight = FontWeight.w500, Color? color, double height = 1.45, double letterSpacing = 0}) {
    final rtl = Directionality.of(c) == TextDirection.rtl;
    final col = color ?? BrandColors.ink;
    if (rtl) return TextStyle(fontFamily: 'IBMPlexSansArabic', fontFamilyFallback: _latinFallback, fontSize: size, fontWeight: weight, height: height + 0.1, color: col);
    return TextStyle(fontFamily: 'PlusJakartaSans', fontFamilyFallback: _arabicFallback, fontSize: size, fontWeight: weight, height: height, letterSpacing: letterSpacing, color: col);
  }
}

/// Wraps a screen so Material widgets that use the theme text styles (chips,
/// date picker, buttons, snack bars) also use the bundled brand fonts instead
/// of the platform default (Roboto on web).
class BrandThemed extends StatelessWidget {
  final Widget child;
  const BrandThemed({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final family = BrandType.familyFor(context);
    const fb = ['IBMPlexSansArabic', 'PlusJakartaSans'];
    final label = BrandType.ui(context, size: 14, weight: FontWeight.w600);
    ButtonStyle? withLabel(ButtonStyle? st) => (st ?? const ButtonStyle()).copyWith(textStyle: WidgetStatePropertyAll(label));
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(fontFamily: family, fontFamilyFallback: fb),
        primaryTextTheme: base.primaryTextTheme.apply(fontFamily: family, fontFamilyFallback: fb),
        // The legacy app theme pins component text to runtime-fetched fonts; override with bundled ones.
        chipTheme: base.chipTheme.copyWith(labelStyle: label),
        textButtonTheme: TextButtonThemeData(style: withLabel(base.textButtonTheme.style)),
        elevatedButtonTheme: ElevatedButtonThemeData(style: withLabel(base.elevatedButtonTheme.style)),
        outlinedButtonTheme: OutlinedButtonThemeData(style: withLabel(base.outlinedButtonTheme.style)),
        filledButtonTheme: FilledButtonThemeData(style: withLabel(base.filledButtonTheme.style)),
        snackBarTheme: base.snackBarTheme.copyWith(contentTextStyle: BrandType.ui(context, size: 14, color: Colors.white)),
      ),
      child: child,
    );
  }
}
