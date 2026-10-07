import 'package:flutter/material.dart';

/// AQARATI Experience System: single source of truth for design tokens.
/// Brand values come from the brand book (mocha #825C3F, ivory #ECE3D7,
/// deep mocha #674830, ink #2D2823); dark values are derived, not inverted.

/// Semantic colour set. Read with [AQColors.of].
@immutable
class AQColors {
  final Brightness brightness;
  /// Page background (calm ivory / deep warm near-black).
  final Color background;
  /// Resting tonal surface on the background (fields, choice tiles).
  final Color surface;
  /// Raised tonal surface (sheets, selected tint).
  final Color surfaceRaised;
  /// Selected / pressed tint.
  final Color surfaceSelected;
  final Color ink;
  final Color inkSoft;
  final Color inkFaint;
  final Color hairline;
  final Color accent;
  final Color accentDeep;
  final Color onAccent;
  final Color accentDisabled;
  final Color danger;
  final Color success;

  const AQColors._({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSelected,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.hairline,
    required this.accent,
    required this.accentDeep,
    required this.onAccent,
    required this.accentDisabled,
    required this.danger,
    required this.success,
  });

  static const light = AQColors._(
    brightness: Brightness.light,
    background: Color(0xFFEDE1D4),
    surface: Color(0xB8FBF7F1),
    surfaceRaised: Color(0xFFFBF7F1),
    surfaceSelected: Color(0xFFF6EADB),
    ink: Color(0xFF2D2823),
    inkSoft: Color(0xFF655C52),
    inkFaint: Color(0xFF8E8377),
    hairline: Color(0x33655C52),
    accent: Color(0xFF825C3F),
    accentDeep: Color(0xFF674830),
    onAccent: Color(0xFFFFFFFF),
    accentDisabled: Color(0xFFB09A86),
    danger: Color(0xFFA2402E),
    success: Color(0xFF4C6B38),
  );

  static const dark = AQColors._(
    brightness: Brightness.dark,
    background: Color(0xFF1A1613),
    surface: Color(0xB8272019),
    surfaceRaised: Color(0xFF2A231D),
    surfaceSelected: Color(0xFF3A2E24),
    ink: Color(0xFFF1E8DB),
    inkSoft: Color(0xFFC3B6A5),
    inkFaint: Color(0xFF93877A),
    hairline: Color(0x33F1E8DB),
    accent: Color(0xFFB98A64),
    accentDeep: Color(0xFFD1A47F),
    onAccent: Color(0xFF1A1613),
    accentDisabled: Color(0xFF6B5545),
    danger: Color(0xFFE08A78),
    success: Color(0xFF9DB98A),
  );

  static AQColors of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? dark : light;

  bool get isDark => brightness == Brightness.dark;
}

/// 4-pt rhythm.
class AQSpacing {
  AQSpacing._();
  static const double x1 = 4, x2 = 8, x3 = 12, x4 = 16, x5 = 20, x6 = 24, x8 = 32, x10 = 40, x12 = 48;
  /// Horizontal page margin.
  static const double gutter = 24;
  /// Content never gets wider than this (tablet / web).
  static const double maxContent = 520;
}

/// Three radii only. Everything is built from these.
class AQRadius {
  AQRadius._();
  /// chips, small tags, icon tiles
  static const double small = 10;
  /// buttons, fields, choice tiles
  static const double medium = 18;
  /// sheets, large surfaces
  static const double large = 28;
}

/// Restrained, layered elevation. No ordinary control exceeds `floating`.
class AQElevation {
  AQElevation._();
  static const List<BoxShadow> none = [];
  static const List<BoxShadow> subtle = [BoxShadow(color: Color(0x0F2D2823), blurRadius: 6, offset: Offset(0, 1))];
  static const List<BoxShadow> floating = [BoxShadow(color: Color(0x1A2D2823), blurRadius: 16, offset: Offset(0, 6))];
  static const List<BoxShadow> modal = [BoxShadow(color: Color(0x262D2823), blurRadius: 28, offset: Offset(0, 10))];
}

class AQIconSize {
  AQIconSize._();
  static const double small = 18, medium = 22, large = 26, role = 28;
}

class AQControl {
  AQControl._();
  /// Minimum interactive target (WCAG / platform guidance).
  static const double tap = 48;
  static const double button = 56;
  static const double buttonCompact = 50;
  static const double field = 56;
}

/// Semantic motion. Never hard-code a Duration or Curve in a screen.
class AQMotion {
  AQMotion._();
  static const Duration micro = Duration(milliseconds: 110);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 380);
  static const Duration page = Duration(milliseconds: 340);
  static const Duration hero = Duration(milliseconds: 700);
  static const Duration reveal = Duration(milliseconds: 640);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve decelerate = Curves.decelerate;
  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  /// Soft spring-like settle (no overshoot beyond ~3%).
  static const Curve spring = Cubic(0.22, 1.0, 0.36, 1.0);

  static bool reduced(BuildContext c) => MediaQuery.maybeDisableAnimationsOf(c) ?? false;
  static Duration scaled(BuildContext c, Duration d) => reduced(c) ? Duration.zero : d;
}

/// Responsive helpers: adjust, do not just scale.
class AQLayout {
  AQLayout._();
  static bool compact(BuildContext c) => MediaQuery.sizeOf(c).height < 760;
  static double contentWidth(BuildContext c) => MediaQuery.sizeOf(c).width.clamp(0, AQSpacing.maxContent + AQSpacing.gutter * 2).toDouble();
  /// 0.92..1.08 around a 393 pt reference width.
  static double scale(BuildContext c) => (contentWidth(c) / 393).clamp(0.92, 1.08).toDouble();
}
