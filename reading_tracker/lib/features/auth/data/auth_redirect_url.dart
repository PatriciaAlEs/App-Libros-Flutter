import 'package:flutter/foundation.dart';

const _configuredAuthRedirectUrl = String.fromEnvironment(
  'AUTH_REDIRECT_URL',
);

String? get authRedirectUrl => resolveAuthRedirectUrl(
  isWeb: kIsWeb,
  baseUri: Uri.base,
  configuredUrl: _configuredAuthRedirectUrl,
);

String? resolveAuthRedirectUrl({
  required bool isWeb,
  required Uri baseUri,
  String configuredUrl = '',
}) {
  if (!isWeb) return null;

  final configured = configuredUrl.trim();
  if (configured.isNotEmpty) return configured;

  return Uri(
    scheme: baseUri.scheme,
    host: baseUri.host,
    port: baseUri.hasPort ? baseUri.port : null,
    path: '/',
  ).toString();
}
