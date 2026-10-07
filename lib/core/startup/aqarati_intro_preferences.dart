import 'package:shared_preferences/shared_preferences.dart';

/// Whether the one-time brand film has been completed on this installation.
/// Only ever written after real completion (or the reduced-motion bypass).
class AqaratiIntroPreferences {
  static const _key = 'hasCompletedAqaratiIntro';

  Future<bool> hasCompletedIntro() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(_key) ?? false;
    } catch (_) {
      // Storage unavailable: treat as completed so startup is never blocked.
      return true;
    }
  }

  Future<void> markIntroCompleted() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(_key, true);
    } catch (_) {}
  }
}
