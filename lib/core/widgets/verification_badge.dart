import 'package:flutter/material.dart';
import '../../data/models/enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A single, calm indicator for identity / business / property verification.
/// Never implies government affiliation — factual status only.
class VerificationBadge extends StatelessWidget {
  final VerificationStatus status;
  final String? label;

  const VerificationBadge({super.key, required this.status, this.label});

  Color get _color {
    switch (status) {
      case VerificationStatus.verified:
        return AppColors.verified;
      case VerificationStatus.underReview:
      case VerificationStatus.submitted:
        return AppColors.underReview;
      case VerificationStatus.needsAttention:
        return AppColors.needsAttention;
      case VerificationStatus.unverified:
        return AppColors.unverified;
    }
  }

  IconData get _icon {
    switch (status) {
      case VerificationStatus.verified:
        return Icons.verified_rounded;
      case VerificationStatus.underReview:
      case VerificationStatus.submitted:
        return Icons.schedule_rounded;
      case VerificationStatus.needsAttention:
        return Icons.error_outline_rounded;
      case VerificationStatus.unverified:
        return Icons.help_outline_rounded;
    }
  }

  String get _defaultLabel {
    switch (status) {
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.underReview:
        return 'Under review';
      case VerificationStatus.submitted:
        return 'Submitted';
      case VerificationStatus.needsAttention:
        return 'Needs attention';
      case VerificationStatus.unverified:
        return 'Not verified';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label ?? _defaultLabel,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
