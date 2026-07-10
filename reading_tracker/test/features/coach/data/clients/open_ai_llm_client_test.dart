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

    test('streaming conserva request y emite deltas en orden', () async {
      final httpClient = _StreamingClient([
        utf8.encode('\n'),
        utf8.encode(
          'data: {"type":"response.output_text.delta","delta":"Ho"}\n',
        ),
        utf8.encode(
          'data: {"type":"response.output_text.delta","delta":"la\\n"}\n',
        ),
        utf8.encode('data: {"type":"response.completed"}\n'),
        utf8.encode('data: [DONE]\n'),
      ]);
      final client = _client(httpClient);

      final chunks = await client
          .streamCompletion(messages: _messages())
          .toList();
      final body = jsonDecode(httpClient.request.body) as Map<String, dynamic>;

      expect(chunks, ['Ho', 'la\n']);
      expect(body['stream'], isTrue);
      expect(body['model'], 'test-model');
      expect(body['input'], hasLength(3));
      expect(httpClient.request.headers['Authorization'], 'Bearer test-key');
      expect(httpClient.request.headers['Content-Type'], 'application/json');
    });

    test('streaming procesa eventos y UTF-8 divididos entre chunks', () async {
      final payload = utf8.encode(
        'data: {"type":"response.output_text.delta","delta":"¡España 📚!"}\n'
        'data: [DONE]\n',
      );
      final splitInsideEmoji = payload.indexOf(0xF0) + 2;
      final httpClient = _StreamingClient([
        payload.sublist(0, 9),
        payload.sublist(9, splitInsideEmoji),
        payload.sublist(splitInsideEmoji),
      ]);

      final chunks = await _client(
        httpClient,
      ).streamCompletion(messages: _messages()).toList();

      expect(chunks, ['¡España 📚!']);
    });

    test(
      'streaming ignora eventos validos sin texto y marcador final',
      () async {
        final client = _client(
          _StreamingClient([
            utf8.encode(
              'data: {"type":"response.created"}\n'
              'data: {"type":"response.output_text.delta","delta":""}\n'
              'data: [DONE]\n',
            ),
          ]),
        );

        expect(
          await client.streamCompletion(messages: _messages()).toList(),
          isEmpty,
        );
      },
    );

    test('streaming falla ante status no exitoso', () {
      final client = _client(
        _StreamingClient([utf8.encode('Error')], statusCode: 500),
      );

      expect(
        client.streamCompletion(messages: _messages()).toList(),
        throwsA(
          isA<OpenAiLlmException>().having(
            (error) => error.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
    });

    test('streaming falla ante JSON procesable invalido', () {
      final client = _client(_StreamingClient([utf8.encode('data: {\n')]));

      expect(
        client.streamCompletion(messages: _messages()).toList(),
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

class _StreamingClient extends http.BaseClient {
  _StreamingClient(this.byteChunks, {this.statusCode = 200});

  final List<List<int>> byteChunks;
  final int statusCode;
  late http.Request request;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    this.request = request as http.Request;
    return http.StreamedResponse(Stream.fromIterable(byteChunks), statusCode);
  }
}
