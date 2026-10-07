import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Security')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Security & Sessions', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your account is protected by secure authentication. Monitor active sessions and secure your credentials here.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          _SettingsTile(
            icon: Icons.shield_outlined,
            title: 'THEQA Identity',
            subtitle: 'Oman National PKI · Connected',
            trailing: _StatusPill(label: 'Connected', color: AppColors.verified),
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.devices_outlined,
            title: 'Active Sessions',
            subtitle: '3 devices logged in',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const _ActiveSessionsScreen()),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.history_rounded,
            title: 'Sign-In Activity',
            subtitle: 'Last event: identity verified via THEQA yesterday',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const _SignInActivityScreen()),
            ),
          ),
          const Divider(height: AppSpacing.xxxl),
          Text('App Security', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.fingerprint_rounded,
            title: 'Biometric Sign-In',
            subtitle: 'Face ID Enabled',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsTile(
            icon: Icons.password_rounded,
            title: 'Security PIN',
            subtitle: 'Configured',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionsScreen extends StatelessWidget {
  const _ActiveSessionsScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Active Sessions')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            "These are devices that have recently logged into your AQARATI account. If you don't recognize a session, sign out immediately.",
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Current device', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          const _DeviceTile(icon: Icons.phone_iphone_rounded, name: 'iPhone 15 Pro', detail: 'Muscat, Oman · Active now', isCurrent: true),
          const SizedBox(height: AppSpacing.xl),
          Text('Other active devices', style: theme.textTheme.labelMedium),
          const SizedBox(height: AppSpacing.sm),
          const _DeviceTile(icon: Icons.laptop_mac_rounded, name: 'MacBook Pro 16', detail: 'Active 2 hours ago'),
          const SizedBox(height: AppSpacing.sm),
          const _DeviceTile(icon: Icons.tablet_mac_rounded, name: 'iPad Air', detail: 'AQARATI App · iOS · Salalah, Oman · Active 3 days ago'),
          const SizedBox(height: AppSpacing.sm),
          const _DeviceTile(icon: Icons.desktop_windows_outlined, name: 'Windows Desktop', detail: 'Chrome · Windows · Sohar, Oman'),
          const SizedBox(height: AppSpacing.xxxl),
          AqaratiButton(
            label: 'Sign out of all other devices',
            variant: AqaratiButtonVariant.secondary,
            fullWidth: true,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm it\'s you'),
                  content: const Text('Verify your identity to continue with this action.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Signed out of all other devices')));
                      },
                      child: const Text('Use THEQA'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SignInActivityScreen extends StatelessWidget {
  const _SignInActivityScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final events = [
      ('Signed in', 'Safari · MacBook Pro 16', 'Today, 9:41 AM · Muscat, Oman', Icons.login_rounded),
      ('Identity verified via THEQA', 'National Single Sign-On system', 'Yesterday, 3:15 PM · Oman', Icons.verified_user_outlined),
      ('Password changed', 'Secure self-service portal', '3 days ago · Muscat, Oman', Icons.key_outlined),
      ('New device added', 'iPhone 15 Pro authenticated', 'Last week, Jan 15 · Muscat, Oman', Icons.add_to_home_screen_outlined),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Sign-in activity')),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, i) {
          final (title, subtitle, time, icon) = events[i];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: AppColors.sand, shape: BoxShape.circle),
                child: Icon(icon, size: AppIconSize.compact, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(time, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String detail;
  final bool isCurrent;

  const _DeviceTile({required this.icon, required this.name, required this.detail, this.isCurrent = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: isCurrent ? AppColors.primary.withValues(alpha: 0.3) : AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.slate),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: theme.textTheme.titleSmall),
                    if (isCurrent) ...[
                      const SizedBox(width: AppSpacing.sm),
                      const _StatusPill(label: 'THIS DEVICE', color: AppColors.verified),
                    ],
                  ],
                ),
                Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.trailing, required this.onTap});

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
            if (trailing != null) trailing! else const Icon(Icons.chevron_right_rounded, color: AppColors.mist),
          ],
        ),
      ),
    );
  }
}
