import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/account_models.dart';
import '../../data/api/account_api.dart';
import '../devbuild/db_models.dart';
import '../entry/models/signup_purpose.dart';

/// Which of the six home experiences a session lands on.
enum HomeRole { buyer, agent, developer, construction, architecture, interiorExterior }

/// An approved agent is also a buyer and can switch between the two.
enum HomeWorkspace { buyer, agent }

/// The outcome of resolving a session into a home. Pure data so it can be unit-tested.
///
/// A role home is only ever chosen from an APPROVED grant. Any other business state (draft,
/// pending, awaiting second approval, resubmission, rejected, suspended) falls back to the
/// buyer home and carries the grant so the home can show the real status and link to
/// `/verification`. Choosing a role while signing up is never a grant.
class HomeResolution {
  final HomeRole role;

  /// Set when the person has a business or agent application that is not approved.
  final SignupPurpose? pendingPurpose;
  final GrantState? pendingGrant;
  final ReviewStage? pendingStage;

  /// True for an approved agent: the Buyer / Agent switcher is shown on both homes.
  final bool canSwitch;
  const HomeResolution(this.role, {this.pendingPurpose, this.pendingGrant, this.pendingStage, this.canSwitch = false});

  bool get hasPendingApplication => pendingPurpose != null && pendingGrant != null;
  bool get isProfessionalCompany => role != HomeRole.buyer && role != HomeRole.agent;
  ProType? get proType => switch (role) {
        HomeRole.developer => ProType.developer,
        HomeRole.construction => ProType.construction,
        HomeRole.architecture => ProType.architecture,
        HomeRole.interiorExterior => ProType.interiorExterior,
        _ => null,
      };
}

/// [chosen] is the person's last Buyer / Agent choice; null means "not chosen yet", which
/// opens an approved agent in the agent workspace.
HomeResolution resolveHome(MeSession? me, {HomeWorkspace? chosen}) {
  if (me == null || me.account != AccountState.active) return const HomeResolution(HomeRole.buyer);
  final purpose = me.purpose;
  final grant = me.grant;
  final cfg = purpose == null ? null : roleConfigs[purpose];
  if (purpose == null || cfg == null || !cfg.needsDocuments) return const HomeResolution(HomeRole.buyer);

  if (grant == GrantState.approved) {
    if (purpose == SignupPurpose.realEstateAgent) {
      final ws = chosen ?? HomeWorkspace.agent;
      return HomeResolution(ws == HomeWorkspace.agent ? HomeRole.agent : HomeRole.buyer, canSwitch: true);
    }
    return HomeResolution(switch (proTypeOfPurpose(purpose)) {
      ProType.developer => HomeRole.developer,
      ProType.construction => HomeRole.construction,
      ProType.architecture => HomeRole.architecture,
      ProType.interiorExterior => HomeRole.interiorExterior,
      null => HomeRole.buyer,
    });
  }
  // Not approved: buyer home plus the honest status of the application, if one exists.
  if (grant == null) return const HomeResolution(HomeRole.buyer);
  return HomeResolution(HomeRole.buyer, pendingPurpose: purpose, pendingGrant: grant, pendingStage: me.stage);
}

/// The last Buyer / Agent choice in this app session (not persisted, not sent anywhere).
final homeWorkspaceProvider = StateProvider<HomeWorkspace?>((ref) => null);

/// Home resolution for the signed-in session. Loading and signed-out both resolve to the
/// buyer home so guests and first paint never flash a business screen.
final homeResolutionProvider = Provider.autoDispose<HomeResolution>((ref) {
  final me = ref.watch(meProvider).valueOrNull;
  final chosen = ref.watch(homeWorkspaceProvider);
  return resolveHome(me, chosen: chosen);
});
