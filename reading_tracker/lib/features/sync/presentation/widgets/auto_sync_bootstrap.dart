import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/sync_status_controller.dart';

class AutoSyncBootstrap extends ConsumerStatefulWidget {
  const AutoSyncBootstrap({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AutoSyncBootstrap> createState() => _AutoSyncBootstrapState();
}

class _AutoSyncBootstrapState extends ConsumerState<AutoSyncBootstrap> {
  String? _lastTriggeredUserId;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(
      authControllerProvider.select((state) => state.user?.id),
    );
    _scheduleSyncIfNeeded(userId);
    return widget.child;
  }

  void _scheduleSyncIfNeeded(String? userId) {
    if (userId == null) {
      _lastTriggeredUserId = null;
      return;
    }

    if (_lastTriggeredUserId == userId) return;
    _lastTriggeredUserId = userId;

    scheduleMicrotask(() {
      if (!mounted) return;
      unawaited(
        ref.read(syncStatusControllerProvider.notifier).syncNow(userId: userId),
      );
    });
  }
}
