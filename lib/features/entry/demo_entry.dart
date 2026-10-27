import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/demo_mode.dart';
import '../../core/localization/flow_strings.dart';
import '../../data/api/account_api.dart' show meProvider;
import '../../data/demo/demo_providers.dart';
import '../role_home/role_home_model.dart' show homeWorkspaceProvider;
import 'models/signup_purpose.dart';

/// Presentation shortcut: opens [purpose]'s home on the simulated session, without creating,
/// registering or verifying anything. Does nothing unless [kDemoMode] is on.
void demoSkipInto(BuildContext context, WidgetRef ref, SignupPurpose purpose) {
  final state = ref.read(demoBackendStateProvider);
  if (!kDemoMode || state == null) return;
  demoEnterAs(state, purpose);
  ref.read(homeWorkspaceProvider.notifier).state = null;
  ref.invalidate(meProvider);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 6),
      content: Text(FlowStrings.of(context).t('demo.skip.note')),
    ),
  );
  context.go('/app/home');
}
