import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

enum AqaratiButtonVariant { primary, secondary, text }

/// Single button component for the whole app. One clear primary action per screen.
class AqaratiButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AqaratiButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;
  final bool loading;

  const AqaratiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AqaratiButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppIconSize.md),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(label, maxLines: 1),
              ],
            ),
          );

    final Widget button = switch (variant) {
      AqaratiButtonVariant.primary => ElevatedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      AqaratiButtonVariant.secondary => OutlinedButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
      AqaratiButtonVariant.text => TextButton(
          onPressed: loading ? null : onPressed,
          child: child,
        ),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}
