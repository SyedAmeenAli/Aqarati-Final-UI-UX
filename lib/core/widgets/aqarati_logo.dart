import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The real AQARATI arch mark, pulled from Figma (asset id a9b8b).
/// Native aspect ratio ~376.56 x 302.157 — always size by [height] and let
/// width follow, never stretch.
class AqaratiLogoMark extends StatelessWidget {
  final double height;

  const AqaratiLogoMark({super.key, this.height = 64});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo/aqarati_logo_mark.svg',
      height: height,
    );
  }
}

/// Full lockup: mark + "AQARATI" wordmark + Arabic + tagline, matching the
/// Figma cover page exactly. Use on splash/auth screens only — elsewhere use
/// [AqaratiLogoMark] alone or the top-bar wordmark.
class AqaratiFullLockup extends StatelessWidget {
  final double markHeight;
  final bool showTagline;

  const AqaratiFullLockup({super.key, this.markHeight = 140, this.showTagline = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AqaratiLogoMark(height: markHeight),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'AQARATI',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                letterSpacing: 22,
                color: const Color(0xFF1C2B1A),
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'عقاراتي',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                letterSpacing: 4,
                color: AppColors.sand600,
              ),
        ),
        if (showTagline) ...[
          const SizedBox(height: AppSpacing.lg),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 32, height: 1, color: AppColors.sand700),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'REAL ESTATE FOR A BETTER OMAN',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 3,
                        color: AppColors.neutral700,
                      ),
                ),
              ),
              Container(width: 32, height: 1, color: AppColors.sand700),
            ],
            ),
          ),
        ],
      ],
    );
  }
}
