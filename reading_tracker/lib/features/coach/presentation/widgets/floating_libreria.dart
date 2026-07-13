import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../screens/coach_screen.dart';

class FloatingLibreria extends StatelessWidget {
  const FloatingLibreria({
    super.key,
    required this.isExpanded,
    required this.onExpand,
    required this.onCollapse,
  });

  final bool isExpanded;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;

  static const double maxPanelWidth = 420;
  static const double maxPanelHeight = 680;
  static const double _navigationClearance = 112;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final sideMargin = isCompact ? 10.0 : 24.0;
        final topMargin = isCompact ? 10.0 : 24.0;
        final availableHeight = math.max(
          0.0,
          constraints.maxHeight - _navigationClearance - topMargin,
        );
        final panelHeight = math.min(maxPanelHeight, availableHeight);

        if (!isExpanded) {
          return Stack(
            children: [
              Positioned(
                right: sideMargin,
                bottom: _navigationClearance,
                child: Semantics(
                  button: true,
                  label: 'Abrir LibrerIA',
                  child: Tooltip(
                    message: 'Abrir LibrerIA',
                    child: Material(
                      key: const ValueKey('open-libreria'),
                      color: theme.colorScheme.primary,
                      shape: const CircleBorder(),
                      elevation: 8,
                      shadowColor: theme.colorScheme.primary.withValues(
                        alpha: 0.46,
                      ),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onExpand,
                        child: const SizedBox(
                          width: 60,
                          height: 60,
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: [
            Positioned(
              left: isCompact ? sideMargin : null,
              right: sideMargin,
              bottom: _navigationClearance,
              width: isCompact ? null : maxPanelWidth,
              height: panelHeight,
              child: Material(
                key: const ValueKey('libreria-panel'),
                color: theme.scaffoldBackgroundColor,
                elevation: 18,
                shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.28),
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
                  ),
                  child: CoachScreen(
                    isFloatingPanel: true,
                    onCollapse: onCollapse,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
