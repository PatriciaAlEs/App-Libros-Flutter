import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/design_system.dart';
import '../providers/sync_onboarding_notice_controller.dart';

class SyncOnboardingNotice extends ConsumerStatefulWidget {
  const SyncOnboardingNotice({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SyncOnboardingNotice> createState() =>
      _SyncOnboardingNoticeState();
}

class _SyncOnboardingNoticeState extends ConsumerState<SyncOnboardingNotice> {
  bool _dialogQueued = false;

  @override
  Widget build(BuildContext context) {
    ref.listen(syncOnboardingNoticeControllerProvider, (previous, next) {
      final shouldShow = next.valueOrNull ?? false;
      if (!shouldShow || _dialogQueued) return;

      _dialogQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showNotice();
      });
    });

    return widget.child;
  }

  Future<void> _showNotice() async {
    final controller = ref.read(
      syncOnboardingNoticeControllerProvider.notifier,
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);

        return AlertDialog(
          icon: Icon(
            Icons.cloud_done_outlined,
            color: theme.colorScheme.primary,
          ),
          title: const Text('Sincronizacion disponible'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tus lecturas siguen estando guardadas en este dispositivo.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Ahora puedes iniciar sesion para proteger y sincronizar tu '
                'biblioteca en la nube cuando quieras.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Es opcional y puedes activarlo mas adelante desde Perfil.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await controller.dismiss();
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
              child: const Text('Ahora no'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await controller.dismiss();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (!mounted) return;
                Navigator.of(context).pushNamed('/account/transition');
              },
              icon: const Icon(Icons.person_outline_rounded),
              label: const Text('Ver como activar sync'),
            ),
          ],
        );
      },
    );

    if (mounted) _dialogQueued = false;
  }
}
