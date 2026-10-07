import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';

class NotificationPrefsScreen extends StatefulWidget {
  const NotificationPrefsScreen({super.key});

  @override
  State<NotificationPrefsScreen> createState() => _NotificationPrefsScreenState();
}

class _NotificationPrefsScreenState extends State<NotificationPrefsScreen> {
  final Map<String, bool> _prefs = {
    'Property Matching Alerts': true,
    'Saved Search Updates': true,
    'Ecosystem Price Changes': false,
    'Instant Messages': true,
    'Official Enquiries': true,
    'Price Quotes & Proposals': true,
    'Property Viewing Bookings': true,
    'Payment & Invoices': true,
    'Maintenance Requests': false,
    'Ecosystem Security Alerts': true,
    'Ministry & THEQA Approvals': true,
  };

  bool _pushNotifications = true;
  bool _emailReports = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ecosystem Alerts')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Stay updated with instant push notifications, Omani SMS alerts, and news in Oman.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          Text('DELIVERY CHANNELS', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
          const SizedBox(height: AppSpacing.sm),
          _ToggleRow(title: 'Push Notifications', subtitle: 'Instant alerts on your current device', value: _pushNotifications, onChanged: (v) => setState(() => _pushNotifications = v)),
          _ToggleRow(title: 'Email Reports', subtitle: 'Contract PDFs and transaction summaries', value: _emailReports, onChanged: (v) => setState(() => _emailReports = v)),
          const Divider(height: AppSpacing.xxxl),
          Text('ALERT TYPES', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
          const SizedBox(height: AppSpacing.sm),
          Text('Search & Market Alerts', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final key in ['Property Matching Alerts', 'Saved Search Updates', 'Ecosystem Price Changes'])
            _ToggleRow(title: key, value: _prefs[key]!, onChanged: (v) => setState(() => _prefs[key] = v)),
          const SizedBox(height: AppSpacing.md),
          Text('Communication & Chat', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final key in ['Instant Messages', 'Official Enquiries', 'Price Quotes & Proposals'])
            _ToggleRow(title: key, value: _prefs[key]!, onChanged: (v) => setState(() => _prefs[key] = v)),
          const SizedBox(height: AppSpacing.md),
          Text('Operations & Bookings', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final key in ['Property Viewing Bookings', 'Payment & Invoices', 'Maintenance Requests'])
            _ToggleRow(title: key, value: _prefs[key]!, onChanged: (v) => setState(() => _prefs[key] = v)),
          const SizedBox(height: AppSpacing.md),
          Text('Security & Verification', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final key in ['Ecosystem Security Alerts', 'Ministry & THEQA Approvals'])
            _ToggleRow(title: key, value: _prefs[key]!, onChanged: (v) => setState(() => _prefs[key] = v)),
          const SizedBox(height: AppSpacing.xl),
          AqaratiButton(
            label: 'Save Notification Prefs',
            fullWidth: true,
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification preferences saved'))),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.title, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyMedium),
                if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, activeColor: AppColors.primary, onChanged: onChanged),
        ],
      ),
    );
  }
}
