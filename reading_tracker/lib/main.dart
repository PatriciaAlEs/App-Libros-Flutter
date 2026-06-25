import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/backend/supabase_initializer.dart';
import 'core/observability/readpp_sentry.dart';

Future<void> main() async {
  await ReadPpSentry.init(
    appRunner: () async {
      await SupabaseInitializer.init();
      runApp(const ProviderScope(child: App()));
    },
  );
}
