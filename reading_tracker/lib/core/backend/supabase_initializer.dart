import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../navigation/app_launch_uri.dart';
import 'supabase_config.dart';

class SupabaseInitializer {
  const SupabaseInitializer._();

  static bool _isInitialized = false;

  static bool get isEnabled => _isInitialized;

  static Future<void> init() async {
    if (_isInitialized || !SupabaseConfig.isConfigured) return;

    final launchUri = Uri.base;
    if (kDebugMode) {
      debugPrint(
        '[supabase-auth] rawUri=${safeUriForLog(launchUri)} '
        'path=${appRoutePath(launchUri)} '
        'queryKeys=${launchUri.queryParameters.keys.toList()..sort()} '
        'sessionAvailable=false oauthExchangeCompleted=false',
      );
    }

    await Supabase.initialize(
      url: SupabaseConfig.url.trim(),
      publishableKey: SupabaseConfig.anonKey.trim(),
    );

    _isInitialized = true;
    if (kDebugMode) {
      final sessionAvailable =
          Supabase.instance.client.auth.currentSession != null;
      debugPrint(
        '[supabase-auth] initialized sessionAvailable=$sessionAvailable '
        'oauthExchangeCompleted='
        '${launchUri.queryParameters.containsKey('code') && sessionAvailable}',
      );
    }
  }
}
