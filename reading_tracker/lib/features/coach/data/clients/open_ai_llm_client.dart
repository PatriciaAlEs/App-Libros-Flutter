import 'dart:convert';

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

    final response = await httpClient.post(
      config.baseUri,
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': config.model,
        'input': messages.map(_messageToJson).toList(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OpenAiLlmException(
        'Request failed',
        statusCode: response.statusCode,
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

    final request = http.Request('POST', config.baseUri)
      ..headers.addAll({
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      })
      ..body = jsonEncode({
        'model': config.model,
        'input': messages.map(_messageToJson).toList(),
        'stream': true,
      });
    final response = await httpClient.send(request);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.stream.drain<void>();
      throw OpenAiLlmException(
        'Streaming request failed',
        statusCode: response.statusCode,
      );
    }

    yield* _parseStream(response.stream);
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
