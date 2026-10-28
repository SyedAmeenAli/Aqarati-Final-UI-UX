import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/aq/aq_primitives.dart';
import '../../core/aq/aq_scene.dart';
import '../../core/aq/aq_tokens.dart';
import '../../core/aq/aq_typography.dart';
import '../../core/auth/auth_repository.dart';
import '../../core/localization/flow_strings.dart';
import '../../data/api/account_api.dart' show meProvider, verificationProvider;
import '../agent/agent_shell.dart' show WorkspaceSideRail;
import '../role_home/home_agent.dart' show AgentHome;
import '../role_home/home_construction.dart';
import '../role_home/home_developer.dart';
import '../role_home/home_studio.dart';
import '../role_home/role_home_model.dart';
import '../viewing/widgets/viewing_components.dart';
import '../viewing/widgets/viewing_scaffold.dart';

/// One destination of a professional workspace.
class ProTab {
  final String icon, labelKey, route;

  /// Locations that keep this tab selected.
  final List<String> prefixes;
  const ProTab(this.icon, this.labelKey, this.route, this.prefixes);
}

/// The four professional roles each get their own navigation: different tabs, different words,
/// pointing at the pages that role actually works in. (Development and construction work in
/// projects; architecture and design work from a portfolio.)
List<ProTab> proTabsFor(HomeRole r) => switch (r) {
  HomeRole.developer => const [
    ProTab('home', 'pn.home', '/pro', ['/pro/home']),
    ProTab('development', 'pn.projects', '/app/account/workspace/projects', ['/app/account/workspace/projects', '/workspace/projects']),
    ProTab('activity', 'pn.enquiries', '/app/account/workspace/leads', ['/app/account/workspace/leads', '/workspace/leads']),
    ProTab('account', 'pn.company', '/app/account/workspace/profile', ['/app/account/workspace/profile']),
    ProTab('more', 'pn.more', '/pro/more', ['/pro/more', '/app/account/workspace/reviews', '/app/account/workspace']),
  ],
  HomeRole.construction => const [
    ProTab('home', 'pn.home', '/pro', ['/pro/home']),
    ProTab('construction', 'pn.portfolio', '/app/account/workspace/portfolio', ['/app/account/workspace/portfolio']),
    ProTab('calendar', 'pn.requests', '/app/account/workspace/leads', ['/app/account/workspace/leads', '/workspace/leads']),
    ProTab('account', 'pn.company', '/app/account/workspace/profile', ['/app/account/workspace/profile']),
    ProTab('more', 'pn.more', '/pro/more', ['/pro/more', '/app/account/workspace/reviews', '/app/account/workspace']),
  ],
  HomeRole.architecture => const [
    ProTab('home', 'pn.studio', '/pro', ['/pro/home']),
    ProTab('architecture', 'pn.portfolio', '/app/account/workspace/portfolio', ['/app/account/workspace/portfolio', '/app/account/workspace/projects', '/workspace/projects']),
    ProTab('verified', 'pn.engagements', '/app/account/workspace/engagements', ['/app/account/workspace/engagements', '/workspace/engagements', '/app/account/workspace/leads', '/workspace/leads']),
    ProTab('account', 'pn.profile', '/app/account/workspace/profile', ['/app/account/workspace/profile']),
    ProTab('more', 'pn.more', '/pro/more', ['/pro/more', '/app/account/workspace/reviews', '/app/account/workspace']),
  ],
  HomeRole.interiorExterior => const [
    ProTab('home', 'pn.gallery', '/pro', ['/pro/home']),
    ProTab('interior', 'pn.portfolio', '/app/account/workspace/portfolio', ['/app/account/workspace/portfolio', '/app/account/workspace/projects', '/workspace/projects']),
    ProTab('verified', 'pn.engagements', '/app/account/workspace/engagements', ['/app/account/workspace/engagements', '/workspace/engagements', '/app/account/workspace/leads', '/workspace/leads']),
    ProTab('account', 'pn.profile', '/app/account/workspace/profile', ['/app/account/workspace/profile']),
    ProTab('more', 'pn.more', '/pro/more', ['/pro/more', '/app/account/workspace/reviews', '/app/account/workspace']),
  ],
  _ => const [],
};

bool isProRole(HomeRole r) =>
    r == HomeRole.developer ||
    r == HomeRole.construction ||
    r == HomeRole.architecture ||
    r == HomeRole.interiorExterior;

int proTabIndex(List<ProTab> tabs, String path) {
  // Longest matching prefix wins, so a project page stays under Projects, not under More.
  var best = -1, bestLen = -1;
  for (var i = 0; i < tabs.length; i++) {
    for (final p in tabs[i].prefixes) {
      if (path == p || path.startsWith('$p/')) {
        if (p.length > bestLen) {
          best = i;
          bestLen = p.length;
        }
      }
    }
  }
  return best < 0 ? 0 : best;
}

/// The business workspace frame for an approved Development, Construction, Architecture or
/// Interior & Exterior account. Not the customer shell, and not the agent's.
class ProShell extends ConsumerStatefulWidget {
  final Widget child;
  const ProShell({super.key, required this.child});
  @override
  ConsumerState<ProShell> createState() => _ProShellState();
}

