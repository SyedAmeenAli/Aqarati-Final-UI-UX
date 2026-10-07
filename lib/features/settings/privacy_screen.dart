import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Your Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Manage Your Data', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Control how AQARATI uses your information to deliver Oman's premium property experience.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          _PrivacyTile(
            icon: Icons.person_outline_rounded,
            title: 'Personal Information',
            subtitle: 'Manage your basic profile, contact and Omani ID details.',
            onTap: () {},
          ),
          _PrivacyTile(
            icon: Icons.verified_user_outlined,
            title: 'Identity & Verification',
            subtitle: 'Secure verification documents for rental contracts and property listing.',
            onTap: () {},
          ),
          _PrivacyTile(
            icon: Icons.map_outlined,
            title: 'Location & Maps',
            subtitle: 'Control map access to explore prime Omani estates and amenities.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const _LocationAccessScreen()),
            ),
          ),
          _PrivacyTile(
            icon: Icons.notifications_none_rounded,
            title: 'Communication & Alert Settings',
            subtitle: 'Choose how you receive matches, market trends and WhatsApp updates.',
            onTap: () {},
          ),
          _PrivacyTile(
            icon: Icons.folder_outlined,
            title: 'My Documents Vault',
            subtitle: 'Review property deeds, tenancy agreements, and lease documentation.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const _DocumentVaultScreen()),
            ),
          ),
          const Divider(height: AppSpacing.xxxl),
          _PrivacyTile(
            icon: Icons.file_download_outlined,
            title: 'Your Information & Data Options',
            subtitle: 'Request a copy, review data categories, or request account deletion.',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const _DataOptionsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationAccessScreen extends StatefulWidget {
  const _LocationAccessScreen();

  @override
  State<_LocationAccessScreen> createState() => _LocationAccessScreenState();
}

class _LocationAccessScreenState extends State<_LocationAccessScreen> {
  bool _locationEnabled = true;
  bool _nearbySearch = true;
  bool _interactiveMap = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Location')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(color: AppColors.sand, shape: BoxShape.circle),
              child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 40),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Location Preference', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tailor how geographical data enhances your real estate searches in Oman.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          _ToggleRow(
            title: 'Location Enabled',
            subtitle: 'Allow AQARATI to access your GPS to surface local Omani neighborhoods.',
            value: _locationEnabled,
            onChanged: (v) => setState(() => _locationEnabled = v),
          ),
          _ToggleRow(
            title: 'Nearby Search',
            subtitle: 'Instantly prioritize properties and compounds closest to your current coordinates.',
            value: _nearbySearch,
            onChanged: (v) => setState(() => _nearbySearch = v),
          ),
          _ToggleRow(
            title: 'Interactive Map Experience',
            subtitle: 'Enable map rendering for landmarks, schools, and hospitals near selected listings.',
            value: _interactiveMap,
            onChanged: (v) => setState(() => _interactiveMap = v),
          ),
        ],
      ),
    );
  }
}

class _DocumentVaultScreen extends StatelessWidget {
  const _DocumentVaultScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Your Documents')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: AppColors.sand900, shape: BoxShape.circle),
                  child: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Secured Document Vault', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Any verification files you upload (such as Omani National ID, passport, or ownership deeds) are fully encrypted and only visible during official leasing or verification processes.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _PrivacyTile(icon: Icons.enhanced_encryption_outlined, title: 'End-to-End Encryption', subtitle: 'Data is scrambled in transit and at rest in accordance with Omani tech compliance.', onTap: () {}),
          _PrivacyTile(icon: Icons.auto_delete_outlined, title: 'Auto-Purge Cycles', subtitle: 'Temporary application documents are fully deleted 30 days after verification approval.', onTap: () {}),
          _PrivacyTile(icon: Icons.admin_panel_settings_outlined, title: 'Authorized Access Only', subtitle: 'Only your designated Omani estate agent or verified broker can review submissions.', onTap: () {}),
        ],
      ),
    );
  }
}

class _DataOptionsScreen extends StatelessWidget {
  const _DataOptionsScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Your Data Options')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Personal Control', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'AQARATI ensures premium transparency. Request, download, or fully clear your mobile record below.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.download_outlined, color: AppColors.slate),
                const SizedBox(height: AppSpacing.sm),
                Text('Request a Copy of Information', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Receive a comprehensive export of your saved coordinates, preferences, verification logs, and active records in a secured PDF or JSON format.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AqaratiButton(
                  label: 'Request Data File',
                  variant: AqaratiButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Data file requested — check your email'))),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.red50,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.red200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                const SizedBox(height: AppSpacing.sm),
                Text('Request Account Deletion', style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  'Permanently purge your search index, preferences, and verified files. Please note active tenancy contracts cannot be deleted until lease completion.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AqaratiButton(
                  label: 'Initiate Deletion',
                  fullWidth: true,
                  onPressed: () => _confirmDeletion(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deleting your AQARATI account is irreversible'),
        content: const Text(
          'All bookmarked properties in Muscat, Salalah, and Sohar will lose digital verification links. Active tenancy contracts and verified THEQA information will be disconnected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel and Keep Account')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Deletion Flow'),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, activeColor: AppColors.primary, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PrivacyTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PrivacyTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
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
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(subtitle, style: theme.textTheme.bodySmall),
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
