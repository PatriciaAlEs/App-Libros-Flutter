import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design_system/design_system.dart';
import 'core/observability/readpp_sentry.dart';
import 'core/observability/sentry_validation_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_controller.dart';
import 'features/navigation/presentation/screens/main_navigation_screen.dart';
import 'features/onboarding/presentation/providers/onboarding_controller.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(appThemeControllerProvider);

    return MaterialApp(
      title: 'ReadPp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(selectedTheme),
      themeAnimationDuration: AppMotion.slow,
      themeAnimationCurve: AppMotion.emphasized,
      home: ref
          .watch(onboardingControllerProvider)
          .when(
            loading: () => const _AppBootstrapScreen(),
            error: (error, stackTrace) => const OnboardingScreen(),
            data: (isCompleted) => isCompleted
                ? const MainNavigationScreen()
                : const OnboardingScreen(),
          ),
      onGenerateRoute: _onGenerateRoute,
      navigatorObservers: ReadPpSentry.navigatorObservers(),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return _route(settings, (_) => const MainNavigationScreen());

      case '/__readpp/sentry-validation':
        if (!ReadPpSentry.validationActionEnabled) return _notFoundRoute();
        return _route(settings, (_) => const SentryValidationScreen());

      case '/home':
        return _route(settings, (_) => const MainNavigationScreen());

      case '/books':
        return _route(
          settings,
          (_) => const MainNavigationScreen(initialIndex: 1),
        );

      case '/book/add':
        return _shellRoute(settings, initialIndex: 1);

      case '/book/detail':
        final bookId = settings.arguments as String?;
        if (bookId == null) return _notFoundRoute();
        return _shellRoute(settings, initialIndex: 1);

      case '/calendar':
        return _shellRoute(settings);

      case '/calendar/day':
        final day = settings.arguments as DateTime?;
        if (day == null) return _notFoundRoute();
        return _shellRoute(settings);

      case '/session/add':
        final initialDate = settings.arguments as DateTime?;
        return _shellRoute(
          RouteSettings(name: settings.name, arguments: initialDate),
          initialIndex: 2,
        );

      case '/session/edit':
        if (settings.arguments == null) return _notFoundRoute();
        return _shellRoute(settings, initialIndex: 2);

      case '/stats':
        return _shellRoute(settings, initialIndex: 2);

      case '/progress':
        return _route(
          settings,
          (_) => const MainNavigationScreen(initialIndex: 2),
        );

      case '/insights':
        return _route(
          settings,
          (_) => const MainNavigationScreen(initialIndex: 3),
        );

      case '/settings':
        return _route(
          settings,
          (_) => const MainNavigationScreen(initialIndex: 4),
        );

      default:
        return _notFoundRoute();
    }
  }

  Route<dynamic> _shellRoute(RouteSettings settings, {int initialIndex = 0}) {
    return _route(
      settings,
      (_) => MainNavigationScreen(
        initialIndex: initialIndex,
        initialRoute: settings.name ?? '/',
        initialArguments: settings.arguments,
      ),
    );
  }

  Route<dynamic> _route(
    RouteSettings settings,
    WidgetBuilder builder, {
    Offset slideOffset = const Offset(0.018, 0),
  }) {
    return AppFadeThroughPageRoute(
      settings: settings,
      builder: builder,
      slideOffset: slideOffset,
    );
  }

  Route<dynamic> _notFoundRoute() =>
      _route(const RouteSettings(name: '/not-found'), (_) {
        return const Scaffold(
          body: Center(child: Text('Pantalla no encontrada.')),
        );
      });
}

class _AppBootstrapScreen extends StatelessWidget {
  const _AppBootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
