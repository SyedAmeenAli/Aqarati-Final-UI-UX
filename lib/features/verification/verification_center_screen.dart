import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/verification_badge.dart';
import '../../data/models/enums.dart';
import 'identity_verification_flow.dart';
import 'property_verification_flow.dart';

/// Trust model kept strictly separate per spec: identity (THEQA) vs business
/// vs property verification are three different questions, never conflated.
class VerificationCenterScreen extends StatefulWidget {
  const VerificationCenterScreen({super.key});

  @override
  State<VerificationCenterScreen> createState() => _VerificationCenterScreenState();
}

class _VerificationCenterScreenState extends State<VerificationCenterScreen> {
  VerificationStatus _identity = VerificationStatus.unverified;
  VerificationStatus _property = VerificationStatus.unverified;
  final VerificationStatus _business = VerificationStatus.unverified;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Verification Centre')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Keep your account trusted', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Identity, property and business verification are reviewed separately.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          _VerificationTile(
            icon: Icons.fingerprint_rounded,
            title: 'Identity Verification',
            subtitle: 'Confirm who you are using your Oman digital identity.',
            status: _identity,
            onTap: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (context) => const IdentityVerificationFlow()),
              );
              if (result == true) setState(() => _identity = VerificationStatus.verified);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _VerificationTile(
            icon: Icons.home_work_outlined,
            title: 'Property Verification',
            subtitle: 'Verify ownership documents for a listing.',
            status: _property,
            onTap: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (context) => const PropertyVerificationFlow()),
              );
              if (result == true) setState(() => _property = VerificationStatus.underReview);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _VerificationTile(
            icon: Icons.apartment_rounded,
            title: 'Business Verification',
            subtitle: 'Verify your business to list as a professional.',
            status: _business,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _VerificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VerificationStatus status;
  final VoidCallback onTap;

  const _VerificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: AppIconSize.lg),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                  const SizedBox(height: AppSpacing.xs),
                  VerificationBadge(status: status),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.mist),
          ],
        ),
      ),
    );
  }
}
