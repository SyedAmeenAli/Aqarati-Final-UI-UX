import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Column(
              children: [
                const AqaratiLogoMark(height: 64),
                const SizedBox(height: AppSpacing.md),
                Text('AQARATI', style: theme.textTheme.headlineSmall),
                Text('عقاراتي', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary)),
                const SizedBox(height: AppSpacing.xs),
                Text("Oman's property and home ecosystem", style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: AppIconSize.compact, color: AppColors.slate),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Licensed by the Ministry of Housing and Urban Planning, Sultanate of Oman. Supporting localized transparent OMR pricing.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('INFORMATION & LEGAL', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
          const SizedBox(height: AppSpacing.sm),
          _Row(icon: Icons.menu_book_outlined, title: 'Product Information', onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const _ProductInfoScreen()),
          )),
          _Row(icon: Icons.description_outlined, title: 'Terms & Conditions', onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const _LegalDocScreen(
              title: 'Terms & Conditions',
              heading: 'AQARATI Platform Terms',
              noticeLabel: 'LEGAL NOTICE',
              noticeText: '[Terms and conditions content to be provided before launch]',
              noticeColor: AppColors.sand600,
              sections: [
                ('1. Platform Services', 'Subject to future compliance modifications, the AQARATI system provides online mediation, informational directories, and home management software under rules set by Omani ministerial decrees.'),
                ('2. Licensing and Registration', 'To list real estate properties or services, individuals must hold a valid Omani Brokerage License or commercial registration (Sijil Commercial).'),
                ('3. Currency and Fees', 'All transaction values, quotes, and listings displayed must be calculated and transacted in Omani Rials (OMR) unless explicitly specified otherwise.'),
              ],
            )),
          )),
          _Row(icon: Icons.shield_outlined, title: 'Privacy Policy', onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const _LegalDocScreen(
              title: 'Privacy Policy',
              heading: 'Sovereign Data Privacy',
              noticeLabel: 'COMPLIANCE DIRECTIVE',
              noticeText: '[Privacy policy content to be provided before launch]',
              noticeColor: AppColors.secondary,
              sections: [
                ('I. Information Collection Scope', 'Drafted to specify national ID systems, contact preferences, and location data collection boundaries.'),
                ('II. Use of Personal Data', 'Outlining processing protocols for property ownership registration verifications and escrow operations.'),
                ('III. Data Security & Storage', 'Governing physical and digital storage of data strictly on domestic server farms within the Sultanate of Oman.'),
              ],
            )),
          )),
          _Row(icon: Icons.workspace_premium_outlined, title: 'Licenses & Attributions', trailing: 'OSS', onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const _LicensesScreen()),
          )),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Column(
              children: [
                Text('Version 2.4.0 (Oman Build)', style: theme.textTheme.bodySmall),
                Text('© 2026 AQARATI. All rights reserved.', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInfoScreen extends StatelessWidget {
  const _ProductInfoScreen();

  static const _items = [
    (Icons.search_rounded, 'Find Properties', 'Browse verified listings across Muscat, Salalah, Sohar and beyond with transparent pricing in OMR.'),
    (Icons.groups_outlined, 'Discover Professionals', 'Connect directly with verified brokers, local developers, and certified home improvement experts.'),
    (Icons.verified_outlined, 'Verify Identity', 'Secure integrated digital verification with your Omani civil status system (PKI / National ID).'),
    (Icons.request_quote_outlined, 'Request Services', 'Get quotes, book reliable home services, and complete payments securely within the system.'),
    (Icons.house_outlined, 'Manage your home', 'Access your digital deeds, monitor utilities, and maintain your property status from your personal dashboard.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About AQARATI')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('The Home Ecosystem', style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'AQARATI simplifies Omani real estate. Discover authentic listings, vetted regional service providers, and secure document vaults on one unified sovereign portal.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final item in _items)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: Icon(item.$1, color: AppColors.secondary),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$2, style: theme.textTheme.titleSmall),
                        Text(item.$3, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LegalDocScreen extends StatelessWidget {
  final String title;
  final String heading;
  final String noticeLabel;
  final String noticeText;
  final Color noticeColor;
  final List<(String, String)> sections;

  const _LegalDocScreen({
    required this.title,
    required this.heading,
    required this.noticeLabel,
    required this.noticeText,
    required this.noticeColor,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(heading, style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text('Last Updated: October 15, 2024', style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: noticeColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: noticeColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(noticeLabel, style: theme.textTheme.labelSmall?.copyWith(color: noticeColor)),
                const SizedBox(height: 4),
                Text(noticeText, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final s in sections) ...[
            Text(s.$1, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(s.$2, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _LicensesScreen extends StatelessWidget {
  const _LicensesScreen();

  static const _licenses = [
    ('React Native Core', 'v0.72.6', 'MIT'),
    ('OpenSSL Encryption', 'v3.1.2', 'Apache 2.0'),
    ('Mapbox GL Mobile', 'v10.15.0', 'BSD-3-Clause'),
    ('FontAwesome Pro', 'v6.4.2', 'SIL OFL 1.1'),
    ('FastImage Native', 'v8.6.3', 'MIT'),
    ('Lottie Animations', 'v4.1.0', 'Apache 2.0'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Licenses')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Open Source Software', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'The AQARATI platform incorporates open source modules. Below are the key third-party libraries and compliance licenses utilized.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          for (final l in _licenses)
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.$1, style: theme.textTheme.titleSmall),
                        Text(l.$2, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(AppRadius.sm)),
                    child: Text(l.$3, style: theme.textTheme.labelSmall),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.green50, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WARRANTY DISCLAIMER', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.secondary)),
                const SizedBox(height: 4),
                Text(
                  'These software elements are distributed "AS IS" without warranties or conditions of any kind, either express or implied, according to each individual open-source license copyright.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _Row({required this.icon, required this.title, this.trailing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(title, style: theme.textTheme.bodyMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Container(
              margin: const EdgeInsets.only(right: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Text(trailing!, style: theme.textTheme.labelSmall),
            ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mist),
        ],
      ),
      onTap: onTap,
    );
  }
}
