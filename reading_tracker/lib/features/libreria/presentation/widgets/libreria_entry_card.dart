import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/design_system/design_system.dart';

class LibreriaEntryCard extends StatelessWidget {
  const LibreriaEntryCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
        '[libreria] entry card build route='
        '${ModalRoute.of(context)?.settings.name}',
      );
    }
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: 'Abrir LibrerIA, tu espacio de lectura',
      child: Material(
        color: Colors.transparent,
        child: AppPressable(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.58),
                  theme.colorScheme.surface.withValues(alpha: 0.96),
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.14),
              ),
              boxShadow: AppShadows.editorial(theme.colorScheme.primary),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    AppIcons.libreria,
                    color: theme.colorScheme.onPrimary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LibrerIA',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Tu espacio para entender y acompañar tus lecturas.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
