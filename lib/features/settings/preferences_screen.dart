import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/aqarati_button.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String _language = 'English';
  String _textSize = 'Default';
  String _appearance = 'System';
  bool _reduceMotion = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Preferences', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text('Tailor your Omani real estate search', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          Text('LANGUAGE', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
          const SizedBox(height: AppSpacing.sm),
          _Row(
            icon: Icons.language_rounded,
            title: 'App Language',
            trailing: _language,
            onTap: () async {
              final result = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (context) => _LanguageScreen(current: _language)),
              );
              if (result != null) setState(() => _language = result);
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('DISPLAY & ACCESSIBILITY', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
          const SizedBox(height: AppSpacing.sm),
          _Row(
            icon: Icons.text_fields_rounded,
            title: 'Text Size',
            trailing: _textSize,
            onTap: () async {
              final result = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (context) => _TextSizeScreen(current: _textSize)),
              );
              if (result != null) setState(() => _textSize = result);
            },
          ),
          _Row(
            icon: Icons.visibility_outlined,
            title: 'Appearance',
            trailing: _appearance,
            onTap: () async {
              final result = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (context) => _AppearanceScreen(current: _appearance)),
              );
              if (result != null) setState(() => _appearance = result);
            },
          ),
          _ToggleTile(
            icon: Icons.accessibility_new_rounded,
            title: 'Reduce Motion',
            subtitle: 'Limit animations across maps & galleries',
            value: _reduceMotion,
            onChanged: (v) => setState(() => _reduceMotion = v),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('PERMISSIONS & PRIVACY', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
          const SizedBox(height: AppSpacing.sm),
          _Row(icon: Icons.notifications_none_rounded, title: 'Notification Settings', onTap: () {}),
          _Row(icon: Icons.location_on_outlined, title: 'Location (Oman Maps)', trailing: 'While Using', onTap: () {}),
          _Row(icon: Icons.shield_outlined, title: 'Privacy Settings', onTap: () {}),
        ],
      ),
    );
  }
}

class _LanguageScreen extends StatelessWidget {
  final String current;

  const _LanguageScreen({required this.current});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Language')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _LanguageOption(label: 'English', subtitle: 'App standard interface', selected: current == 'English', onTap: () => Navigator.of(context).pop('English')),
          const SizedBox(height: AppSpacing.md),
          _LanguageOption(label: 'العربية', subtitle: 'الواجهة القياسية لعقاراتي', selected: current == 'العربية', onTap: () => Navigator.of(context).pop('العربية')),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(
              children: [
                const Icon(Icons.refresh_rounded, size: AppIconSize.compact, color: AppColors.slate),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text('App will restart to apply language changes.', style: theme.textTheme.bodySmall)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({required this.label, required this.subtitle, required this.selected, required this.onTap});

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
          border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: selected ? AppBorder.strong : AppBorder.thin),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.titleSmall),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, color: selected ? AppColors.primary : AppColors.mist),
          ],
        ),
      ),
    );
  }
}

class _TextSizeScreen extends StatefulWidget {
  final String current;

  const _TextSizeScreen({required this.current});

  @override
  State<_TextSizeScreen> createState() => _TextSizeScreenState();
}

class _TextSizeScreenState extends State<_TextSizeScreen> {
  static const _sizes = ['Small', 'Default', 'Medium', 'Large'];
  late int _index = _sizes.indexOf(widget.current).clamp(0, 3);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = 0.85 + (_index * 0.15);
    return Scaffold(
      appBar: AppBar(title: const Text('Text Size')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Adjust typography scale for comfortable browsing', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.line)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PREVIEW CARD', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
                const SizedBox(height: AppSpacing.sm),
                Text('Luxury Villa in Al Mouj, Muscat', style: theme.textTheme.titleLarge?.copyWith(fontSize: (theme.textTheme.titleLarge?.fontSize ?? 22) * scale)),
                const SizedBox(height: 4),
                Text(
                  'Featuring breathtaking ocean views and modern Omani architectural highlights.',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('A', style: TextStyle(fontSize: 14, color: AppColors.mist)),
              Text('Drag slider below', style: theme.textTheme.titleSmall),
              const Text('A', style: TextStyle(fontSize: 22, color: AppColors.mist)),
            ],
          ),
          Slider(
            value: _index.toDouble(),
            min: 0,
            max: 3,
            divisions: 3,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _index = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _sizes.map((s) => Text(s, style: theme.textTheme.labelSmall)).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _index = 1),
              icon: const Icon(Icons.refresh_rounded, size: AppIconSize.compact),
              label: const Text('Reset to Default Size'),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AqaratiButton(label: 'Save', fullWidth: true, onPressed: () => Navigator.of(context).pop(_sizes[_index])),
        ],
      ),
    );
  }
}

class _AppearanceScreen extends StatefulWidget {
  final String current;

  const _AppearanceScreen({required this.current});

  @override
  State<_AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<_AppearanceScreen> {
  late String _mode = widget.current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = _mode == 'Dark';
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Choose your primary viewing preference', style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _AppearanceOption(label: 'Light', icon: Icons.wb_sunny_outlined, selected: _mode == 'Light', onTap: () => setState(() => _mode = 'Light')),
              const SizedBox(width: AppSpacing.md),
              _AppearanceOption(label: 'Dark', icon: Icons.nightlight_outlined, selected: _mode == 'Dark', onTap: () => setState(() => _mode = 'Dark')),
              const SizedBox(width: AppSpacing.md),
              _AppearanceOption(label: 'System', icon: Icons.smartphone_rounded, selected: _mode == 'System', onTap: () => setState(() => _mode = 'System')),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('PREVIEW', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.mist)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? AppColors.neutral900 : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.line),
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            alignment: Alignment.bottomLeft,
            child: Text('Earthy Interior', style: theme.textTheme.titleSmall?.copyWith(color: isDark ? Colors.white : AppColors.ink, fontStyle: FontStyle.italic)),
          ),
          const SizedBox(height: AppSpacing.xl),
          AqaratiButton(label: 'Save', fullWidth: true, onPressed: () => Navigator.of(context).pop(_mode)),
        ],
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AppearanceOption({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: selected ? AppColors.primary : AppColors.line, width: selected ? AppBorder.strong : AppBorder.thin),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.slate),
              const SizedBox(height: AppSpacing.sm),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined, size: AppIconSize.compact, color: selected ? AppColors.primary : AppColors.mist),
            ],
          ),
        ),
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
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: theme.textTheme.bodyMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) Text(trailing!, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mist),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
      trailing: Switch(value: value, activeColor: AppColors.primary, onChanged: onChanged),
    );
  }
}
