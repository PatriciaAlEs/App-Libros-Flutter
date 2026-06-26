import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class AccountTransitionScreen extends StatelessWidget {
  const AccountTransitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.10),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0, 0.42, 1],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Volver',
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ReadPpSurface(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                borderRadius: 30,
                opacity: 0.94,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.cloud_done_outlined,
                      size: 46,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Tus lecturas, ahora mas seguras',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Hasta ahora ReadPp guardaba tu biblioteca y tu progreso '
                      'unicamente en este dispositivo.\n\n'
                      'Con esta actualizacion podras crear una cuenta para '
                      'sincronizar tus datos entre dispositivos y proteger tu '
                      'biblioteca frente a perdidas accidentales.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.38,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const _BenefitItem(
                      icon: Icons.sync_rounded,
                      label: 'Sincronizacion entre dispositivos.',
                    ),
                    const _BenefitItem(
                      icon: Icons.restore_rounded,
                      label: 'Recuperacion de datos.',
                    ),
                    const _BenefitItem(
                      icon: Icons.library_books_outlined,
                      label: 'Biblioteca siempre disponible.',
                    ),
                    const _BenefitItem(
                      icon: Icons.cloud_queue_rounded,
                      label: 'Preparacion para futuras funcionalidades cloud.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/account/auth',
                        arguments: true,
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Crear cuenta'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/account/auth',
                        arguments: false,
                      ),
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Ya tengo una cuenta'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: () => Navigator.maybePop(context),
                      child: const Text('Mas tarde'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  const _BenefitItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 19),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
