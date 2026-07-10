import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/coach_message.dart';
import '../../domain/services/llm_client.dart';

class OpenAiConfig {
  OpenAiConfig({required String apiKey, required String model, Uri? baseUri})
    : apiKey = _validateValue(apiKey, 'apiKey'),
      model = _validateValue(model, 'model'),
      baseUri = baseUri ?? Uri.parse('https://api.openai.com/v1/responses');

  final String apiKey;
  final String model;
  final Uri baseUri;

  bool get hasApiKey => apiKey != 'missing-openai-api-key';

  static String _validateValue(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(value, name, '$name cannot be empty');
    }
    return value;
  }
}

class OpenAiLlmException implements Exception {
  const OpenAiLlmException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode;
    if (code == null) return 'OpenAiLlmException: $message';
    return 'OpenAiLlmException: $message (statusCode: $code)';
  }
}

class OpenAiLlmClient implements LlmClient {
  const OpenAiLlmClient({required this.config, required this.httpClient});

  final OpenAiConfig config;
  final http.Client httpClient;

  @override
  Future<String> complete({required List<CoachMessage> messages}) async {
    if (messages.isEmpty) {
      throw ArgumentError.value(
        messages,
        'messages',
        'Messages cannot be empty',
      );
    }

    _validateRuntimeConfiguration();
    http.Response response;
    try {
      response = await httpClient.post(
        config.baseUri,
        headers: _headers,
        body: jsonEncode(_requestBody(messages, stream: false)),
      );
    } catch (error, stackTrace) {
      _logFailure('http.complete.send', error, stackTrace: stackTrace);
      rethrow;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _httpFailure(
        phase: 'http.complete.response',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw OpenAiLlmException('Invalid JSON response: ${error.message}');
    }

    final text = _extractText(body);
    if (text == null) {
      throw const OpenAiLlmException('Response did not contain assistant text');
    }

    return text;
  }

  @override
  Stream<String> streamCompletion({
    required List<CoachMessage> messages,
  }) async* {
    if (messages.isEmpty) {
      throw ArgumentError.value(
        messages,
        'messages',
        'Messages cannot be empty',
      );
    }

    _validateRuntimeConfiguration();
    final request = http.Request('POST', config.baseUri)
      ..headers.addAll(_headers)
      ..body = jsonEncode(_requestBody(messages, stream: true));
    late http.StreamedResponse response;
    try {
      response = await httpClient.send(request);
    } catch (error, stackTrace) {
      _logFailure('http.stream.send', error, stackTrace: stackTrace);
      rethrow;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = await response.stream.bytesToString();
      throw _httpFailure(
        phase: 'http.stream.response',
        statusCode: response.statusCode,
        body: errorBody,
      );
    }

    try {
      yield* _parseStream(response.stream);
    } catch (error, stackTrace) {
      _logFailure('sse.parse', error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Stream<String> _parseStream(Stream<List<int>> bytes) async* {
    await for (final line
        in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('data:')) continue;

      final data = trimmed.substring(5).trimLeft();
      if (data == '[DONE]') return;

      final Object? event;
      try {
        event = jsonDecode(data);
      } on FormatException catch (error) {
        throw OpenAiLlmException('Invalid streaming JSON: ${error.message}');
      }
      if (event is! Map<String, dynamic>) continue;

      final eventError = event['error'];
      if (eventError != null || event['type'] == 'error') {
        final sanitized = _sanitizeErrorBody(jsonEncode(eventError ?? event));
        throw OpenAiLlmException('Streaming API error: $sanitized');
      }

      final type = event['type'];
      if (type == 'response.output_text.delta') {
        final delta = event['delta'];
        if (delta is String && delta.isNotEmpty) yield delta;
        continue;
      }

      final choices = event['choices'];
      if (choices is List && choices.isNotEmpty) {
        final choice = choices.first;
        if (choice is Map<String, dynamic>) {
          final delta = choice['delta'];
          if (delta is Map<String, dynamic>) {
            final content = delta['content'];
            if (content is String && content.isNotEmpty) yield content;
          }
        }
      }
    }
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${config.apiKey}',
    'Content-Type': 'application/json',
    'Accept': 'text/event-stream',
  };

  Map<String, Object> _requestBody(
    List<CoachMessage> messages, {
    required bool stream,
  }) => {
    'model': config.model,
    if (_usesChatCompletions)
      'messages': messages.map(_messageToJson).toList()
    else
      'input': messages.map(_messageToJson).toList(),
    if (stream) 'stream': true,
  };

  bool get _usesChatCompletions =>
      config.baseUri.path.endsWith('/chat/completions');

  void _validateRuntimeConfiguration() {
    if (config.hasApiKey) return;
    const error = OpenAiLlmException(
      'OPENAI_API_KEY is missing. Start Flutter with a Dart define.',
    );
    _logFailure('configuration', error);
    throw error;
  }

  OpenAiLlmException _httpFailure({
    required String phase,
    required int statusCode,
    required String body,
  }) {
    final sanitizedBody = _sanitizeErrorBody(body);
    final error = OpenAiLlmException(
      'Request failed: $sanitizedBody',
      statusCode: statusCode,
    );
    _logFailure(phase, error, statusCode: statusCode, body: sanitizedBody);
    return error;
  }

  void _logFailure(
    String phase,
    Object error, {
    int? statusCode,
    String? body,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[Coach/OpenAI] phase=$phase status=${statusCode ?? 'n/a'} '
      'exception=${error.runtimeType} error=${_sanitizeErrorBody('$error')}'
      '${body == null ? '' : ' body=$body'}',
    );
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  String _sanitizeErrorBody(String value) {
    final withoutBearer = value.replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9._-]+', caseSensitive: false),
      'Bearer [REDACTED]',
    );
    final withoutJsonSecrets = withoutBearer.replaceAllMapped(
      RegExp(
        r'("(?:api[_-]?key|authorization)"\s*:\s*")[^"]+(\")',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}[REDACTED]${match.group(2)}',
    );
    const maxLength = 800;
    return withoutJsonSecrets.length <= maxLength
        ? withoutJsonSecrets
        : '${withoutJsonSecrets.substring(0, maxLength)}…';
  }

  Map<String, String> _messageToJson(CoachMessage message) {
    return {'role': _roleToString(message.role), 'content': message.content};
  }

  String _roleToString(CoachMessageRole role) {
    switch (role) {
      case CoachMessageRole.system:
        return 'system';
      case CoachMessageRole.user:
        return 'user';
      case CoachMessageRole.assistant:
        return 'assistant';
    }
  }

  String? _extractText(Object? body) {
    if (body is! Map<String, dynamic>) return null;

    final choices = body['choices'];
    if (choices is List && choices.isNotEmpty) {
      final firstChoice = choices.first;
      if (firstChoice is Map<String, dynamic>) {
        final message = firstChoice['message'];
        if (message is Map<String, dynamic>) {
          final content = message['content'];
          if (content is String && content.trim().isNotEmpty) {
            return content;
          }
        }
      }
    }

    final outputText = body['output_text'];
    if (outputText is String && outputText.trim().isNotEmpty) {
      return outputText;
    }

    final output = body['output'];
    if (output is! List) return null;

    final textParts = <String>[];
    for (final outputItem in output) {
      if (outputItem is! Map<String, dynamic>) continue;

      final content = outputItem['content'];
      if (content is! List) continue;

      for (final contentItem in content) {
        if (contentItem is! Map<String, dynamic>) continue;

        final text = contentItem['text'];
        if (text is String && text.trim().isNotEmpty) {
          textParts.add(text);
        }
      }
    }

    if (textParts.isEmpty) return null;
    return textParts.join('\n');
  }
}
