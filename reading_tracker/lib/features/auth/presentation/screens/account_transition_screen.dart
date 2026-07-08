import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../onboarding/presentation/providers/sync_coach_mark_controller.dart';

class AccountTransitionScreen extends ConsumerStatefulWidget {
  const AccountTransitionScreen({super.key});

  @override
  ConsumerState<AccountTransitionScreen> createState() =>
      _AccountTransitionScreenState();
}

class _AccountTransitionScreenState
    extends ConsumerState<AccountTransitionScreen> {
  bool _markSeenQueued = false;
  bool _displayCoachMark = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shouldShowCoachMark =
        ref.watch(syncCoachMarkControllerProvider).valueOrNull ?? false;

    if (shouldShowCoachMark && !_displayCoachMark) {
      _displayCoachMark = true;
    }

    if (shouldShowCoachMark && !_markSeenQueued) {
      _markSeenQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await ref.read(syncCoachMarkControllerProvider.notifier).markShown();
      });
    }

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
              if (_displayCoachMark) ...[
                const _SyncCoachMarkCard(),
                const SizedBox(height: AppSpacing.lg),
              ],
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

class _SyncCoachMarkCard extends StatelessWidget {
  const _SyncCoachMarkCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.22),
        ),
        boxShadow: AppShadows.editorial(theme.colorScheme.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withValues(alpha: 0.82),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.touch_app_outlined,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Entra en Perfil',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Inicia sesion para activar la sincronizacion.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Tus lecturas seguiran guardadas en este dispositivo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
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
