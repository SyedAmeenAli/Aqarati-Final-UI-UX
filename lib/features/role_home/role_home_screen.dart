import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/aq/aq_tokens.dart';
import '../../data/api/account_api.dart' show meProvider;
import '../devbuild/db_widgets.dart' show DbSkeleton;
import '../workspace/aq_home.dart' show AQHomeScreen;
import 'home_agent.dart';
import 'home_construction.dart';
import 'home_developer.dart';
import 'home_studio.dart';
import 'role_home_model.dart';
import 'role_home_widgets.dart';

/// The Home tab. Resolves the signed-in session into one of six homes from the real grant.
/// Everything that is not an approved role (guests, buyers, drafts, pending, rejected,
/// suspended) gets the buyer home; a business or agent application that is not approved adds a
/// status banner that links to the real verification screens.
class RoleHomeScreen extends ConsumerWidget {
  const RoleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = ref.watch(homeResolutionProvider);
    // Until the session is known, show a quiet placeholder instead of a buyer page that would
    // flash and then be replaced by a role home. A failed lookup (guest) resolves to the buyer home.
    final me = ref.watch(meProvider);
    if (me.isLoading && !me.hasValue && !me.hasError) {
      return const SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(AQSpacing.gutter, AQSpacing.x6, AQSpacing.gutter, 0),
          child: Column(children: [DbSkeleton(height: 56), SizedBox(height: AQSpacing.x4), DbSkeleton(height: 220), SizedBox(height: AQSpacing.x4), DbSkeleton(height: 120)]),
        ),
      );
    }
    final Widget home = switch (r.role) {
      HomeRole.buyer => AQHomeScreen(topSlot: _buyerTop(ref, r)),
      HomeRole.agent => const AgentHome(),
      HomeRole.developer => const DeveloperHome(),
      HomeRole.construction => const ConstructionHome(),
      HomeRole.architecture => const ArchitectureHome(),
      HomeRole.interiorExterior => const InteriorHome(),
    };
    return AnimatedSwitcher(
      duration: AQMotion.scaled(context, const Duration(milliseconds: 220)),
      child: KeyedSubtree(key: ValueKey(r.role), child: home),
    );
  }

  Widget? _buyerTop(WidgetRef ref, HomeResolution r) {
    if (r.canSwitch) {
      return Padding(
        padding: const EdgeInsets.only(top: AQSpacing.x3, bottom: AQSpacing.x4),
        child: RoleWorkspaceSwitcher(selected: HomeWorkspace.buyer, onChanged: (w) => ref.read(homeWorkspaceProvider.notifier).state = w),
      );
    }
    if (r.hasPendingApplication) {
      return Padding(padding: const EdgeInsets.only(top: AQSpacing.x3), child: RoleStatusBanner(grant: r.pendingGrant!, stage: r.pendingStage));
    }
    return null;
  }
}
