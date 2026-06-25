import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_initializer.dart';

final supabaseClientProvider = Provider<SupabaseClient?>((ref) {
  if (!SupabaseInitializer.isEnabled) return null;
  return Supabase.instance.client;
});

final isSupabaseEnabledProvider = Provider<bool>((ref) {
  return SupabaseInitializer.isEnabled;
});
