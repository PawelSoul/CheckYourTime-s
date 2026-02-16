import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/calendar/presentation/calendar_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/shell/presentation/shell_page.dart';
import '../features/statistics/domain/models/statistics_models.dart';
import '../features/statistics/presentation/category_stats_screen.dart';
import '../features/tasks/presentation/tasks_list_page.dart';
import '../features/timer/presentation/name_task_screen.dart';
import '../features/timer/presentation/timer_page.dart';

enum AppRoute {
  tasks,
  timer,
  calendar,
  settings,
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/timer',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return ShellPage(child: child);
        },
        routes: [
          GoRoute(
            path: '/tasks',
            name: AppRoute.tasks.name,
            builder: (context, state) => const TasksListPage(),
            routes: [
              GoRoute(
                path: 'category-stats',
                name: 'categoryStats',
                builder: (context, state) {
                  final args = CategoryStatsScreenArgs.fromExtra(state.extra);
                  if (args == null) {
                    return const Scaffold(
                      body: Center(child: Text('Brak parametrów kategorii')),
                    );
                  }
                  return CategoryStatsScreen(args: args);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/timer',
            name: AppRoute.timer.name,
            builder: (context, state) => const TimerPage(),
            routes: [
              GoRoute(
                path: 'name-task',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>?;
                  final taskId = extra?['taskId'] as String? ?? '';
                  return NameTaskScreen(taskId: taskId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/calendar',
            name: AppRoute.calendar.name,
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: '/settings',
            name: AppRoute.settings.name,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
