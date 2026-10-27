import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/aq/aq_scene.dart';
import '../core/aq/aq_tokens.dart';
import '../core/theme/app_theme.dart';
import '../features/ads/ad_repository.dart';
import 'admin_ads_screens.dart';
import 'admin_auth.dart';
import 'admin_auth_screens.dart';
import 'admin_models.dart';
import 'admin_moderation_screens.dart';
import 'admin_repository.dart';
import 'admin_verification_screens.dart';

/// Keeps the router in step with the sign-in stage, so a sign-out or an ended session leaves every
/// protected page at once.
class AdminAuthListenable extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// Where the sign-in stage allows the person to be. Nothing protected is reachable before the code
/// step is done, whatever address is typed.
String? adminRedirect(AdminAuthStage stage, String location) {
  final onLogin = location == '/login';
  final onCode = location == '/code';
  switch (stage) {
    case AdminAuthStage.signedOut:
      return onLogin ? null : '/login';
    case AdminAuthStage.needsTotp:
      return onCode ? null : '/code';
    case AdminAuthStage.active:
      if (onLogin || onCode || location == '/') return '/verification';
      return null;
  }
}

GoRouter buildAdminRouter(WidgetRef ref, AdminAuthListenable listenable) {
  Page<void> page(GoRouterState s, Widget child) =>
      AQRoute.fade(key: s.pageKey, child: child);
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: listenable,
    redirect: (context, state) =>
        adminRedirect(ref.read(adminAuthProvider).stage, state.uri.path),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/verification'),
      GoRoute(
        path: '/login',
        pageBuilder: (c, s) => page(s, const AdminLoginScreen()),
      ),
      GoRoute(
        path: '/code',
        pageBuilder: (c, s) => page(s, const AdminTotpScreen()),
      ),
      GoRoute(
        path: '/verification',
        pageBuilder: (c, s) => page(s, const VerificationQueueScreen()),
      ),
      GoRoute(
        path: '/verification/:id',
        pageBuilder: (c, s) =>
            page(s, VerificationDetailScreen(id: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/moderation',
        pageBuilder: (c, s) => page(s, const ModerationQueueScreen()),
      ),
      GoRoute(
        path: '/moderation/:id',
        pageBuilder: (c, s) =>
            page(s, ModerationDetailScreen(id: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/ads',
        pageBuilder: (c, s) => page(s, const AdsListScreen()),
      ),
      GoRoute(
        path: '/ads/new',
        pageBuilder: (c, s) => page(s, const AdFormScreen()),
      ),
      GoRoute(
        path: '/ads/:id/edit',
        pageBuilder: (c, s) =>
            page(s, AdFormScreen(editId: s.pathParameters['id'])),
      ),
    ],
  );
}

/// The admin console. It shares the design system, motion and components with the customer app and
/// ships as its own build; the customer app never imports this file.
class AdminApp extends ConsumerStatefulWidget {
  const AdminApp({super.key});
  @override
  ConsumerState<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends ConsumerState<AdminApp> {
  final _listenable = AdminAuthListenable();
  late final GoRouter _router = buildAdminRouter(ref, _listenable);

  @override
  void dispose() {
    _router.dispose();
    _listenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(adminAuthProvider, (_, _) => _listenable.ping());
    return MaterialApp.router(
      title: 'AQARATI Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A1613),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF825C3F),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.light,
      routerConfig: _router,
      builder: (context, child) => AQThemeTransition(
        mode: ThemeMode.light,
        child: child ?? const SizedBox.shrink(),
      ),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

/// Provider overrides for a console that runs against the demo store: one store feeds sign-in, the
/// queues, the moderation list and the ad management, and the ads the customer side would be served.
List<Override> adminOverrides(DemoAdminStore store) => [
  adminStoreProvider.overrideWithValue(store),
  adRepositoryProvider.overrideWithValue(store.ads),
];
