import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'lead_repository.dart';

/// Opens the platform dialler with the number. It cannot know whether a call was made or connected,
/// so callers never report an outcome beyond "the dialler opened".
class UrlPhoneLauncher implements PhoneLauncher {
  const UrlPhoneLauncher();
  @override
  Future<bool> dial(String number) async {
    final cleaned = number.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return false;
    try {
      return await launchUrl(Uri(scheme: 'tel', path: cleaned));
    } catch (_) {
      return false;
    }
  }
}

final phoneLauncherProvider = Provider<PhoneLauncher>(
  (ref) => const UrlPhoneLauncher(),
);
