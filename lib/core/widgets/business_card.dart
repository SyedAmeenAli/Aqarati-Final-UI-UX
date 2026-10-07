import 'package:flutter/material.dart';
import '../../data/models/business.dart';
import '../../data/models/enums.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'verification_badge.dart';

/// Reusable business/professional card — used in discovery lists and
/// property-detail lister previews.
class BusinessCard extends StatelessWidget {
  final Business business;
  final VoidCallback onTap;

  const BusinessCard({super.key, required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.sand,
                child: Text(
                  business.name.isNotEmpty ? business.name[0] : '?',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            business.name,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (business.verification.isVerified)
                          const VerificationBadge(
                            status: VerificationStatus.verified,
                            label: 'Verified',
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      business.categories.map((c) => c.label).join(' · '),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: AppIconSize.sm, color: AppColors.mist),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            business.locationLabel,
                            style: theme.textTheme.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.mist),
            ],
          ),
        ),
      ),
    );
  }
}
