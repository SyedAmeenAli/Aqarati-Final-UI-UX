import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/aq/aq_tokens.dart';
import '../../core/localization/flow_strings.dart';
import '../maintenance/maintenance_screens.dart';
import '../viewing/screens/my_viewings_screen.dart';
import '../workspace/aq_home.dart' show AQSlideSwitch;

/// Which Activity list is open: 0 viewings, 1 maintenance requests. Kept for the app session.
final activityTabProvider = StateProvider<int>((ref) => 0);

/// The Activity tab: a viewing list and a maintenance-request list behind one switch. Both lists
/// keep their own states (loading, empty, error); nothing here invents entries.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = FlowStrings.of(context);
    final tab = ref.watch(activityTabProvider);
    return Column(children: [
      SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AQSpacing.maxContent + AQSpacing.gutter * 2),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AQSpacing.gutter, AQSpacing.x3, AQSpacing.gutter, 0),
              child: AQSlideSwitch(labels: [f.t('act.viewings'), f.t('act.maintenance')], index: tab, onChanged: (i) => ref.read(activityTabProvider.notifier).state = i),
            ),
          ),
        ),
      ),
      Expanded(
        child: AnimatedSwitcher(
          duration: AQMotion.scaled(context, AQMotion.fast),
          child: KeyedSubtree(key: ValueKey(tab), child: tab == 0 ? const MyViewingsScreen() : const MaintenanceBookingsView()),
        ),
      ),
    ]);
  }
}
