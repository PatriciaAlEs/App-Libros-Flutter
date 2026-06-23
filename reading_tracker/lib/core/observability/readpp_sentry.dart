import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

typedef ReadPpAppRunner = FutureOr<void> Function();

class ReadPpSentry {
  const ReadPpSentry._();

  static const _dsn = String.fromEnvironment('SENTRY_DSN');
  static const _environmentOverride = String.fromEnvironment(
    'SENTRY_ENVIRONMENT',
  );
  static const _release = String.fromEnvironment(
    'SENTRY_RELEASE',
    defaultValue: 'reading_tracker@1.0.0+1',
  );

  static bool get isEnabled => kReleaseMode && _dsn.trim().isNotEmpty;

  static String get environment {
    if (_environmentOverride.trim().isNotEmpty) {
      return _environmentOverride.trim();
    }
    if (kReleaseMode) return 'release';
    if (kProfileMode) return 'profile';
    return 'debug';
  }

  static String get release => _release;

  static String get platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  static Future<void> init({required ReadPpAppRunner appRunner}) async {
    WidgetsFlutterBinding.ensureInitialized();

    if (!isEnabled) {
      await appRunner();
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = _dsn.trim();
      options.environment = environment;
      options.release = _release;
      options.attachStacktrace = true;
      options.sendDefaultPii = false;
      options.enableAutoSessionTracking = true;
      options.tracesSampleRate = 0.0;
      options.beforeSend = (event, hint) => isEnabled ? event : null;
    }, appRunner: () async => appRunner());
  }

  static List<NavigatorObserver> navigatorObservers() {
    if (!isEnabled) return const [];
    return [SentryNavigatorObserver()];
  }

  static Future<void> addBookSearchBreadcrumb({
    required String event,
    required String provider,
    required String query,
    Duration? duration,
    int? resultCount,
    String? failureKind,
    int? statusCode,
  }) async {
    if (!isEnabled) return;

    final data = <String, Object?>{
      'provider': provider,
      'query': query,
      'platform': platformName,
      'release': release,
    };
    if (duration != null) data['duration_ms'] = duration.inMilliseconds;
    if (resultCount != null) data['result_count'] = resultCount;
    if (failureKind != null) data['failure_kind'] = failureKind;
    if (statusCode != null) data['status_code'] = statusCode;

    await Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'book_search',
        message: event,
        level: failureKind == null ? SentryLevel.info : SentryLevel.error,
        data: data,
      ),
    );
  }

  static Future<void> captureOpenLibraryException({
    required Object exception,
    required StackTrace stackTrace,
    required String query,
    required Duration duration,
    required String failureKind,
    int? statusCode,
  }) async {
    if (!isEnabled) return;

    final context = <String, Object?>{
      'query': query,
      'duration_ms': duration.inMilliseconds,
      'platform': platformName,
      'release': release,
    };
    if (statusCode != null) context['status_code'] = statusCode;

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        scope.setTag('integration', 'open_library');
        scope.setTag('book_search.provider', 'open_library');
        scope.setTag('book_search.failure_kind', failureKind);
        if (statusCode != null) {
          scope.setTag('http.status_code', '$statusCode');
        }
        scope.setContexts('open_library_search', context);
      },
    );
  }
}
