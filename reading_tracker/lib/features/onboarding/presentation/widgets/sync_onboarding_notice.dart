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
          content: Text(
            'Ya puedes iniciar sesion para preparar la sincronizacion de tu '
            'biblioteca, sesiones, perfil lector y objetivo anual.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
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
              child: const Text('Mas tarde'),
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
              label: const Text('Ir a Perfil'),
            ),
          ],
        );
      },
    );

    if (mounted) _dialogQueued = false;
  }
}
