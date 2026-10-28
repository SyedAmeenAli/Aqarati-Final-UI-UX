import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'admin_app.dart';
import 'admin_auth.dart';

/// The Admin Web Console as a page of the customer app, at `/admin` (so one web build, and one
/// Vercel deployment, carries both). It is still its own application with its own navigation,
/// sign-in and routes; the only thing it asks of the customer app is a way back.
class AdminConsoleHost extends StatelessWidget {
  const AdminConsoleHost({super.key});
  @override
  Widget build(BuildContext context) => ProviderScope(
    overrides: [
      adminExitProvider.overrideWithValue(() {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/entry');
        }
      }),
    ],
    child: const AdminApp(),
  );
}
