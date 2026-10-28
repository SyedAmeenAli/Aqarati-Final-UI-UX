import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/notifications/notifications.dart' show readNotificationsProvider;
import '../../features/onboarding/interests.dart';
import 'app_state_providers.dart';

/// Keeps the two pieces of purely local, on-device state across restarts: the properties a person
/// saved (hearts) and their own recent searches. Nothing here is sent anywhere and nothing is
/// invented: a fresh install starts empty. Storage failures are ignored so the app still works.
class AQLocalPersistence extends ConsumerStatefulWidget {
  final Widget child;
  const AQLocalPersistence({super.key, required this.child});
  @override
  ConsumerState<AQLocalPersistence> createState() => _AQLocalPersistenceState();
}

const kSavedIdsKey = 'aq.saved.propertyIds';
const kRecentSearchesKey = 'aq.recent.searches';
const kReadNotificationsKey = 'aq.notifications.read';

class _AQLocalPersistenceState extends ConsumerState<AQLocalPersistence> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(kSavedIdsKey);
      final recent = prefs.getStringList(kRecentSearchesKey);
      final read = prefs.getStringList(kReadNotificationsKey);
      final interests = prefs.getStringList(kInterestsKey);
      if (!mounted) return;
      if (interests != null) {
        ref.read(interestsProvider.notifier).update((s) => {
          ...s,
          for (final n in interests)
            ...Interest.values.where((i) => i.name == n),
        });
      }
      if (read != null) ref.read(readNotificationsProvider.notifier).update((s) => {...read, ...s});
      // Merge with anything chosen before the read finished, so no early tap is lost.
      if (ids != null) ref.read(savedPropertyIdsProvider.notifier).update((s) => {...ids, ...s});
      if (recent != null) ref.read(recentSearchesProvider.notifier).update((s) => [...s, ...recent.where((x) => !s.contains(x))].take(6).toList());
    } catch (_) {
      // Local storage unavailable: keep working in memory.
    }
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save(String key, List<String> value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Set<String>>(savedPropertyIdsProvider, (_, next) {
      if (_loaded) _save(kSavedIdsKey, next.toList());
    });
    ref.listen<List<String>>(recentSearchesProvider, (_, next) {
      if (_loaded) _save(kRecentSearchesKey, next);
    });
    ref.listen<Set<Interest>>(interestsProvider, (_, next) {
      if (_loaded) _save(kInterestsKey, [for (final i in next) i.name]);
    });
    ref.listen<Set<String>>(readNotificationsProvider, (_, next) {
      if (_loaded) _save(kReadNotificationsKey, next.toList());
    });
    return widget.child;
  }
}
