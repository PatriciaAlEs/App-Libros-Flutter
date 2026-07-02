import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/sync_status_state.dart';
import '../controllers/sync_status_controller.dart';

class SyncStatusCard extends ConsumerWidget {
  const SyncStatusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(
      authControllerProvider.select((state) => state.user?.id),
    );
    if (userId == null) return const SizedBox.shrink();

    final syncState = ref.watch(syncStatusStateProvider);

    return syncState.when(
      loading: () => const _SyncStatusSurface(
        state: SyncStatusState(status: SyncUiStatus.idle),
        isLoading: true,
      ),
      error: (_, _) => _SyncStatusSurface(
        state: SyncStatusState(
          status: SyncUiStatus.failed,
          lastSyncResult: LastSyncResult(
            status: LastSyncResultStatus.failed,
            finishedAt: DateTime(0),
            message: 'No se pudo leer el estado de sincronizacion.',
          ),
        ),
        onSyncNow: () {
          ref
              .read(syncStatusControllerProvider.notifier)
              .syncNow(userId: userId);
        },
      ),
      data: (state) {
        if (state == null) return const SizedBox.shrink();
        return _SyncStatusSurface(
          state: state,
          onSyncNow: state.status == SyncUiStatus.syncing
              ? null
              : () async {
                  await ref
                      .read(syncStatusControllerProvider.notifier)
                      .syncNow(userId: userId);
                  if (!context.mounted) return;
                  final syncResult = ref.read(syncStatusControllerProvider);
                  if (syncResult.status == SyncUiStatus.synced) {
                    showBookCompletionCelebration(context);
                    await showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (_) => const _SyncSuccessSheet(),
                    );
                  }
                },
        );
      },
    );
  }
}

class _SyncSuccessSheet extends StatelessWidget {
  const _SyncSuccessSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_done_rounded,
                color: theme.colorScheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sincronización completada',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tu biblioteca ya está actualizada.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              key: const Key('sync_success_home_button'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (_) => false);
              },
              icon: const Icon(Icons.home_rounded),
              label: const Text('Ir a Inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SyncStatusSurface extends StatelessWidget {
  const _SyncStatusSurface({
    required this.state,
    this.onSyncNow,
    this.isLoading = false,
  });

  final SyncStatusState state;
  final VoidCallback? onSyncNow;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _statusColor(theme, state.status);

    return Container(
      key: const Key('sync_status_card'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.14),
                ),
                child: isLoading || state.status == SyncUiStatus.syncing
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: accent,
                        ),
                      )
                    : Icon(_statusIcon(state.status), color: accent, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sincronizacion',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _statusLabel(state.status),
                      key: const Key('sync_status_label'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _statusDescription(state),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MetricChip(
                label: 'Pendientes',
                value: state.pendingCount.toString(),
              ),
              _MetricChip(
                label: 'Conflictos',
                value: state.conflictCount.toString(),
              ),
              _MetricChip(
                label: 'Ultima sync',
                value: _formatLastSync(state.lastSyncAt),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            key: const Key('sync_now_button'),
            onPressed: isLoading ? null : onSyncNow,
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Sincronizar ahora'),
          ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

IconData _statusIcon(SyncUiStatus status) {
  return switch (status) {
    SyncUiStatus.idle => Icons.cloud_queue_rounded,
    SyncUiStatus.syncing => Icons.sync_rounded,
    SyncUiStatus.synced => Icons.cloud_done_outlined,
    SyncUiStatus.pendingChanges => Icons.cloud_upload_outlined,
    SyncUiStatus.conflict => Icons.warning_amber_rounded,
    SyncUiStatus.failed => Icons.error_outline_rounded,
  };
}

Color _statusColor(ThemeData theme, SyncUiStatus status) {
  return switch (status) {
    SyncUiStatus.conflict || SyncUiStatus.failed => theme.colorScheme.error,
    SyncUiStatus.pendingChanges => theme.colorScheme.secondary,
    _ => theme.colorScheme.primary,
  };
}

String _statusLabel(SyncUiStatus status) {
  return switch (status) {
    SyncUiStatus.idle => 'Sin actividad reciente',
    SyncUiStatus.syncing => 'Sincronizando',
    SyncUiStatus.synced => 'Todo sincronizado',
    SyncUiStatus.pendingChanges => 'Cambios pendientes',
    SyncUiStatus.conflict => 'Conflictos detectados',
    SyncUiStatus.failed => 'Sincronizacion fallida',
  };
}

String _statusDescription(SyncStatusState state) {
  if (state.status == SyncUiStatus.failed &&
      state.lastSyncResult?.message != null) {
    return state.lastSyncResult!.message!;
  }

  return switch (state.status) {
    SyncUiStatus.idle =>
      'Conecta tu cuenta para mantener tus datos preparados.',
    SyncUiStatus.syncing => 'Estamos actualizando tus datos en segundo plano.',
    SyncUiStatus.synced => 'Tu biblioteca y progreso estan al dia.',
    SyncUiStatus.pendingChanges =>
      'Hay cambios locales esperando sincronizacion.',
    SyncUiStatus.conflict =>
      'Hay datos que necesitan revision antes de resolverse.',
    SyncUiStatus.failed => 'No se pudo completar la ultima sincronizacion.',
  };
}

String _formatLastSync(DateTime? value) {
  if (value == null) return 'Nunca';
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}
