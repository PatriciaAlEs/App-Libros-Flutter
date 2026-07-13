import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/app_launch_uri.dart';
import '../controllers/auth_controller.dart';

class OAuthCallbackBootstrap extends ConsumerStatefulWidget {
  const OAuthCallbackBootstrap({
    required this.child,
    required this.launchUri,
    this.onCleanUrl,
    super.key,
  });

  final Widget child;
  final Uri launchUri;
  final ValueChanged<String>? onCleanUrl;

  @override
  ConsumerState<OAuthCallbackBootstrap> createState() =>
      _OAuthCallbackBootstrapState();
}

class _OAuthCallbackBootstrapState
    extends ConsumerState<OAuthCallbackBootstrap> {
  bool _urlCleaned = false;
  late final ProviderSubscription<AuthControllerState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = ref.listenManual<AuthControllerState>(
      authControllerProvider,
      _onAuthChanged,
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _authSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _onAuthChanged(
    AuthControllerState? previous,
    AuthControllerState authState,
  ) {
    final queryKeys = widget.launchUri.queryParameters.keys.toList()..sort();
    final hasCode = queryKeys.contains('code');
    final exchangeCompleted = hasCode && authState.isAuthenticated;

    if (kDebugMode) {
      debugPrint(
        '[oauth-callback] timestamp=${DateTime.now().toIso8601String()} '
        'source=urlCleanup rawUri=${safeUriForLog(widget.launchUri)} '
        'path=${appRoutePath(widget.launchUri)} queryKeys=$queryKeys '
        'authState=${authState.isAuthenticated ? 'authenticated' : 'anonymous'} '
        'sessionAvailable=${authState.user != null} '
        'oauthExchangeCompleted=$exchangeCompleted',
      );
    }

    if (!_urlCleaned && exchangeCompleted) {
      _urlCleaned = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (kDebugMode) {
          debugPrint(
            '[oauth-callback] timestamp=${DateTime.now().toIso8601String()} '
            'source=urlCleanup urlCleanup=replace-with-root',
          );
        }
        final onCleanUrl = widget.onCleanUrl;
        if (onCleanUrl != null) {
          onCleanUrl('/');
        } else {
          cleanOAuthCallbackUrl();
        }
      });
    }
  }
}
