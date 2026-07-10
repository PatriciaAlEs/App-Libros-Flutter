import 'package:flutter/foundation.dart';

const _configuredAuthRedirectUrl = String.fromEnvironment('AUTH_REDIRECT_URL');

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

bool isOAuthCallbackUri(Uri uri) {
  final query = uri.queryParameters;
  return query.containsKey('code') ||
      query.containsKey('error') ||
      uri.fragment.contains('access_token=') ||
      uri.fragment.contains('error=');
}

bool isOAuthCancellationUri(Uri uri) {
  final error = uri.queryParameters['error']?.toLowerCase();
  final description = uri.queryParameters['error_description']?.toLowerCase();
  final fragment = uri.fragment.toLowerCase();
  return error == 'access_denied' ||
      description?.contains('cancel') == true ||
      fragment.contains('error=access_denied');
}
