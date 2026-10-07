import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/aq/aq_documents.dart';
import '../../core/aq/aq_forms.dart';
import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_scene.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/domain/account_models.dart';
import '../../core/localization/entry_strings.dart';
import '../../core/localization/flow_strings.dart';
import '../entry/models/signup_purpose.dart';
import '../../data/api/account_api.dart';
import '../flow/screens/approval_screens.dart' show workspaceCaps;
import '../flow/widgets/flow_common.dart';

const _tabs = ['/app/home', '/app/explore', '/app/activity', '/app/account'];

/// Authenticated shell: quiet backdrop, the page, and the floating glass nav.
/// Only this shell hosts [AQGlassNav].
class AQAppShell extends StatefulWidget {
  final Widget child;
  const AQAppShell({super.key, required this.child});
  @override
  State<AQAppShell> createState() => _AQAppShellState();
}

class _AQAppShellState extends State<AQAppShell> {
  final _nav = AQNavController();

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    final location = GoRouterState.of(context).uri.path;
    final index = _tabs.indexWhere(location.startsWith).clamp(0, _tabs.length - 1);
    final items = [
      AQNavItem('home', f.t('nav.home')),
      AQNavItem('explore', f.t('nav.explore')),
      AQNavItem('activity', f.t('nav.activity')),
      AQNavItem('account', f.t('nav.account')),
    ];
    return Scaffold(
      backgroundColor: c.background,
      body: Stack(fit: StackFit.expand, children: [
        const AQBackdrop(asset: 'assets/entry/oman_terrace_2k.jpg', quiet: true),
        NotificationListener<ScrollNotification>(onNotification: _nav.onScroll, child: widget.child),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AQGlassNav(
            items: items,
            index: index,
            controller: _nav,
            onSelected: (i) {
              _nav.setCompact(false);
              if (i != index) context.go(_tabs[i]);
            },
          ),
        ),
      ]),
    );
  }
}

/// Shared page frame for the tabs: title, scrolling body, room for the nav.
class _TabPage extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _TabPage({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AQSpacing.maxContent + AQSpacing.gutter * 2),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AQSpacing.gutter, AQSpacing.x6, AQSpacing.gutter, 128),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Semantics(header: true, child: Text(title, style: AQTypography.of(context, AQText.displaySmall))),
              const SizedBox(height: AQSpacing.x6),
              ...children,
            ]),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final String text;
  const _Body(this.text);
  @override
  Widget build(BuildContext context) => Text(text, style: AQTypography.of(context, AQText.bodyMedium, soft: true));
}

/// Wraps a tab that needs the session; shows the shared loading/error frames.
class _SessionTab extends ConsumerWidget {
  final String titleKey;
  final List<Widget> Function(BuildContext, WidgetRef, MeSession) body;
  const _SessionTab({required this.titleKey, required this.body});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    return ref.watch(meProvider).when(
          loading: () => _TabPage(title: f.t(titleKey), children: const [AQSkeleton()]),
          error: (e, _) => _TabPage(title: f.t(titleKey), children: [
            AQErrorBanner(text: f.t(apiErrorKey(e))),
            AQTextButton(label: f.t('common.retry'), onPressed: () => ref.invalidate(meProvider)),
          ]),
          data: (m) => _TabPage(title: f.t(titleKey), children: body(context, ref, m)),
        );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    return _SessionTab(
      titleKey: 'home.title',
      body: (context, ref, m) {
        final cfg = m.purpose == null ? null : roleConfigs[m.purpose];
        final business = cfg != null && cfg.needsDocuments && m.grant != null;
        return [
          if (m.purpose != null) AQReviewSection(title: f.t('account.role'), children: [Padding(padding: const EdgeInsets.only(top: AQSpacing.x2), child: Text(roleTitle(context, m.purpose!), style: AQTypography.of(context, AQText.titleMedium)))]),
          if (business)
            AQReviewSection(title: f.t('home.verification'), children: [
              const SizedBox(height: AQSpacing.x2),
              Align(alignment: AlignmentDirectional.centerStart, child: AQStatusBadge(grant: m.grant!, stage: m.stage)),
              const SizedBox(height: AQSpacing.x2),
              if (m.grant == GrantState.approved) _Body(f.t('home.verified')),
              AQTextButton(label: f.t('home.viewStatus'), trailingIcon: 'chevron-right', onPressed: () => context.go('/verification')),
            ]),
          if (business && m.grant == GrantState.approved && m.purpose != null)
            AQReviewSection(title: f.t('home.workspace'), children: [
              Padding(padding: const EdgeInsets.only(top: AQSpacing.x2, bottom: AQSpacing.x1), child: Text(f.t('ws.t.${m.purpose!.name}'), style: AQTypography.of(context, AQText.titleSmall))),
              if (m.purpose == SignupPurpose.realEstateAgent) Padding(padding: const EdgeInsets.only(bottom: AQSpacing.x1), child: Text(f.t('home.buyerAgent'), style: AQTypography.of(context, AQText.labelMedium, color: AQColors.of(context).accentDeep))),
              for (final k in workspaceCaps(m.purpose!)) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(f.t(k), style: AQTypography.of(context, AQText.bodySmall, soft: true))),
            ]),
          if (!business)
            AQReviewSection(title: f.t('home.title'), children: [Padding(padding: const EdgeInsets.only(top: AQSpacing.x2), child: _Body(f.t('home.userBody')))]),
          _Body(f.t('home.soon')),
        ];
      },
    );
  }
}

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});
  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    return _TabPage(title: f.t('explore.title'), children: [_Body(f.t('home.soon'))]);
  }
}

class ActivityTab extends StatelessWidget {
  const ActivityTab({super.key});
  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    return _TabPage(title: f.t('activity.title'), children: [_Body(f.t('activity.empty'))]);
  }
}

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final f = FlowStrings.of(context);
    return _SessionTab(
      titleKey: 'account.title',
      body: (context, ref, m) {
        final current = ref.watch(localeProvider).languageCode;
        return [
          AQReviewSection(title: f.t('account.title'), children: [
            if (m.purpose != null) AQKeyValue(f.t('account.role'), roleTitle(context, m.purpose!)),
            if (m.phoneLast4 != null) AQKeyValue(f.t('account.phone'), '•••• ${m.phoneLast4}'),
          ]),
          AQReviewSection(title: f.t('account.language'), children: [
            _LangRow(title: 'English', selected: current == 'en', onTap: () => ref.read(localeProvider.notifier).state = const Locale('en')),
            _LangRow(title: 'العربية', selected: current == 'ar', onTap: () => ref.read(localeProvider.notifier).state = const Locale('ar')),
          ]),
          AQReviewSection(title: f.t('account.appearance'), children: [
            _LangRow(title: f.t('account.light'), selected: ref.watch(themeModeProvider) == ThemeMode.light, onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light),
            _LangRow(title: f.t('account.dark'), selected: ref.watch(themeModeProvider) == ThemeMode.dark, onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark),
          ]),
          AQSecondaryButton(
            label: f.t('account.signOut'),
            trailingChevron: false,
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              ref.invalidate(meProvider);
              ref.invalidate(verificationProvider);
              if (context.mounted) context.go('/entry');
            },
          ),
        ];
      },
    );
  }
}

class _LangRow extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  const _LangRow({required this.title, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AQColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      excludeSemantics: true,
      child: AQPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AQControl.tap),
          child: Row(children: [
            Expanded(child: Text(title, style: AQTypography.of(context, AQText.bodyMedium))),
            if (selected) AQIcon('check', size: AQIconSize.medium, color: c.accent),
          ]),
        ),
      ),
    );
  }
}
