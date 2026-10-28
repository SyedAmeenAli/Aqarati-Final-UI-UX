import 'package:go_router/go_router.dart';

import '../../core/aq/aq_scene.dart' show AQRoute;
import 'agent_screens.dart';

/// The agent workspace's own pages (hosted by `AgentShell`, never by the customer shell).
List<RouteBase> agentShellRoutes() => [
  GoRoute(
    path: '/agent',
    pageBuilder: (context, state) =>
        AQRoute.tab(key: state.pageKey, child: const AgentDashboardScreen()),
  ),
  GoRoute(
    path: '/agent/contacts',
    pageBuilder: (context, state) =>
        AQRoute.tab(key: state.pageKey, child: const AgentContactsScreen()),
  ),
  GoRoute(
    path: '/agent/contacts/new',
    pageBuilder: (context, state) => AQRoute.forward(
      key: state.pageKey,
      child: const AgentContactFormScreen(),
    ),
  ),
  GoRoute(
    path: '/agent/contacts/:id',
    pageBuilder: (context, state) => AQRoute.forward(
      key: state.pageKey,
      child: AgentContactScreen(id: state.pathParameters['id']!),
    ),
  ),
  GoRoute(
    path: '/agent/contacts/:id/edit',
    pageBuilder: (context, state) => AQRoute.forward(
      key: state.pageKey,
      child: AgentContactFormScreen(editId: state.pathParameters['id']),
    ),
  ),
  GoRoute(
    path: '/agent/calendar',
    pageBuilder: (context, state) =>
        AQRoute.tab(key: state.pageKey, child: const AgentCalendarScreen()),
  ),
  GoRoute(
    path: '/agent/more',
    pageBuilder: (context, state) =>
        AQRoute.tab(key: state.pageKey, child: const AgentMoreScreen()),
  ),
];
