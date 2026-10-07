/// Spacing, radius, border, elevation, motion, icon-size and breakpoint
/// tokens — pulled from Figma "09 Design System Foundations". No arbitrary
/// numeric values should appear outside this file.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double xxxxl = 64;
  static const double xxxxxl = 80;
  static const double xxxxxxl = 128;
}

class AppRadius {
  AppRadius._();

  static const double none = 0;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double pill = 9999;
}

class AppBorder {
  AppBorder._();

  static const double thin = 1;
  static const double regular = 1.5;
  static const double strong = 2;
}

class AppElevation {
  AppElevation._();

  // (blur, alpha) pairs — offsets kept small per "shadows sparingly" rule.
  static const double flat = 0;
  static const double subtleBlur = 4;
  static const double mediumBlur = 12;
  static const double elevatedBlur = 24;
  static const double overlayBlur = 40;

  static const double subtleAlpha = 0.06;
  static const double mediumAlpha = 0.08;
  static const double elevatedAlpha = 0.10;
  static const double overlayAlpha = 0.14;
}

class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}

class AppIconSize {
  AppIconSize._();

  static const double sm = 16;
  static const double compact = 20;
  static const double md = 24;
  static const double lg = 32;
}

/// Grid breakpoints (mobile-first; this app targets mobile, but the values
/// stay here so any future tablet/desktop pass reads from one place).
class AppBreakpoint {
  AppBreakpoint._();

  static const double mobile = 390;
  static const double tablet = 768;
  static const double desktop = 1280;
}
