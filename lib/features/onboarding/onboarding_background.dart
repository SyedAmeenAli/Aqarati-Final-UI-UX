import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Atmospheric background layer for onboarding steps — a top hero band of
/// real Omani architectural photography that fades into the existing flat
/// background before reaching the selection controls/CTA, so the supplied
/// imagery enriches the screen without ever becoming the primary content.
/// The existing AqaratiOnboarding UI (title, chips, buttons) renders
/// unchanged on top; this widget owns only the photograph + fade.
class AqaratiOnboardingBackground extends StatelessWidget {
  final String asset;
  final Widget child;

  const AqaratiOnboardingBackground({super.key, required this.asset, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fadeColor = isDark ? AppColors.neutral900 : AppColors.background;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 340,
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stack) => Container(color: fadeColor),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 340,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  fadeColor.withValues(alpha: isDark ? 0.55 : 0.15),
                  fadeColor.withValues(alpha: 0.35),
                  fadeColor,
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
