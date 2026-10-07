import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';

class AccountSwitchScreen extends StatefulWidget {
  const AccountSwitchScreen({super.key});

  @override
  State<AccountSwitchScreen> createState() => _AccountSwitchScreenState();
}

class _AccountSwitchScreenState extends State<AccountSwitchScreen> {
  bool _isBusiness = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Your Account')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
            child: Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: AppColors.sand, child: const Icon(Icons.person_outline, color: AppColors.slate)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Ahmed Al-Rashdi', style: theme.textTheme.titleSmall),
                          const SizedBox(width: AppSpacing.sm),
                          const _Pill(label: 'Verified', color: AppColors.verified),
                        ],
                      ),
                      Text('Omani National ID · ****9847', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Choose how you want to use AQARATI', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Switching profiles allows you to cleanly separate personal investments from your agency business listings.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          _ProfileCard(
            icon: Icons.person_outline_rounded,
            title: 'Personal Profile',
            subtitle: 'For finding and managing your home. Search Muscat villas, chat with landlord brokers, keep property bookmarks, and request quotes in OMR.',
            active: !_isBusiness,
            onTap: () => setState(() => _isBusiness = false),
          ),
          const SizedBox(height: AppSpacing.md),
          _ProfileCard(
            icon: Icons.business_center_outlined,
            title: 'Business Profile',
            subtitle: 'For managing your services and projects. Showcase licensed brokerage services, manage leads, track payments, and verify documents with Ministry of Housing.',
            active: _isBusiness,
            onTap: () => setState(() => _isBusiness = true),
          ),
          if (_isBusiness) ...[
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.red200)),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Needs Attention', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.error)),
                        Text(
                          'Your business application requires additional details. 2 of 3 documents are pending final activation.',
                          style: theme.textTheme.bodySmall,
                        ),
                        TextButton(
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const _BusinessVerificationScreen()),
                          ),
                          child: const Text('View Feedback'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BusinessVerificationScreen extends StatelessWidget {
  const _BusinessVerificationScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Business verification')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.red50, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.red200)),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Needs Attention', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.error)),
                      Text('Review status updated 2h ago', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Submitted Documents', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          _DocRow(title: 'Ministry Commercial Registration (CR)', detail: 'Approved Jan 12, 2026', status: 'Verified', color: AppColors.verified),
          _DocRow(title: 'Brokerage Broker License (MoHUP)', detail: 'Submitted Jan 15, 2026', status: 'Under review', color: AppColors.pending),
          _DocRow(
            title: 'Chamber of Commerce Membership',
            detail: 'Requires certified signature file',
            status: 'Needs attention',
            color: AppColors.error,
            action: 'Resubmit',
          ),
          const SizedBox(height: AppSpacing.xl),
          AqaratiButton(
            label: 'Resubmit Documents',
            fullWidth: true,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document resubmission started'))),
          ),
        ],
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final String title;
  final String detail;
  final String status;
  final Color color;
  final String? action;

  const _DocRow({required this.title, required this.detail, required this.status, required this.color, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                    _Pill(label: status, color: color),
                  ],
                ),
                Text(detail, style: theme.textTheme.bodySmall),
                if (action != null)
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                    onPressed: () {},
                    child: Text(action!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final VoidCallback onTap;

  const _ProfileCard({required this.icon, required this.title, required this.subtitle, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: active ? AppColors.sand50 : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: active ? AppColors.primary : AppColors.line, width: active ? AppBorder.strong : AppBorder.thin),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(radius: 20, backgroundColor: AppColors.sand, child: Icon(icon, color: AppColors.primary)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                      if (active) const _Pill(label: 'Active', color: AppColors.verified),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;

  const _Pill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}
