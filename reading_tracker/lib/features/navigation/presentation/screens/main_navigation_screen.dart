import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/observability/readpp_sentry.dart';
import '../../../../core/navigation/app_launch_uri.dart';
import '../../../auth/presentation/screens/account_screen.dart';
import '../../../auth/presentation/screens/account_transition_screen.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../books/presentation/screens/book_detail_screen.dart';
import '../../../books/presentation/screens/book_form_screen.dart';
import '../../../books/presentation/screens/books_list_screen.dart';
import '../../../coach/presentation/widgets/floating_libreria.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../insights/presentation/screens/insights_screen.dart';
import '../../../progress/presentation/screens/progress_screen.dart';
import '../../../reading_sessions/domain/entities/reading_session.dart';
import '../../../reading_sessions/presentation/screens/calendar_screen.dart';
import '../../../reading_sessions/presentation/screens/day_detail_screen.dart';
import '../../../reading_sessions/presentation/screens/session_form_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../stats/presentation/screens/stats_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.initialRoute = '/',
    this.initialArguments,
  });

  final int initialIndex;
  final String initialRoute;
  final Object? initialArguments;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final ValueNotifier<int> _selectedIndex;
  late final ValueNotifier<String> _currentRoute;
  late final NavigatorObserver _routeObserver;
  final List<int> _tabVersions = List.filled(5, 0);
  late bool _isLibreriaExpanded;

  @override
  void initState() {
    super.initState();
    _selectedIndex = ValueNotifier(_expectedIndex(widget));
    final initialPath = appRoutePath(routeUri(widget.initialRoute));
    _currentRoute = ValueNotifier(initialPath == '/coach' ? '/' : initialPath);
    _routeObserver = _ShellRouteObserver(_currentRoute);
    _isLibreriaExpanded = initialPath == '/coach';
    if (kDebugMode) {
      debugPrint(
        '[navigation] shell init route=${widget.initialRoute} '
        'index=${_selectedIndex.value}',
      );
    }
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final expectedIndex = _expectedIndex(widget);
    if (_selectedIndex.value == expectedIndex) return;
    if (kDebugMode) {
      debugPrint(
        '[navigation] shell config changed raw=${widget.initialRoute} '
        'path=${appRoutePath(routeUri(widget.initialRoute))} '
        'selectedIndex=${_selectedIndex.value} expectedIndex=$expectedIndex',
      );
    }
    _selectedIndex.value = expectedIndex;
  }

  int _expectedIndex(MainNavigationScreen configuration) {
    final path = appRoutePath(routeUri(configuration.initialRoute));
    return _indexFromPath(path) ?? configuration.initialIndex.clamp(0, 4);
  }

  int? _indexFromPath(String path) => switch (path) {
    '/' || '/home' => 0,
    '/books' => 1,
    '/progress' => 2,
    '/insights' => 3,
    '/settings' => 4,
    _ => null,
  };

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint(
        '[navigation] shell dispose route=${widget.initialRoute} '
        'index=${_selectedIndex.value}',
      );
    }
    _selectedIndex.dispose();
    _currentRoute.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: NavigatorPopHandler(
              onPopWithResult: (result) =>
                  _navigatorKey.currentState?.pop(result),
              child: Navigator(
                key: _navigatorKey,
                initialRoute: _initialNavigatorRoute,
                onGenerateInitialRoutes: (_, initialRoute) => [
                  _onGenerateRoute(
                    RouteSettings(
                      name: initialRoute,
                      arguments: widget.initialArguments,
                    ),
                    updateSelectedIndex: false,
                  ),
                ],
                onGenerateRoute: _onGenerateRoute,
                observers: [
                  ...ReadPpSentry.navigatorObservers(),
                  _routeObserver,
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: ValueListenableBuilder<String>(
              valueListenable: _currentRoute,
              builder: (context, route, _) {
                if (_isAuthenticationRoute(route)) {
                  return const SizedBox.shrink();
                }
                return FloatingLibreria(
                  isExpanded: _isLibreriaExpanded,
                  onExpand: _expandLibreria,
                  onCollapse: _collapseLibreria,
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: _selectedIndex,
        builder: (context, selectedIndex, _) => ReadPpBottomNavigation(
          selectedIndex: selectedIndex,
          onSelect: _selectTab,
        ),
      ),
    );
  }

  String get _initialNavigatorRoute {
    final path = appRoutePath(routeUri(widget.initialRoute));
    return path == '/coach' ? '/' : widget.initialRoute;
  }

  bool _isAuthenticationRoute(String route) =>
      route == '/account/auth' || route == '/account/transition';

  void _expandLibreria() {
    if (_isLibreriaExpanded || !mounted) return;
    setState(() => _isLibreriaExpanded = true);
  }

  void _collapseLibreria() {
    if (!_isLibreriaExpanded || !mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLibreriaExpanded = false);
  }

  void _selectTab(int index) {
    final normalizedIndex = index.clamp(0, 4);
    final route = _pathForIndex(normalizedIndex);
    if (kDebugMode) {
      debugPrint(
        '[navigation] bottom navigation route=$route '
        'selectedIndex=${_selectedIndex.value} expectedIndex=$normalizedIndex',
      );
    }
    if (normalizedIndex == _selectedIndex.value &&
        _navigatorKey.currentState?.canPop() == false) {
      return;
    }
    _tabVersions[normalizedIndex]++;
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
  }

  String _pathForIndex(int index) => switch (index) {
    0 => '/',
    1 => '/books',
    2 => '/progress',
    3 => '/insights',
    _ => '/settings',
  };

  Route<dynamic> _onGenerateRoute(
    RouteSettings rawSettings, {
    bool updateSelectedIndex = true,
  }) {
    final uri = routeUri(rawSettings.name);
    final settings = RouteSettings(
      name: appRoutePath(uri),
      arguments: rawSettings.arguments,
    );
    final mainIndex = _indexFromPath(settings.name!);
    if (mainIndex != null && updateSelectedIndex) {
      _selectedIndex.value = mainIndex;
    }

    if (kDebugMode) {
      debugPrint(
        '[navigation] inner route=${settings.name} branch='
        '${mainIndex == null ? 'detail' : 'main-tab'} '
        'selectedIndex=${_selectedIndex.value} initial=${!updateSelectedIndex} '
        'rawUri=${safeUriForLog(uri)} path=${appRoutePath(uri)} '
        'queryKeys=${uri.queryParameters.keys.toList()..sort()}',
      );
    }

    if (settings.name == '/coach') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _expandLibreria();
      });
    }

    final builder = switch (settings.name) {
      '/' ||
      '/home' ||
      '/books' ||
      '/progress' ||
      '/insights' ||
      '/settings' => (_) => _mainTabBody(),
      '/book/add' => (_) => const BookFormScreen(),
      '/book/detail' => (_) => BookDetailScreen(
        bookId: settings.arguments! as String,
      ),
      '/calendar' => (_) => const CalendarScreen(),
      '/calendar/day' => (_) => DayDetailScreen(
        day: settings.arguments! as DateTime,
      ),
      '/session/add' => (_) => SessionFormScreen(
        initialDate: settings.arguments as DateTime?,
      ),
      '/session/edit' => (_) => SessionFormScreen(
        session: settings.arguments! as ReadingSession,
      ),
      '/stats' => (_) => const StatsScreen(),
      '/coach' => (_) => _mainTabBody(),
      '/account' => (_) => const AccountScreen(),
      '/account/transition' => (_) => const AccountTransitionScreen(),
      '/account/auth' => (_) => AuthScreen(
        initialRegisterMode: settings.arguments == true,
      ),
      _ => (_) => const Scaffold(
        body: Center(child: Text('Pantalla no encontrada.')),
      ),
    };

    return AppFadeThroughPageRoute(settings: settings, builder: builder);
  }

  Widget _mainTabBody() {
    return ValueListenableBuilder<int>(
      valueListenable: _selectedIndex,
      builder: (context, selectedIndex, _) {
        if (kDebugMode) {
          debugPrint(
            '[navigation] _mainTabBody branch=${_branchName(selectedIndex)} '
            'selectedIndex=$selectedIndex',
          );
        }
        return AppAnimatedPageSwitch(
          child: KeyedSubtree(
            key: ValueKey('tab-$selectedIndex-${_tabVersions[selectedIndex]}'),
            child: _screenForIndex(selectedIndex),
          ),
        );
      },
    );
  }

  String _branchName(int index) => switch (index) {
    0 => 'HomeScreen',
    1 => 'BooksListScreen',
    2 => 'ProgressScreen',
    3 => 'InsightsScreen',
    _ => 'SettingsScreen',
  };

  Widget _screenForIndex(int index) {
    return switch (index) {
      0 => const HomeScreen(),
      1 => const BooksListScreen(),
      2 => const ProgressScreen(),
      3 => const InsightsScreen(),
      _ => const SettingsScreen(),
    };
  }
}

