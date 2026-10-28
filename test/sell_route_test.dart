import 'package:aqarati_app/core/router/extra_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('/sell/new reaches the form, not a submission called "new"; real ids still resolve', (t) async {
    final shell = extraShellRoutes().whereType<GoRoute>().where((r) => r.path.startsWith('/sell')).toList();
    final standalone = extraRoutes().whereType<GoRoute>().where((r) => r.path == '/sell-new' || r.path == '/sell/new').toList();
    expect(shell, isNotEmpty);
    expect(standalone.map((r) => r.path), contains('/sell-new'));
    // Same order as the app router: the shell's /sell/:id is matched before the standalone form.
    final router = GoRouter(
      initialLocation: '/sell/new',
      routes: [
        ShellRoute(
          builder: (c, s, child) => child,
          routes: [
            for (final r in shell)
              GoRoute(
                path: r.path,
                redirect: r.redirect,
                builder: (c, s) => Text('SHELL ${s.pathParameters['id']}'),
              ),
          ],
        ),
        GoRoute(path: '/sell-new', builder: (c, s) => const Text('FORM')),
      ],
    );
    await t.pumpWidget(MaterialApp.router(routerConfig: router));
    await t.pumpAndSettle();
    expect(find.text('FORM'), findsOneWidget);
    router.go('/sell/s123');
    await t.pumpAndSettle();
    expect(find.text('SHELL s123'), findsOneWidget);
    router.go('/sell/newer');
    await t.pumpAndSettle();
    expect(find.text('SHELL newer'), findsOneWidget, reason: 'only the exact word new is the form');
  });
}
