import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'aqarati_button.dart';

/// Shown when a guest attempts an action that requires an account
/// (save, message, enquire, book, pay). Never dumps the user back to Home —
/// callers should proceed with [onContinue] right where the user left off.
Future<void> showAuthGateSheet(
  BuildContext context, {
  required VoidCallback onContinue,
  String actionLabel = 'continue',
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sign in to continue', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Use your Oman digital identity to securely confirm who you are before you $actionLabel.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          AqaratiButton(
            label: 'Continue with THEQA',
            icon: Icons.fingerprint_rounded,
            fullWidth: true,
            onPressed: () {
              Navigator.of(context).pop();
              onContinue();
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not now'),
          ),
        ],
      ),
    ),
  );
}

/// Small helper — content behind the gate shows a soft blur/scrim to signal
/// "there's more here once you sign in" without hiding it entirely.
class GatedPreview extends StatelessWidget {
  final Widget child;

  const GatedPreview({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(opacity: 0.4, child: IgnorePointer(child: child)),
        Container(color: AppColors.scrim.withValues(alpha: 0.05)),
      ],
    );
  }
}
