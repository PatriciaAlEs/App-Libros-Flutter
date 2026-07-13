import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/auth/data/auth_redirect_url.dart';
import 'package:reading_tracker/core/navigation/app_launch_uri.dart';

void main() {
  group('resolveAuthRedirectUrl', () {
    test('localhost dynamic port without define uses its current origin', () {
      final redirectUrl = resolveAuthRedirectUrl(
        isWeb: true,
        baseUri: Uri.parse('http://localhost:58001/profile?x=1'),
      );

      expect(redirectUrl, 'http://localhost:58001/');
    });

    test('explicit Vercel redirect has priority over localhost origin', () {
      final redirectUrl = resolveAuthRedirectUrl(
        isWeb: true,
        baseUri: Uri.parse('http://localhost:58001/'),
        configuredUrl: ' https://readpp-web-alpha.vercel.app/ ',
      );

      expect(redirectUrl, 'https://readpp-web-alpha.vercel.app/');
      expect(redirectUrl, isNot(contains('localhost')));
    });

    test('explicit localhost redirect has priority over Vercel origin', () {
      final redirectUrl = resolveAuthRedirectUrl(
        isWeb: true,
        baseUri: Uri.parse('https://readpp-web-alpha.vercel.app/'),
        configuredUrl: 'http://localhost:61234/',
      );

      expect(redirectUrl, 'http://localhost:61234/');
      expect(redirectUrl, isNot(contains('vercel.app')));
    });

    test('fallback never mixes localhost host with production origin', () {
      final localRedirect = resolveAuthRedirectUrl(
        isWeb: true,
        baseUri: Uri.parse('http://localhost:49327/?debug=true'),
      );
      final productionRedirect = resolveAuthRedirectUrl(
        isWeb: true,
        baseUri: Uri.parse('https://readpp-web-alpha.vercel.app/?x=1'),
      );

      expect(localRedirect, 'http://localhost:49327/');
      expect(productionRedirect, 'https://readpp-web-alpha.vercel.app/');
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
      final cancellation = Uri.parse('https://readpp.dev/?error=access_denied');
      expect(isOAuthCallbackUri(cancellation), isTrue);
      expect(isOAuthCancellationUri(cancellation), isTrue);
    });

    test('does not treat a normal Home URL as callback', () {
      final uri = Uri.parse('https://readpp.dev/');
      expect(isOAuthCallbackUri(uri), isFalse);
      expect(isOAuthCancellationUri(uri), isFalse);
    });
  });

  group('OAuth callback route normalization', () {
    for (final location in [
      '/?code=fake-oauth-code',
      '/?state=fake-state',
      '/?error=access_denied',
      '/?code=fake-oauth-code&state=fake-state',
    ]) {
      test('$location selects the root path without query data', () {
        final uri = Uri.parse(location);
        expect(appRoutePath(uri), '/');
        expect(routeUri(location).queryParameters.keys, isNotEmpty);
      });
    }
  });
}
