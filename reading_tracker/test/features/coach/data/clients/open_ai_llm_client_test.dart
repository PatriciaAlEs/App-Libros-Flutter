import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reading_tracker/features/coach/data/clients/open_ai_llm_client.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';

void main() {
  group('OpenAiLlmClient', () {
    test('construye request con endpoint correcto', () async {
      late http.Request capturedRequest;
      final client = _client(
        MockClient((request) async {
          capturedRequest = request;
          return _outputTextResponse('Respuesta');
        }),
      );

      await client.complete(messages: _messages());

      expect(
        capturedRequest.url,
        Uri.parse('https://api.openai.com/v1/responses'),
      );
    });

    test('envia Authorization Bearer', () async {
      late http.Request capturedRequest;
      final client = _client(
        MockClient((request) async {
          capturedRequest = request;
          return _outputTextResponse('Respuesta');
        }),
      );

      await client.complete(messages: _messages());

      expect(capturedRequest.headers['Authorization'], 'Bearer test-key');
    });

    test('envia Content-Type application/json', () async {
      late http.Request capturedRequest;
      final client = _client(
        MockClient((request) async {
          capturedRequest = request;
          return _outputTextResponse('Respuesta');
        }),
      );

      await client.complete(messages: _messages());

      expect(capturedRequest.headers['Content-Type'], 'application/json');
    });

    test('serializa model', () async {
      late Map<String, dynamic> body;
      final client = _client(
        MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return _outputTextResponse('Respuesta');
        }),
      );

      await client.complete(messages: _messages());

      expect(body['model'], 'test-model');
    });

    test('serializa mensajes system user assistant', () async {
      late Map<String, dynamic> body;
      final client = _client(
        MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return _outputTextResponse('Respuesta');
        }),
      );

      await client.complete(messages: _messages());

      expect(body['input'], [
        {'role': 'system', 'content': 'Instrucciones'},
        {'role': 'user', 'content': 'Pregunta'},
        {'role': 'assistant', 'content': 'Respuesta previa'},
      ]);
    });

    test('devuelve output_text cuando existe', () async {
      final client = _client(
        MockClient((request) async => _outputTextResponse('Texto directo')),
      );

      final response = await client.complete(messages: _messages());

      expect(response, 'Texto directo');
    });

    test(
      'devuelve texto desde output content text si no existe output_text',
      () async {
        final client = _client(
          MockClient((request) async {
            return http.Response(
              jsonEncode({
                'output': [
                  {
                    'content': [
                      {'text': 'Texto anidado'},
                    ],
                  },
                ],
              }),
              200,
            );
          }),
        );

        final response = await client.complete(messages: _messages());

        expect(response, 'Texto anidado');
      },
    );

    test('rechaza lista vacia con ArgumentError', () {
      final client = _client(
        MockClient((request) async => _outputTextResponse('Respuesta')),
      );

      expect(client.complete(messages: const []), throwsArgumentError);
    });

    test('lanza OpenAiLlmException en status no 2xx', () {
      final client = _client(
        MockClient((request) async => http.Response('Error', 500)),
      );

      expect(
        client.complete(messages: _messages()),
        throwsA(
          isA<OpenAiLlmException>().having(
            (error) => error.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('lanza OpenAiLlmException en JSON invalido', () {
      final client = _client(
        MockClient((request) async => http.Response('{', 200)),
      );

      expect(
        client.complete(messages: _messages()),
        throwsA(isA<OpenAiLlmException>()),
      );
    });

    test('lanza OpenAiLlmException cuando no hay texto', () {
      final client = _client(
        MockClient(
          (request) async => http.Response(jsonEncode({'output': []}), 200),
        ),
      );

      expect(
        client.complete(messages: _messages()),
        throwsA(isA<OpenAiLlmException>()),
      );
    });

    test('OpenAiConfig rechaza apiKey vacia', () {
      expect(
        () => OpenAiConfig(apiKey: '', model: 'test-model'),
        throwsArgumentError,
      );
    });

    test('OpenAiConfig rechaza model vacio', () {
      expect(
        () => OpenAiConfig(apiKey: 'test-key', model: '   '),
        throwsArgumentError,
      );
    });
  });
}

OpenAiLlmClient _client(http.Client httpClient) {
  return OpenAiLlmClient(
    config: OpenAiConfig(apiKey: 'test-key', model: 'test-model'),
    httpClient: httpClient,
  );
}

List<CoachMessage> _messages() {
  return [
    CoachMessage.system('Instrucciones'),
    CoachMessage.user('Pregunta'),
    CoachMessage.assistant('Respuesta previa'),
  ];
}

http.Response _outputTextResponse(String text) {
  return http.Response(jsonEncode({'output_text': text}), 200);
}
