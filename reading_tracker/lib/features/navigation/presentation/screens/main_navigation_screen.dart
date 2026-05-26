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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomeScreen(),
          const BooksListScreen(),
          const ProgressScreen(),
          const InsightsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _MainBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelect: _selectTab,
      ),
    );
  }

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
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
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: AppShadows.soft(theme.colorScheme.primary),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                _NavItem(
                  icon: AppIcons.home,
                  label: 'Inicio',
                  isSelected: selectedIndex == 0,
                  onTap: () => onSelect(0),
                ),
                _NavItem(
                  icon: AppIcons.library,
                  label: 'Biblioteca',
                  isSelected: selectedIndex == 1,
                  onTap: () => onSelect(1),
                ),
                const SizedBox(width: 62),
                _NavItem(
                  icon: AppIcons.chart,
                  label: 'Progreso',
                  isSelected: selectedIndex == 2,
                  onTap: () => onSelect(2),
                ),
                _NavItem(
                  icon: AppIcons.insights,
                  label: 'Insights',
                  isSelected: selectedIndex == 3,
                  onTap: () => onSelect(3),
                ),
                _NavItem(
                  icon: AppIcons.settings,
                  label: 'Ajustes',
                  isSelected: selectedIndex == 4,
                  onTap: () => onSelect(4),
                ),
              ],
            ),
            const _NavLogo(),
          ],
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
        : theme.colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        borderRadius: AppRadii.card,
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: AppRadii.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 3),
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

class _NavLogo extends StatelessWidget {
  const _NavLogo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 54,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
        border: Border.all(color: theme.colorScheme.surface, width: 4),
      ),
      child: Text(
        'RP',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
