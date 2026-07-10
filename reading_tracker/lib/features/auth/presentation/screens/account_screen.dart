import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../sync/presentation/widgets/sync_status_card.dart';
import '../../domain/entities/account_migration_preparation.dart';
import '../controllers/account_migration_controller.dart';
import '../controllers/auth_controller.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(authControllerProvider);
    final user = state.user;
    final migrationPreparation = state.isAuthenticated
        ? ref.watch(accountMigrationControllerProvider)
        : null;

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
              132,
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
                      state.isRestoring
                          ? Icons.sync_rounded
                          : state.isAuthenticated
                          ? Icons.verified_user_outlined
                          : Icons.phone_android_rounded,
                      size: 46,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Cuenta',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontSize: 31,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (state.isRestoring)
                      const _RestoringAccountContent()
                    else if (state.isAuthenticated && user != null)
                      _SignedInContent(
                        email: user.email ?? 'Cuenta sin email visible',
                        isLoading: state.isLoading,
                        migrationPreparation: migrationPreparation,
                        onSignOut: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .signOut();
                        },
                      )
                    else
                      _LocalModeContent(isLoading: state.isLoading),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                          height: 1.35,
                        ),
                      ),
                    ],
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

class _RestoringAccountContent extends StatelessWidget {
  const _RestoringAccountContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        LinearProgressIndicator(),
        SizedBox(height: AppSpacing.md),
        Text('Comprobando tu sesion…', textAlign: TextAlign.center),
      ],
    );
  }
}

class _LocalModeContent extends StatelessWidget {
  const _LocalModeContent({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusPill(
          icon: Icons.storage_rounded,
          label: 'Modo local',
          color: theme.colorScheme.secondary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Tu biblioteca, progreso, sesiones, estadisticas y preferencias '
          'siguen almacenados unicamente en este dispositivo.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.38,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
            ),
          ),
          child: Text(
            'Mas adelante, cuando actives una cuenta, ReadPp podra preparar la '
            'transferencia de tus datos locales para sincronizarlos en la nube.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.icon(
          onPressed: isLoading
              ? null
              : () => Navigator.pushNamed(context, '/account/transition'),
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('Crear cuenta o iniciar sesion'),
        ),
      ],
    );
  }
}

class _SignedInContent extends StatelessWidget {
  const _SignedInContent({
    required this.email,
    required this.isLoading,
    required this.migrationPreparation,
    required this.onSignOut,
  });

  final String email;
  final bool isLoading;
  final AsyncValue<AccountMigrationPreparation>? migrationPreparation;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusPill(
          icon: Icons.check_circle_outline_rounded,
          label: 'Sesion iniciada',
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        _AccountSummaryItem(
          icon: Icons.mail_outline_rounded,
          label: 'Email',
          value: email,
        ),
        if (migrationPreparation != null) ...[
          const SizedBox(height: AppSpacing.md),
          _MigrationPreparationStatus(preparation: migrationPreparation!),
        ],
        const SizedBox(height: AppSpacing.lg),
        const SyncStatusCard(),
        const SizedBox(height: AppSpacing.xl),
        OutlinedButton.icon(
          onPressed: isLoading ? null : onSignOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesion'),
        ),
      ],
    );
  }
}

class _MigrationPreparationStatus extends StatelessWidget {
  const _MigrationPreparationStatus({required this.preparation});

  final AsyncValue<AccountMigrationPreparation> preparation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return preparation.when(
      loading: () => _AccountSummaryItem(
        icon: Icons.sync_rounded,
        label: 'Preparacion local',
        value: 'Comprobando datos locales...',
      ),
      error: (_, _) => _AccountSummaryItem(
        icon: Icons.info_outline_rounded,
        label: 'Preparacion local',
        value: 'No se pudo comprobar ahora.',
      ),
      data: (result) {
        final summary = result.summary;
        final value = switch (result.status) {
          AccountMigrationPreparationStatus.unauthenticated =>
            'Inicia sesion para preparar tu biblioteca.',
          AccountMigrationPreparationStatus.noLocalData =>
            'No hay datos locales pendientes.',
          AccountMigrationPreparationStatus.readyForFutureSync =>
            '${summary.bookCount} libros, ${summary.readingSessionCount} sesiones.',
        };

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.76),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.10),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sync_alt_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Preparacion local',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (result.isReadyForFutureSync) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Listo para asociarse a tu cuenta cuando activemos la sincronizacion.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.26)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSummaryItem extends StatelessWidget {
  const _AccountSummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
