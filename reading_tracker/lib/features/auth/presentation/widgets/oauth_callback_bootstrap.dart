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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final queryKeys = widget.launchUri.queryParameters.keys.toList()..sort();
    final hasCode = queryKeys.contains('code');
    final exchangeCompleted = hasCode && authState.isAuthenticated;

    if (kDebugMode) {
      debugPrint(
        '[oauth-callback] rawUri=${safeUriForLog(widget.launchUri)} '
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
          debugPrint('[oauth-callback] replacing browser URL with /');
        }
        final onCleanUrl = widget.onCleanUrl;
        if (onCleanUrl != null) {
          onCleanUrl('/');
        } else {
          cleanOAuthCallbackUrl();
        }
      });
    }

    return widget.child;
  }
}
