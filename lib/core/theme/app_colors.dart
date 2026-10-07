import 'package:flutter/material.dart';

/// AQARATI color tokens — pulled from the real Figma Color System page
/// (system version 1.2). Do not hand-tune hex values here; update from Figma.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFC8392B); // Omani Red
  static const Color secondary = Color(0xFF2D6B4A); // Omani Green (verified/success)
  static const Color accent = Color(0xFFA8895E); // Sand

  // Neutral scale (0-950)
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral25 = Color(0xFFFAF8F5);
  static const Color neutral50 = Color(0xFFF5F2EC);
  static const Color neutral100 = Color(0xFFEBE6DC);
  static const Color neutral200 = Color(0xFFD6CEBF);
  static const Color neutral300 = Color(0xFFC2B6A3);
  static const Color neutral400 = Color(0xFFAB9E87);
  static const Color neutral500 = Color(0xFF91856E);
  static const Color neutral600 = Color(0xFF756B57);
  static const Color neutral700 = Color(0xFF5C5445);
  static const Color neutral800 = Color(0xFF433D35);
  static const Color neutral900 = Color(0xFF2A2823);
  static const Color neutral950 = Color(0xFF0F0D0B);

  // Red scale
  static const Color red50 = Color(0xFFFEF2F0);
  static const Color red100 = Color(0xFFFDE2DE);
  static const Color red200 = Color(0xFFFBC4BC);
  static const Color red300 = Color(0xFFF79C93);
  static const Color red400 = Color(0xFFF16B5E);
  static const Color red500 = Color(0xFFE24A3B);
  static const Color red600 = Color(0xFFC8392B); // = primary
  static const Color red700 = Color(0xFFA12B1E);
  static const Color red800 = Color(0xFF7E1F14);
  static const Color red900 = Color(0xFF4E1410);

  // Green scale
  static const Color green50 = Color(0xFFF0F7F3);
  static const Color green100 = Color(0xFFDCEDE3);
  static const Color green200 = Color(0xFFB8D9CC);
  static const Color green300 = Color(0xFF90C2B0);
  static const Color green400 = Color(0xFF63A88E);
  static const Color green500 = Color(0xFF418E6E);
  static const Color green600 = Color(0xFF2D6B4A); // = secondary
  static const Color green700 = Color(0xFF225237);
  static const Color green800 = Color(0xFF173E24);
  static const Color green900 = Color(0xFF0E1F15);

  // Sand scale
  static const Color sand50 = Color(0xFFFBF8F3);
  static const Color sand100 = Color(0xFFF6ECD7);
  static const Color sand200 = Color(0xFFECD7AF);
  static const Color sand300 = Color(0xFFDFC089);
  static const Color sand400 = Color(0xFFCCA464);
  static const Color sand500 = Color(0xFFB78A49);
  static const Color sand600 = Color(0xFFA8895E); // = accent
  static const Color sand700 = Color(0xFF7C5D33);
  static const Color sand800 = Color(0xFF5C4322);
  static const Color sand900 = Color(0xFF3A2D1C);

  // Semantic
  static const Color success = green600;
  static const Color error = red600;
  static const Color warning = Color(0xFFF59E0B);
  static const Color pending = Color(0xFFF59E0B);

  // Verification states — identity / business / property, kept factual not decorative
  static const Color verified = green600;
  static const Color underReview = pending;
  static const Color needsAttention = red600;
  static const Color unverified = neutral400;

  // Semantic aliases used across widgets — map onto the neutral scale so the
  // whole app stays driven by the same 13-step ramp above.
  static const Color ink = neutral900;
  static const Color charcoal = neutral800;
  static const Color slate = neutral600;
  static const Color mist = neutral400;
  static const Color line = neutral200;
  static const Color sand = neutral50; // warm off-white surface, not the sand ramp
  static const Color surface = neutral0;
  static const Color background = neutral25;
  static const Color divider = neutral100;

  static const Color scrim = Color(0x66000000);
}
