import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/tasks/create_task_screen.dart';
import '../screens/tasks/task_detail_screen.dart';
import '../screens/tasks/task_list_screen.dart';
import '../screens/tasks/open_tasks_screen.dart';
import '../screens/workers/worker_detail_screen.dart';
import '../screens/workers/worker_list_screen.dart';
import '../screens/profile/avatar_generator_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

const _authRequiredRoutes = [
  '/home/my-tasks',
  '/home/profile',
  '/tasks/create',
  '/settings',
  '/profile',
  '/avatar-generator',
];

Future<String?> _authGuard(GoRouterState state) async {
  final path = state.matchedLocation;

  final needsAuth = _authRequiredRoutes.any((r) => path.startsWith(r));
  if (!needsAuth) return null;

  final hasToken = await ApiService().hasToken();
  if (!hasToken) return '/login';

  return null;
}

List<RouteBase> _buildRoutes() => [
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),

      // Buyer Shell (bottom nav)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeScreen(child: child),
        routes: [
          GoRoute(
            path: '/home/browse',
            builder: (_, __) => const WorkerListScreen(),
          ),
          GoRoute(
            path: '/home/tasks',
            builder: (_, __) => const OpenTasksScreen(),
          ),
          GoRoute(
            path: '/home/my-tasks',
            builder: (_, __) => const TaskListScreen(),
          ),
          GoRoute(
            path: '/home/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Standalone routes
      GoRoute(
        path: '/workers/:id',
        builder: (_, state) =>
            WorkerDetailScreen(workerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tasks/create',
        builder: (_, __) => const CreateTaskScreen(),
      ),
      GoRoute(
        path: '/tasks/:id',
        builder: (_, state) => TaskDetailScreen(
          taskNumber: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/avatar-generator',
        builder: (_, __) => const AvatarGeneratorScreen(),
      ),
    ];

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authStateProvider.notifier);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home/browse',
    redirect: (context, state) => _authGuard(state),
    routes: _buildRoutes(),
  );
});

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home/browse',
  redirect: (context, state) => _authGuard(state),
  routes: _buildRoutes(),
);
