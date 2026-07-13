import 'package:flutter/foundation.dart';

import 'browser_url_cleaner_stub.dart'
    if (dart.library.js_interop) 'browser_url_cleaner_web.dart';

String appRoutePath(Uri uri) => uri.path.isEmpty ? '/' : uri.path;

Uri routeUri(String? routeName) {
  final raw = routeName?.trim();
  if (raw == null || raw.isEmpty) return Uri(path: '/');
  return Uri.parse(raw);
}

String safeUriForLog(Uri uri) {
  final keys = uri.queryParameters.keys.toList()..sort();
  final origin = uri.hasScheme && uri.host.isNotEmpty ? uri.origin : '';
  return '$origin${appRoutePath(uri)}'
      '${keys.isEmpty ? '' : '?keys=${keys.join(',')}'}';
}

bool get hasOAuthCallbackParameters {
  final keys = Uri.base.queryParameters.keys;
  return keys.any(
    const {'code', 'state', 'error', 'error_description'}.contains,
  );
}

void cleanOAuthCallbackUrl() {
  if (!kIsWeb || !hasOAuthCallbackParameters) return;
  replaceBrowserUrl('/');
}
