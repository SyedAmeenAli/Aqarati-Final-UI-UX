import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_models.dart';
import 'admin_repository.dart';

/// Where the person is on the way in. The router reads this and refuses every protected address
/// until the stage is [AdminAuthStage.active]; the service refuses the data as well.
class AdminAuthController extends StateNotifier<AdminAuthState> {
  AdminAuthController(this.ref) : super(AdminAuthState.signedOut);
  final Ref ref;

  Future<void> signIn(String email, String password) async {
    await ref.read(adminAuthRepositoryProvider).signIn(email, password);
    state = const AdminAuthState(AdminAuthStage.needsTotp);
  }

  Future<void> verifyTotp(String code) async {
    final s = await ref.read(adminAuthRepositoryProvider).verifyTotp(code);
    state = AdminAuthState(AdminAuthStage.active, session: s);
  }

  Future<void> signOut() async {
    await ref.read(adminAuthRepositoryProvider).signOut();
    state = AdminAuthState.signedOut;
  }

  /// The service said the session ended: back to sign-in, with the reason.
  void expire() {
    if (state.stage == AdminAuthStage.signedOut) return;
    state = const AdminAuthState(AdminAuthStage.signedOut, notice: 'expired');
  }

  void backToLogin() => state = AdminAuthState.signedOut;
}

final adminAuthProvider =
    StateNotifierProvider<AdminAuthController, AdminAuthState>(
      (ref) => AdminAuthController(ref),
    );
