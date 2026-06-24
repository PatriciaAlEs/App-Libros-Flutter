import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

final readPpAnalyticsProvider = Provider<ReadPpAnalytics>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return ReadPpAnalytics(client: client);
});

class ReadPpAnalytics {
  const ReadPpAnalytics({required http.Client client}) : _client = client;
  const ReadPpAnalytics.disabled() : _client = null;

  static const _enabled = bool.fromEnvironment('ANALYTICS_ENABLED');
  static const _postHogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const _postHogHost = String.fromEnvironment(
    'POSTHOG_HOST',
    defaultValue: 'https://eu.i.posthog.com',
  );
  static const _appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'debug',
  );
  static const _release = String.fromEnvironment('SENTRY_RELEASE');
  static const _anonymousIdKey = 'analytics_anonymous_id';

  final http.Client? _client;

  bool get isEnabled =>
      _client != null && _enabled && _postHogApiKey.trim().isNotEmpty;

  Future<void> trackOnboardingCompleted() {
    return _track('onboarding_completed');
  }

  Future<void> trackBookAdded({
    required String source,
    required bool hasCover,
    required bool hasTotalPages,
  }) {
    return _track('book_added', {
      'source': source,
      'has_cover': hasCover,
      'has_total_pages': hasTotalPages,
    });
  }

  Future<void> trackManualBookAdded({
    required bool hasCover,
    required bool hasTotalPages,
  }) {
    return _track('manual_book_added', {
      'has_cover': hasCover,
      'has_total_pages': hasTotalPages,
    });
  }

  Future<void> trackBookCompleted({
    required bool hasRating,
    required int? totalPages,
  }) {
    return _track('book_completed', {
      'has_rating': hasRating,
      'total_pages_bucket': _totalPagesBucket(totalPages),
    });
  }

  Future<void> trackReadingSessionCreated({
    required int minutes,
    required int pagesRead,
  }) {
    return _track('reading_session_created', {
      'minutes_bucket': _minutesBucket(minutes),
      'pages_bucket': _pagesBucket(pagesRead),
    });
  }

  Future<void> trackSearchStarted({
    required int queryLength,
    required int queryWords,
  }) {
    return _track('search_started', {
      'source': 'open_library',
      'query_length': queryLength,
      'query_words': queryWords,
    });
  }

  Future<void> trackSearchCompleted({
    required Duration duration,
    required int resultsCount,
  }) {
    return _track('search_completed', {
      'source': 'open_library',
      'duration_ms': duration.inMilliseconds,
      'results_count_bucket': _resultsCountBucket(resultsCount),
    });
  }

  Future<void> trackSearchFailed({
    required Duration duration,
    required String errorType,
  }) {
    return _track('search_failed', {
      'source': 'open_library',
      'duration_ms': duration.inMilliseconds,
      'error_type': errorType,
    });
  }

  Future<void> trackSearchNoResults({
    required Duration duration,
    required int queryLength,
    required int queryWords,
  }) {
    return _track('search_no_results', {
      'source': 'open_library',
      'duration_ms': duration.inMilliseconds,
      'query_length': queryLength,
      'query_words': queryWords,
    });
  }

  Future<void> trackAnnualGoalCreated({required int goalBooks}) {
    return _track('annual_goal_created', {
      'goal_books_bucket': _goalBooksBucket(goalBooks),
    });
  }

  Future<void> trackAnnualGoalUpdated({required int goalBooks}) {
    return _track('annual_goal_updated', {
      'goal_books_bucket': _goalBooksBucket(goalBooks),
    });
  }

  Future<void> _track(
    String event, [
    Map<String, Object?> properties = const {},
  ]) async {
    if (!isEnabled) return;

    try {
      final distinctId = await _anonymousId();
      final eventProperties = <String, Object?>{
        'app_env': _appEnv,
        'platform': _platformName,
        r'$process_person_profile': false,
        if (_release.trim().isNotEmpty) 'release': _release.trim(),
        ...properties,
      };
      final payload = <String, Object?>{
        'api_key': _postHogApiKey.trim(),
        'event': event,
        'distinct_id': distinctId,
        'properties': eventProperties,
      };

      await _client!
          .post(
            _captureUri,
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 3));
    } catch (error, stackTrace) {
      if (!kDebugMode) return;
      debugPrint('ReadPp analytics event failed: $event ($error)');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<String> _anonymousId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_anonymousIdKey);
    if (existing != null && existing.trim().isNotEmpty) return existing;

    final created = const Uuid().v4();
    await preferences.setString(_anonymousIdKey, created);
    return created;
  }

  Uri get _captureUri {
    final normalizedHost = _postHogHost.trim().replaceFirst(RegExp(r'/+$'), '');
    return Uri.parse('$normalizedHost/i/v0/e/');
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  String _totalPagesBucket(int? totalPages) {
    if (totalPages == null || totalPages <= 0) return 'unknown';
    if (totalPages <= 200) return 'short';
    if (totalPages <= 500) return 'medium';
    return 'long';
  }

  String _minutesBucket(int minutes) {
    if (minutes <= 20) return 'short';
    if (minutes <= 60) return 'medium';
    return 'long';
  }

  String _pagesBucket(int pagesRead) {
    if (pagesRead <= 10) return 'low';
    if (pagesRead <= 40) return 'medium';
    return 'high';
  }

  String _resultsCountBucket(int resultsCount) {
    if (resultsCount <= 0) return 'zero';
    if (resultsCount <= 3) return 'low';
    if (resultsCount <= 10) return 'medium';
    return 'high';
  }

  String _goalBooksBucket(int goalBooks) {
    if (goalBooks <= 12) return 'low';
    if (goalBooks <= 36) return 'medium';
    return 'high';
  }
}

({int length, int words}) analyticsQueryMetrics(String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return (length: 0, words: 0);

  return (
    length: trimmed.length,
    words: trimmed
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length,
  );
}
