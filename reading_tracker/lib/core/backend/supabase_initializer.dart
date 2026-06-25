import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class SupabaseInitializer {
  const SupabaseInitializer._();

  static bool _isInitialized = false;

  static bool get isEnabled => _isInitialized;

  static Future<void> init() async {
    if (_isInitialized || !SupabaseConfig.isConfigured) return;

    await Supabase.initialize(
      url: SupabaseConfig.url.trim(),
      publishableKey: SupabaseConfig.anonKey.trim(),
    );

    _isInitialized = true;
  }
}
