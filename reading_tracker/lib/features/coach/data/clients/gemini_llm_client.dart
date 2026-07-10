import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/coach_message.dart';
import '../../domain/services/llm_client.dart';

class GeminiConfig {
  GeminiConfig({required String apiKey, required String model, Uri? baseUri})
    : apiKey = _required(apiKey, 'GEMINI_API_KEY'),
      model = _required(model, 'GEMINI_MODEL'),
      baseUri = _validateBaseUri(
        baseUri ??
            Uri.parse('https://generativelanguage.googleapis.com/v1beta'),
      );

  final String apiKey;
  final String model;
  final Uri baseUri;

  static String _required(String value, String name) {
    final normalized = value.trim();
    if (normalized.isEmpty || normalized == 'missing-gemini-api-key') {
      throw GeminiConfigurationException('$name is missing');
    }
    return normalized;
  }

  static Uri _validateBaseUri(Uri value) {
    if (!value.hasScheme || value.host.isEmpty) {
      throw const GeminiConfigurationException(
        'GEMINI_BASE_URL must be an absolute URL',
      );
    }
    final path = value.path.toLowerCase();
    if (path.contains('/openai/') ||
        path.endsWith('/chat/completions') ||
        path.contains('/models/')) {
      throw const GeminiConfigurationException(
        'GEMINI_BASE_URL must be the API root, for example '
        'https://generativelanguage.googleapis.com/v1beta; do not include '
        '/openai/chat/completions or /models/...',
      );
    }
    return value;
  }
}

class GeminiConfigurationException implements Exception {
  const GeminiConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'GeminiConfigurationException: $message';
}

class GeminiLlmException implements Exception {
  const GeminiLlmException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'GeminiLlmException: $message'
      : 'GeminiLlmException: $message (statusCode: $statusCode)';
}

class GeminiLlmClient implements LlmClient {
  const GeminiLlmClient({required this.config, required this.httpClient});

  final GeminiConfig config;
  final http.Client httpClient;

  @override
  Future<String> complete({required List<CoachMessage> messages}) async {
    final payload = _buildPayload(messages);
    http.Response response;
    try {
      response = await httpClient.post(
        _endpoint('generateContent'),
        headers: _headers(stream: false),
        body: jsonEncode(payload),
      );
    } catch (error) {
      _debugFailure('http.complete.send', error);
      rethrow;
    }
    if (!_isSuccessful(response.statusCode)) {
      throw _httpFailure(response.statusCode, response.body);
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw GeminiLlmException('Invalid JSON response: ${error.message}');
    }
    final apiError = _apiError(decoded);
    if (apiError != null) throw GeminiLlmException(apiError);
    return _extractText(decoded) ?? '';
  }

