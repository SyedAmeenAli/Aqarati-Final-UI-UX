import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_repository.dart';
import '../api/account_api.dart';
import 'demo_backend.dart';

/// DEMO ONLY wiring (see lib/core/config/backend_mode.dart).
List<Override> demoOverrides() {
  final state = DemoBackendState();
  return [
    authRepositoryProvider.overrideWithValue(DemoAuthRepository(state)),
    accountApiProvider.overrideWithValue(DemoAccountApi(state)),
  ];
}
