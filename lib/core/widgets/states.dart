import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'aqarati_button.dart';

/// Empty state — always tells the user what to do next.
class AqaratiEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const AqaratiEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.mist),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (ctaLabel != null && onCta != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AqaratiButton(label: ctaLabel!, onPressed: onCta),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state — never expose technical errors to the user.
class AqaratiErrorState extends StatelessWidget {
  final bool offline;
  final VoidCallback onRetry;

  const AqaratiErrorState({super.key, this.offline = false, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
              size: 48,
              color: AppColors.mist,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              offline ? "You're offline" : 'Something went wrong',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              offline
                  ? 'Check your connection and try again.'
                  : "We couldn't load this right now.",
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            AqaratiButton(label: 'Try again', onPressed: onRetry, variant: AqaratiButtonVariant.secondary),
          ],
        ),
      ),
    );
  }
}

/// Calm skeleton loading block. Use inside a shimmer-less pulse for a
/// premium, non-distracting loading feel.
class AqaratiSkeleton extends StatefulWidget {
  final double height;
  final double? width;
  final double radius;

  const AqaratiSkeleton({super.key, required this.height, this.width, this.radius = 12});

  @override
  State<AqaratiSkeleton> createState() => _AqaratiSkeletonState();
}

class _AqaratiSkeletonState extends State<AqaratiSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(AppColors.sand, AppColors.line, _controller.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Calm, human loading copy line with a small progress indicator.
class AqaratiLoadingLine extends StatelessWidget {
  final String label;

  const AqaratiLoadingLine({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
