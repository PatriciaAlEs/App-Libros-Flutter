import 'package:flutter/foundation.dart';

const _configuredAuthRedirectUrl = String.fromEnvironment('AUTH_REDIRECT_URL');

String? get authRedirectUrl {
  final isExplicitRedirect = _configuredAuthRedirectUrl.trim().isNotEmpty;
  final redirectUrl = resolveAuthRedirectUrl(
    isWeb: kIsWeb,
    baseUri: Uri.base,
    configuredUrl: _configuredAuthRedirectUrl,
  );
  if (kDebugMode) {
    debugPrint(
      '[auth-redirect] authRedirectUrl=$redirectUrl '
      'currentOrigin=${kIsWeb ? Uri.base.origin : 'native'} '
      'isExplicitRedirect=$isExplicitRedirect',
    );
  }
  return redirectUrl;
}

String? resolveAuthRedirectUrl({
  required bool isWeb,
  required Uri baseUri,
  String configuredUrl = '',
}) {
  if (!isWeb) return null;

  final configured = configuredUrl.trim();
  if (configured.isNotEmpty) return configured;

  return '${baseUri.origin}/';
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
