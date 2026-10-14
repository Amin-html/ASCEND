import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ascend/core/router/app_router.dart';
import 'package:ascend/core/router/app_routes.dart';

Iterable<String> collectPaths(
    List<RouteBase> routes, [
      String prefix = '',
    ]) sync* {
  for (final route in routes) {
    if (route is GoRoute) {
      final full = route.path.startsWith('/')
          ? route.path
          : '$prefix/${route.path}';
      yield full;
      yield* collectPaths(route.routes, full);
    } else if (route is StatefulShellRoute) {
      for (final branch in route.branches) {
        yield* collectPaths(branch.routes, prefix);
      }
    }
  }
}

void main() {
  test('every route from AppRoutes is registered', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = container.read(routerProvider);
    final paths = collectPaths(router.configuration.routes).toSet();

    const expected = [
      AppRoutes.home,
      AppRoutes.planner,
      AppRoutes.goals,
      AppRoutes.stats,
      AppRoutes.profile,
      AppRoutes.backup,
      AppRoutes.notifications,
      AppRoutes.habits,
      AppRoutes.focus,
      AppRoutes.achievements,
      '/goals/:id',
      '/tasks/:id',
    ];

    for (final path in expected) {
      expect(paths, contains(path), reason: 'Route $path is missing');
    }
  });
}