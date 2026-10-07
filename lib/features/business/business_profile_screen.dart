import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_asset_image.dart';
import '../../core/widgets/aqarati_button.dart';
import '../../core/widgets/auth_gate_sheet.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/verification_badge.dart';
import '../../data/models/business.dart';
import '../../data/models/enums.dart';
import '../../data/repositories/providers.dart';
import '../reviews/review_screen.dart';

class BusinessProfileScreen extends ConsumerWidget {
  final String businessId;

  const BusinessProfileScreen({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessRepo = ref.watch(businessRepositoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: FutureBuilder<Business?>(
        future: businessRepo.getById(businessId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AqaratiLoadingLine(label: 'Loading business...');
          }
          final business = snapshot.data;
          if (business == null) {
            return AqaratiErrorState(onRetry: () {});
          }
          return _buildProfile(context, theme, business);
        },
      ),
    );
  }

  Widget _buildProfile(BuildContext context, ThemeData theme, Business business) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 200,
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.ink,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: AppColors.sand,
                  child: const Center(
                    child: Icon(Icons.apartment_rounded, size: 56, color: AppColors.mist),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.sand,
                          child: Text(business.name[0], style: theme.textTheme.headlineSmall),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(business.name, style: theme.textTheme.headlineSmall),
                              const SizedBox(height: 2),
                              Text(
                                business.categories.map((c) => c.label).join(' · '),
                                style: theme.textTheme.bodyMedium,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              if (business.verification.isVerified)
                                const VerificationBadge(
                                  status: VerificationStatus.verified,
                                  label: 'Verified Business',
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: AppIconSize.compact, color: AppColors.slate),
                        const SizedBox(width: 4),
                        Expanded(child: Text(business.locationLabel, style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                    if (business.serviceArea.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.map_outlined, size: AppIconSize.compact, color: AppColors.slate),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text('Serves ${business.serviceArea}', style: theme.textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: AppSpacing.xxxl),
                    Text('About', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      business.description.isEmpty ? 'No description provided yet.' : business.description,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Divider(height: AppSpacing.xxxl),
                    Text('Services', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: business.categories
                          .map((c) => Chip(label: Text(c.label), backgroundColor: AppColors.sand))
                          .toList(),
                    ),
                    const Divider(height: AppSpacing.xxxl),
                    Text('Portfolio', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.sm),
                    business.galleryUrls.isEmpty
                        ? AqaratiEmptyState(
                            icon: Icons.image_outlined,
                            title: 'No portfolio yet',
                            message: 'This business hasn\'t uploaded project photos yet.',
                          )
                        : GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: AppSpacing.sm,
                            crossAxisSpacing: AppSpacing.sm,
                            children: business.galleryUrls
                                .map((url) => ClipRRect(
                                      borderRadius: BorderRadius.circular(AppRadius.sm),
                                      child: AqaratiAssetImage(
                                        url,
                                        displayWidth: 130,
                                        errorBuilder: (context, error, stack) => Container(
                                          decoration: BoxDecoration(
                                            color: AppColors.sand,
                                            borderRadius: BorderRadius.circular(AppRadius.sm),
                                          ),
                                          child: const Icon(Icons.image_outlined, color: AppColors.mist),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                    const Divider(height: AppSpacing.xxxl),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reviews', style: theme.textTheme.titleLarge),
                        TextButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ReviewScreen(
                                listingLabel: business.locationLabel,
                                listingTitle: business.name,
                                priceLabel: '',
                              ),
                            ),
                          ),
                          child: const Text('Write a review'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: const Border(top: BorderSide(color: AppColors.line)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: AppElevation.subtleAlpha),
                  blurRadius: AppElevation.overlayBlur,
                ),
              ],
            ),
            child: AqaratiButton(
              label: 'Request a quote',
              fullWidth: true,
              onPressed: () => showAuthGateSheet(
                context,
                actionLabel: 'request a quote',
                onContinue: () {},
              ),
            ),
          ),
        ),
      ],
    );
  }
}
