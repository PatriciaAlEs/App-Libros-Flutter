import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/design_system/design_system.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_controller.dart';
import 'features/books/presentation/screens/book_detail_screen.dart';
import 'features/books/presentation/screens/book_form_screen.dart';
import 'features/books/presentation/screens/books_list_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/insights/presentation/screens/insights_screen.dart';
import 'features/navigation/presentation/screens/main_navigation_screen.dart';
import 'features/onboarding/presentation/providers/onboarding_controller.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'features/progress/presentation/screens/progress_screen.dart';
import 'features/reading_sessions/presentation/screens/calendar_screen.dart';
import 'features/reading_sessions/presentation/screens/day_detail_screen.dart';
import 'features/reading_sessions/presentation/screens/session_form_screen.dart';
import 'features/reading_sessions/domain/entities/reading_session.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/stats/presentation/screens/stats_screen.dart';

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
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());

      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case '/books':
        return MaterialPageRoute(builder: (_) => const BooksListScreen());

      case '/book/add':
        return MaterialPageRoute(builder: (_) => const BookFormScreen());

      case '/book/detail':
        final bookId = settings.arguments as String?;
        if (bookId == null) return _notFoundRoute();
        return MaterialPageRoute(
          builder: (_) => BookDetailScreen(bookId: bookId),
        );

      case '/calendar':
        return MaterialPageRoute(builder: (_) => const CalendarScreen());

      case '/calendar/day':
        final day = settings.arguments as DateTime?;
        if (day == null) return _notFoundRoute();
        return MaterialPageRoute(builder: (_) => DayDetailScreen(day: day));

      case '/session/add':
        final initialDate = settings.arguments as DateTime?;
        return MaterialPageRoute(
          builder: (_) => SessionFormScreen(initialDate: initialDate),
        );

      case '/session/edit':
        final session = settings.arguments as ReadingSession?;
        if (session == null) return _notFoundRoute();
        return MaterialPageRoute(
          builder: (_) => SessionFormScreen(session: session),
        );

      case '/stats':
        return MaterialPageRoute(builder: (_) => const StatsScreen());

      case '/progress':
        return MaterialPageRoute(builder: (_) => const ProgressScreen());

      case '/insights':
        return MaterialPageRoute(builder: (_) => const InsightsScreen());

      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      default:
        return _notFoundRoute();
    }
  }

  Route<dynamic> _notFoundRoute() => MaterialPageRoute(
    builder: (_) =>
        const Scaffold(body: Center(child: Text('Pantalla no encontrada.'))),
  );
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
