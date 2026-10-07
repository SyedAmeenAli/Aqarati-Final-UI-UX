import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Type scale — pulled from Figma "06 Typography" (system v1.2).
///
/// Two-tier font pairing per the brand's Arabic-English font pairing table:
/// - Editorial (Display/H1/H2): Cormorant Garamond — paired with Noto Naskh
///   Arabic when RTL ships.
/// - Standard UI (H3 and smaller): Inter — paired with IBM Plex Sans Arabic
///   when RTL ships.
/// Dense data/metrics (prices, ref IDs) get IBM Plex Arabic on the Arabic
/// side; the Latin side stays Inter, so no separate English style is needed
/// today.
class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => TextTheme(
        // Display — 48/SemiBold/LH1.2
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 48,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: AppColors.ink,
        ),
        // H1 — 36/SemiBold/LH1.2
        headlineLarge: GoogleFonts.cormorantGaramond(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: AppColors.ink,
        ),
        // H2 — 28/SemiBold/LH1.3
        headlineMedium: GoogleFonts.cormorantGaramond(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: AppColors.ink,
        ),
        // H3 — 22/Medium/LH1.4 (standard UI tier starts here)
        headlineSmall: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: AppColors.ink,
        ),
        // H4 — 18/Medium/LH1.4
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          height: 1.4,
          color: AppColors.ink,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: AppColors.ink,
        ),
        titleSmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: AppColors.charcoal,
        ),
        // Body Large — 18/Regular/LH1.6
        bodyLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: AppColors.charcoal,
        ),
        // Body — 16/Regular/LH1.6
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.6,
          color: AppColors.charcoal,
        ),
        // Body Small — 14/Regular/LH1.5
        bodySmall: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: AppColors.slate,
        ),
        // Button — 16/SemiBold/LH1.2
        labelLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.2,
          color: AppColors.ink,
        ),
        // Label — 12/SemiBold/LH1.2/Uppercase (apply textTransform at call site)
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.2,
          letterSpacing: 0.4,
          color: AppColors.slate,
        ),
        // Caption — 12/Regular/LH1.4
        labelSmall: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: AppColors.mist,
        ),
      );
}