class _ShellRouteObserver extends NavigatorObserver {
  _ShellRouteObserver(this.currentRoute);

  final ValueNotifier<String> currentRoute;

  void _update(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null) currentRoute.value = name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _update(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _update(newRoute);
  }
}

class ReadPpBottomNavigation extends StatelessWidget {
  const ReadPpBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int? selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final navigationHeight =
        82.0 + ((textScale - 1).clamp(0.0, 1.0).toDouble() * 22);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: Container(
          height: navigationHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
              bottom: Radius.circular(22),
            ),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: theme.colorScheme.secondary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _NavItem(
                icon: AppIcons.home,
                label: 'Inicio',
                isSelected: selectedIndex == 0,
                onTap: () => onSelect(0),
              ),
              _NavItem(
                icon: AppIcons.libraryNav,
                label: 'Biblioteca',
                isSelected: selectedIndex == 1,
                onTap: () => onSelect(1),
              ),
              _NavItem(
                icon: AppIcons.progressNav,
                label: 'Progreso',
                isSelected: selectedIndex == 2,
                onTap: () => onSelect(2),
              ),
              _NavItem(
                icon: AppIcons.insightsNav,
                label: 'Insights',
                isSelected: selectedIndex == 3,
                onTap: () => onSelect(3),
              ),
              _NavItem(
                icon: AppIcons.profile,
                label: 'Perfil',
                isSelected: selectedIndex == 4,
                onTap: () => onSelect(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary.withValues(alpha: 0.78);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: ExcludeSemantics(
          child: InkResponse(
            radius: 28,
            onTap: onTap,
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 3),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 7),
                  Icon(icon, color: color, size: 22),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: theme.textTheme.labelSmall?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
