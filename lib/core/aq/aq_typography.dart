import 'package:flutter/material.dart';
import 'aq_tokens.dart';

enum AQText {
  displayLarge,
  displayMedium,
  displaySmall,
  headlineLarge,
  headlineMedium,
  headlineSmall,
  titleLarge,
  titleMedium,
  titleSmall,
  bodyLarge,
  bodyMedium,
  bodySmall,
  labelLarge,
  labelMedium,
  labelSmall,
}

class _Spec {
  final bool editorial; // Fraunces (Latin) vs Plus Jakarta Sans
  final double size, height, weight, tracking;
  const _Spec(this.editorial, this.size, this.height, this.weight, this.tracking);
}

/// Semantic type scale. Fraunces = editorial display, Plus Jakarta Sans = UI,
/// IBM Plex Sans Arabic for RTL. All bundled; each carries the other script as fallback.
class AQTypography {
  AQTypography._();

  static const _spec = <AQText, _Spec>{
    AQText.displayLarge: _Spec(true, 46, 1.04, 400, -1.1),
    AQText.displayMedium: _Spec(true, 38, 1.08, 400, -0.9),
    AQText.displaySmall: _Spec(true, 32, 1.12, 400, -0.6),
    AQText.headlineLarge: _Spec(true, 28, 1.18, 450, -0.4),
    AQText.headlineMedium: _Spec(true, 24, 1.24, 450, -0.3),
    AQText.headlineSmall: _Spec(true, 20, 1.3, 500, -0.2),
    AQText.titleLarge: _Spec(false, 18, 1.35, 600, -0.1),
    AQText.titleMedium: _Spec(false, 16, 1.4, 600, 0),
    AQText.titleSmall: _Spec(false, 14, 1.4, 600, 0),
    AQText.bodyLarge: _Spec(false, 17, 1.5, 400, 0),
    AQText.bodyMedium: _Spec(false, 15, 1.5, 400, 0),
    AQText.bodySmall: _Spec(false, 13, 1.45, 400, 0.05),
    AQText.labelLarge: _Spec(false, 16, 1.2, 600, 0.1),
    AQText.labelMedium: _Spec(false, 13, 1.2, 600, 0.2),
    AQText.labelSmall: _Spec(false, 11, 1.2, 600, 1.4),
  };

  static FontWeight _w(double w) => FontWeight.values[((w / 100).round() - 1).clamp(0, 8)];

  /// [color] defaults to the semantic role colour (display/headline/title = ink,
  /// body = ink, label = ink). Pass `soft: true` for subordinate copy.
  static TextStyle of(BuildContext context, AQText role, {Color? color, bool soft = false, bool italic = false}) {
    final c = AQColors.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final s = _spec[role]!;
    final scale = (s.editorial ? AQLayout.scale(context) : 1.0);
    final col = color ?? (soft ? c.inkSoft : c.ink);
    if (rtl) {
      return TextStyle(
        fontFamily: 'IBMPlexSansArabic',
        fontFamilyFallback: const ['PlusJakartaSans'],
        fontSize: s.size * scale * (s.editorial ? 0.92 : 1.0),
        height: s.height + 0.14,
        fontWeight: _w(s.editorial ? 600 : s.weight.clamp(400, 700).toDouble()),
        color: col,
      );
    }
    return TextStyle(
      fontFamily: s.editorial ? 'Fraunces' : 'PlusJakartaSans',
      fontFamilyFallback: const ['IBMPlexSansArabic'],
      fontSize: s.size * scale,
      height: s.height,
      fontWeight: _w(s.weight),
      letterSpacing: s.tracking,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: col,
    );
  }
}
