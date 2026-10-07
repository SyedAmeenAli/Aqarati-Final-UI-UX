import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthProviderKind { google, apple }

sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess();
}

class AuthUnavailable extends AuthResult {
  const AuthUnavailable();
}

class AuthFailure extends AuthResult {
  final String message;
  const AuthFailure(this.message);
}

/// Why a Firebase email/password call failed, in terms the UI can word.
/// Never reveals whether an account exists (generic wording).
enum AuthError { invalidCredentials, weakPassword, network, tooManyRequests, expiredCode, unavailable, unknown }

class AuthException implements Exception {
  final AuthError error;
  const AuthException(this.error);
}

/// Contract for Firebase Authentication. Credentials go to Firebase, NEVER to
/// the Aqarati API; the API only receives the Firebase ID token.
/// Authentication success is NOT business verification: the app resolves
/// roles and state afterwards via GET /me.
abstract class AuthRepository {
  Future<AuthResult> signInWithProvider(AuthProviderKind kind);
  Future<void> signInWithEmail(String email, String password);
  Future<void> createUserWithEmail(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> confirmPasswordReset(String oobCode, String newPassword);
  Future<void> signOut();
  Future<String?> currentIdToken();
}

/// Default when no Firebase implementation is wired: honest, never pretends.
class UnavailableAuthRepository implements AuthRepository {
  const UnavailableAuthRepository();
  @override
  Future<AuthResult> signInWithProvider(AuthProviderKind kind) async => const AuthUnavailable();
  @override
  Future<void> signInWithEmail(String email, String password) => throw const AuthException(AuthError.unavailable);
  @override
  Future<void> createUserWithEmail(String email, String password) => throw const AuthException(AuthError.unavailable);
  @override
  Future<void> sendPasswordResetEmail(String email) => throw const AuthException(AuthError.unavailable);
  @override
  Future<void> confirmPasswordReset(String oobCode, String newPassword) => throw const AuthException(AuthError.unavailable);
  @override
  Future<void> signOut() async {}
  @override
  Future<String?> currentIdToken() async => null;
}

/// Overridden in main by the demo or the real implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) => const UnavailableAuthRepository());
