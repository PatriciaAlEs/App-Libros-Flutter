import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../books/presentation/screens/books_list_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../insights/presentation/screens/insights_screen.dart';
import '../../../progress/presentation/screens/progress_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final List<int> _tabVersions = List.filled(5, 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          KeyedSubtree(
            key: ValueKey('home-${_tabVersions[0]}'),
            child: const HomeScreen(),
          ),
          KeyedSubtree(
            key: ValueKey('books-${_tabVersions[1]}'),
            child: const BooksListScreen(),
          ),
          KeyedSubtree(
            key: ValueKey('progress-${_tabVersions[2]}'),
            child: const ProgressScreen(),
          ),
          KeyedSubtree(
            key: ValueKey('insights-${_tabVersions[3]}'),
            child: const InsightsScreen(),
          ),
          KeyedSubtree(
            key: ValueKey('profile-${_tabVersions[4]}'),
            child: const SettingsScreen(),
          ),
        ],
      ),
      bottomNavigationBar: _MainBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelect: _selectTab,
      ),
    );
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      _tabVersions[index]++;
    });
  }
}

class _MainBottomNavigation extends StatelessWidget {
  const _MainBottomNavigation({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: Container(
          height: 82,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(0),
            boxShadow: AppShadows.soft(theme.colorScheme.primary),
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
      child: InkResponse(
        radius: 28,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 5),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 9),
              Icon(icon, color: color, size: 23),
              const SizedBox(height: 4),
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
    );
  }
}