class _ProShellState extends ConsumerState<ProShell> {
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
    final me = ref.watch(meProvider);
    final res = resolveHome(me.valueOrNull);
    final allowed = me.hasValue && isProRole(res.role);
    if (!allowed) {
      return Scaffold(
        backgroundColor: c.background,
        body: me.isLoading && !me.hasValue
            ? const Center(child: CircularProgressIndicator())
            : AQViewingScaffold(
                title: f.t('pn.noAccess.t'),
                backLabel: f.t('common.back'),
                onBack: () => aqBack(context, '/app/home'),
                children: [
                  AQNoticeCard(icon: 'lock', title: f.t('pn.noAccess.t'), body: f.t('pn.noAccess.b')),
                ],
              ),
      );
    }
    final tabs = proTabsFor(res.role);
    final path = GoRouterState.of(context).uri.path;
    final index = proTabIndex(tabs, path);
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final items = [for (final t in tabs) AQNavItem(t.icon, f.t(t.labelKey))];
    void go(int i) {
      _nav.setCompact(false);
      if (i != index || path != tabs[i].route) context.go(tabs[i].route);
    }

    final backdrop = const AQBackdrop(asset: 'assets/entry/oman_terrace_2k.jpg', quiet: true);
    return Scaffold(
      backgroundColor: c.background,
      body: wide
          ? Row(
              children: [
                WorkspaceSideRail(items: items, index: index, onSelected: go),
                Expanded(
                  child: Stack(fit: StackFit.expand, children: [backdrop, AQShellInset(height: 0, child: widget.child)]),
                ),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                backdrop,
                AQShellInset(
                  height: 84 + MediaQuery.paddingOf(context).bottom,
                  child: NotificationListener<ScrollNotification>(onNotification: _nav.onScroll, child: widget.child),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AQGlassNav(items: items, index: index, controller: _nav, onSelected: go),
                ),
              ],
            ),
    );
  }
}

/// `/pro`: the role's own home (its existing distinct page), inside the business shell.
class ProHomeScreen extends ConsumerWidget {
  const ProHomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(homeResolutionProvider).role;
    return switch (r) {
      HomeRole.developer => const DeveloperHome(),
      HomeRole.construction => const ConstructionHome(),
      HomeRole.architecture => const ArchitectureHome(),
      HomeRole.interiorExterior => const InteriorHome(),
      HomeRole.agent => const AgentHome(),
      HomeRole.buyer => const SizedBox.shrink(),
    };
  }
}

/// `/pro/more`: reviews, status, the way into the shopper app, and sign out.
class ProMoreScreen extends ConsumerWidget {
  const ProMoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final c = AQColors.of(context);
    Widget row(String icon, String title, VoidCallback onTap, {String? sub, bool danger = false}) => Semantics(
      button: true,
      focusable: true,
      onFocus: () {},
      label: sub == null ? title : '$title. $sub',
      excludeSemantics: true,
      onTap: onTap,
      child: AQPressable(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: AQSpacing.x4, vertical: AQSpacing.x2),
          child: Row(children: [
            AQIcon(icon, size: 20, color: danger ? c.danger : c.accent),
            const SizedBox(width: AQSpacing.x3),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AQTypography.of(context, AQText.bodyMedium, color: danger ? c.danger : c.ink)),
                if (sub != null) Text(sub, style: AQTypography.of(context, AQText.bodySmall, soft: true)),
              ]),
            ),
            AQIcon('chevron-right', size: 16, color: c.inkSoft, directional: true),
          ]),
        ),
      ),
    );
    Widget group(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.only(bottom: AQSpacing.x5),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(bottom: AQSpacing.x2), child: Semantics(header: true, child: Text(title, style: AQTypography.of(context, AQText.labelMedium, soft: true)))),
        Container(
          decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(AQRadius.medium), border: Border.all(color: c.hairline)),
          child: Column(children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, thickness: 1, color: c.hairline, indent: AQSpacing.x4, endIndent: AQSpacing.x4),
              rows[i],
            ],
          ]),
        ),
      ]),
    );
    return SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(AQSpacing.gutter, AQSpacing.x4, AQSpacing.gutter, AQSpacing.x6 + AQShellInset.of(context) + 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Semantics(header: true, child: Text(f.t('pn.more'), style: AQTypography.of(context, AQText.displaySmall))),
              const SizedBox(height: AQSpacing.x4),
              group(f.t('pn.m.business'), [
                row('star', f.t('pn.m.reviews'), () => context.push('/app/account/workspace/reviews')),
                row('verified', f.t('pn.m.status'), () => context.push('/verification/details')),
                row('info', f.t('pn.m.workspace'), () => context.push('/app/account/workspace')),
              ]),
              group(f.t('pn.m.account'), [
                row('home', f.t('pn.m.customer'), () => context.go('/app/explore'), sub: f.t('pn.m.customer.s')),
                row('lock', f.t('ag.more.signOut'), () async {
                  await ref.read(authRepositoryProvider).signOut();
                  ref.invalidate(meProvider);
                  ref.invalidate(verificationProvider);
                  if (context.mounted) context.go('/entry');
                }),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