  @override
  Stream<String> streamCompletion({
    required List<CoachMessage> messages,
  }) async* {
    final request =
        http.Request('POST', _endpoint('streamGenerateContent', stream: true))
          ..headers.addAll(_headers(stream: true))
          ..body = jsonEncode(_buildPayload(messages));

    late http.StreamedResponse response;
    try {
      response = await httpClient.send(request);
    } catch (error) {
      _debugFailure('http.stream.send', error);
      rethrow;
    }
    if (!_isSuccessful(response.statusCode)) {
      final body = await response.stream.bytesToString();
      throw _httpFailure(response.statusCode, body);
    }

    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;
      final data = trimmed.substring(5).trimLeft();
      if (data.isEmpty || data == '[DONE]') continue;

      final Object? event;
      try {
        event = jsonDecode(data);
      } on FormatException catch (error) {
        throw GeminiLlmException('Invalid streaming JSON: ${error.message}');
      }
      final apiError = _apiError(event);
      if (apiError != null) throw GeminiLlmException(apiError);
      final text = _extractText(event);
      if (text != null && text.isNotEmpty) yield text;
    }
  }

  Map<String, Object> _buildPayload(List<CoachMessage> messages) {
    final nonEmpty = messages
        .where((message) => message.content.trim().isNotEmpty)
        .toList(growable: false);
    if (nonEmpty.isEmpty) {
      throw ArgumentError.value(
        messages,
        'messages',
        'Messages cannot be empty',
      );
    }

    final systemText = nonEmpty
        .where((message) => message.role == CoachMessageRole.system)
        .map((message) => message.content)
        .join('\n\n');
    final contents = <Map<String, Object>>[
      for (final message in nonEmpty)
        if (message.role != CoachMessageRole.system)
          {
            'role': message.role == CoachMessageRole.assistant
                ? 'model'
                : 'user',
            'parts': [
              {'text': message.content},
            ],
          },
    ];
    if (contents.isEmpty) {
      throw ArgumentError.value(
        messages,
        'messages',
        'At least one user or assistant message is required',
      );
    }

    return {
      if (systemText.isNotEmpty)
        'system_instruction': {
          'parts': [
            {'text': systemText},
          ],
        },
      'contents': contents,
    };
  }

  Uri _endpoint(String operation, {bool stream = false}) {
    final root = config.baseUri.toString().replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse(
      '$root/models/${Uri.encodeComponent(config.model)}:$operation',
    );
    return stream ? uri.replace(queryParameters: {'alt': 'sse'}) : uri;
  }

  Map<String, String> _headers({required bool stream}) => {
    'x-goog-api-key': config.apiKey,
    'Content-Type': 'application/json',
    'Accept': stream ? 'text/event-stream' : 'application/json',
  };

  bool _isSuccessful(int statusCode) => statusCode >= 200 && statusCode < 300;

  GeminiLlmException _httpFailure(int statusCode, String body) {
    final sanitized = _errorSummary(body);
    final error = GeminiLlmException(
      'Request failed: $sanitized',
      statusCode: statusCode,
    );
    _debugFailure('http.response', error, statusCode: statusCode);
    return error;
  }

  String? _apiError(Object? body) {
    if (body is! Map<String, dynamic>) return null;
    final error = body['error'];
    if (error == null) return null;
    if (error is Map<String, dynamic>) {
      final code = error['code'];
      final status = error['status'];
      final message = error['message'];
      return 'Gemini API error: code=${code ?? 'n/a'} '
          'status=${status ?? 'n/a'} message=${_sanitize('$message')}';
    }
    return 'Gemini API error';
  }

  String _errorSummary(String body) {
    try {
      final decoded = jsonDecode(body);
      return _apiError(decoded) ?? 'Gemini returned an HTTP error';
    } on FormatException {
      return 'Gemini returned a non-JSON HTTP error';
    }
  }

  String? _extractText(Object? body) {
    if (body is! Map<String, dynamic>) return null;
    final candidates = body['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;
    final candidate = candidates.first;
    if (candidate is! Map<String, dynamic>) return null;
    final content = candidate['content'];
    if (content is! Map<String, dynamic>) return null;
    final parts = content['parts'];
    if (parts is! List) return null;
    final text = <String>[];
    for (final part in parts) {
      if (part is! Map<String, dynamic>) continue;
      final value = part['text'];
      if (value is String && value.isNotEmpty) text.add(value);
    }
    return text.isEmpty ? null : text.join();
  }

  void _debugFailure(String phase, Object error, {int? statusCode}) {
    if (!kDebugMode) return;
    debugPrint(
      '[Coach/Gemini] phase=$phase status=${statusCode ?? 'n/a'} '
      'exception=${error.runtimeType} error=${_sanitize('$error')}',
    );
  }

  String _sanitize(String value) {
    final withoutKey = value.replaceAllMapped(
      RegExp(
        r'("(?:key|api[_-]?key|x-goog-api-key)"\s*:\s*")[^"]+(\")',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}[REDACTED]${match.group(2)}',
    );
    const maxLength = 800;
    return withoutKey.length <= maxLength
        ? withoutKey
        : '${withoutKey.substring(0, maxLength)}…';
  }
}
