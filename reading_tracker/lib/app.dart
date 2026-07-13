import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design_system/design_system.dart';
import 'core/navigation/app_launch_uri.dart';
import 'core/observability/readpp_sentry.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_controller.dart';
import 'features/navigation/presentation/screens/main_navigation_screen.dart';
import 'features/auth/presentation/widgets/oauth_callback_bootstrap.dart';
import 'features/onboarding/presentation/providers/onboarding_controller.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/onboarding/presentation/widgets/sync_onboarding_notice.dart';
import 'features/sync/presentation/widgets/auto_sync_bootstrap.dart';

class App extends ConsumerWidget {
  const App({super.key, this.launchUri, this.onOAuthCallbackCleaned});

  final Uri? launchUri;
  final ValueChanged<String>? onOAuthCallbackCleaned;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTheme = ref.watch(appThemeControllerProvider);

    final initialUri = launchUri ?? (kIsWeb ? Uri.base : Uri(path: '/'));

    return OAuthCallbackBootstrap(
      launchUri: initialUri,
      onCleanUrl: onOAuthCallbackCleaned,
      child: AutoSyncBootstrap(
        child: MaterialApp(
          title: 'ReadPp',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(selectedTheme),
          themeAnimationDuration: AppMotion.slow,
          themeAnimationCurve: AppMotion.emphasized,
          initialRoute: appRoutePath(initialUri),
          home: ref
              .watch(onboardingControllerProvider)
              .when(
                loading: () => const _AppBootstrapScreen(),
                error: (error, stackTrace) => const OnboardingScreen(),
                data: (isCompleted) => isCompleted
                    ? const SyncOnboardingNotice(child: MainNavigationScreen())
                    : const OnboardingScreen(),
              ),
          onGenerateRoute: _onGenerateRoute,
          navigatorObservers: ReadPpSentry.navigatorObservers(),
        ),
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings rawSettings) {
    final uri = routeUri(rawSettings.name);
    final settings = RouteSettings(
      name: appRoutePath(uri),
      arguments: rawSettings.arguments,
    );
    if (kDebugMode) {
      debugPrint(
        '[router] rawUri=${safeUriForLog(uri)} path=${appRoutePath(uri)} '
        'queryKeys=${uri.queryParameters.keys.toList()..sort()}',
      );
    }

    switch (settings.name) {
      case '/':
        return _route(settings, (_) => const MainNavigationScreen());

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

      case '/coach':
        return _shellRoute(settings);

      case '/account':
      case '/account/transition':
      case '/account/auth':
        return _shellRoute(settings, initialIndex: 4);

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
