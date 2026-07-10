import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/auth/data/auth_redirect_url.dart';

void main() {
  group('resolveAuthRedirectUrl', () {
    test('uses the current web origin instead of a localhost fallback', () {
      final redirectUrl = resolveAuthRedirectUrl(
        isWeb: true,
        baseUri: Uri.parse('https://readpp-web-alpha.vercel.app/profile?x=1'),
      );

      expect(redirectUrl, 'https://readpp-web-alpha.vercel.app/');
    });

    test('supports an explicit canonical production URL', () {
      final redirectUrl = resolveAuthRedirectUrl(
        isWeb: true,
        baseUri: Uri.parse('https://preview.vercel.app/'),
        configuredUrl: ' https://readpp.example.com/auth ',
      );

      expect(redirectUrl, 'https://readpp.example.com/auth');
    });

    test('does not override the validated native deep-link flow', () {
      final redirectUrl = resolveAuthRedirectUrl(
        isWeb: false,
        baseUri: Uri.parse('https://readpp-web-alpha.vercel.app/'),
        configuredUrl: 'https://readpp.example.com/',
      );

      expect(redirectUrl, isNull);
    });
  });

  group('OAuth callback detection', () {
    test('detects callback code and cancellation', () {
      expect(
        isOAuthCallbackUri(Uri.parse('https://readpp.dev/?code=oauth-code')),
        isTrue,
      );
      final cancellation = Uri.parse(
        'https://readpp.dev/?error=access_denied',
      );
      expect(isOAuthCallbackUri(cancellation), isTrue);
      expect(isOAuthCancellationUri(cancellation), isTrue);
    });

    test('does not treat a normal Home URL as callback', () {
      final uri = Uri.parse('https://readpp.dev/');
      expect(isOAuthCallbackUri(uri), isFalse);
      expect(isOAuthCancellationUri(uri), isFalse);
    });
  });
}
