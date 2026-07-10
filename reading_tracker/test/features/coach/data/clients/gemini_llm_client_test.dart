import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:reading_tracker/features/coach/data/clients/gemini_llm_client.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';

void main() {
  group('GeminiLlmClient', () {
    test('complete usa endpoint oficial y extrae texto', () async {
      late http.Request request;
      final client = _client(
        MockClient((value) async {
          request = value;
          return http.Response(_responseJson('Respuesta completa'), 200);
        }),
      );

      final result = await client.complete(messages: _messages());

      expect(result, 'Respuesta completa');
      expect(
        request.url.toString(),
        'https://generativelanguage.googleapis.com/v1beta/'
        'models/gemini-test:generateContent',
      );
      expect(request.headers['x-goog-api-key'], 'gemini-test-key');
    });

    test(
      'mapea system, user y assistant sin duplicar el ultimo user',
      () async {
        late Map<String, dynamic> body;
        final client = _client(
          MockClient((request) async {
            body = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(_responseJson('Ok'), 200);
          }),
        );

        await client.complete(messages: _messages());

        expect(body['system_instruction'], {
          'parts': [
            {'text': 'Sistema\n\nContexto'},
          ],
        });
        expect(body['contents'], [
          {
            'role': 'user',
            'parts': [
              {'text': 'Pregunta anterior'},
            ],
          },
          {
            'role': 'model',
            'parts': [
              {'text': 'Respuesta anterior'},
            ],
          },
          {
            'role': 'user',
            'parts': [
              {'text': 'Pregunta actual'},
            ],
          },
        ]);
        final contents = body['contents'] as List<dynamic>;
        expect(
          contents.where(
            (item) => jsonEncode(item).contains('Pregunta actual'),
          ),
          hasLength(1),
        );
      },
    );

    test('streaming emite texto incremental', () async {
      final client = _client(
        _StreamingClient([
          utf8.encode('data: ${_responseJson('Ho')}\n'),
          utf8.encode('data: ${_responseJson('la')}\n'),
        ]),
      );

      expect(await client.streamCompletion(messages: _messages()).toList(), [
        'Ho',
        'la',
      ]);
    });

    test('streaming soporta UTF-8 y JSON divididos entre chunks', () async {
      final payload = utf8.encode('data: ${_responseJson('¡España 📚!')}\n');
      final emoji = payload.indexOf(0xF0);
      final client = _client(
        _StreamingClient([
          payload.sublist(0, 8),
          payload.sublist(8, emoji + 2),
          payload.sublist(emoji + 2),
        ]),
      );

      expect(await client.streamCompletion(messages: _messages()).toList(), [
        '¡España 📚!',
      ]);
    });

    test('streaming soporta varios eventos en un chunk', () async {
      final client = _client(
        _StreamingClient([
          utf8.encode(
            'data: ${_responseJson('uno')}\n'
            'data: ${_responseJson('dos')}\n',
          ),
        ]),
      );

      expect(await client.streamCompletion(messages: _messages()).toList(), [
        'uno',
        'dos',
      ]);
    });

    test('complete devuelve vacio cuando no hay texto', () async {
      final client = _client(
        MockClient((_) async => http.Response('{"candidates":[]}', 200)),
      );

      expect(await client.complete(messages: _messages()), '');
    });

    test('streaming ignora respuestas sin texto y finaliza normalmente', () {
      final client = _client(
        _StreamingClient([
          utf8.encode('data: {"candidates":[]}\n'),
          utf8.encode('data: [DONE]\n'),
        ]),
      );

      expect(client.streamCompletion(messages: _messages()), emitsDone);
    });

    test('propaga status y error HTTP', () {
      final client = _client(
        _StreamingClient([
          utf8.encode('{"error":{"message":"invalid model"}}'),
        ], statusCode: 400),
      );

      expect(
        client.streamCompletion(messages: _messages()).toList(),
        throwsA(
          isA<GeminiLlmException>()
              .having((error) => error.statusCode, 'statusCode', 400)
              .having(
                (error) => error.message,
                'message',
                contains('invalid model'),
              ),
        ),
      );
    });

    test('detecta error JSON devuelto con status exitoso', () {
      final client = _client(
        _StreamingClient([
          utf8.encode('data: {"error":{"code":400,"message":"bad request"}}\n'),
        ]),
      );

      expect(
        client.streamCompletion(messages: _messages()).toList(),
        throwsA(
          isA<GeminiLlmException>().having(
            (error) => error.message,
            'message',
            contains('bad request'),
          ),
        ),
      );
    });

    test('conserva contenido parcial antes de un JSON invalido', () async {
      final client = _client(
        _StreamingClient([
          utf8.encode('data: ${_responseJson('Parcial')}\n'),
          utf8.encode('data: {\n'),
        ]),
      );

      await expectLater(
        client.streamCompletion(messages: _messages()),
        emitsInOrder(['Parcial', emitsError(isA<GeminiLlmException>())]),
      );
    });

    test('cancelar suscripcion cancela el stream HTTP', () async {
      final httpClient = _CancelableStreamingClient();
      final subscription = _client(
        httpClient,
      ).streamCompletion(messages: _messages()).listen((_) {});
      await httpClient.started.future;

      await subscription.cancel();

      expect(httpClient.wasCancelled, isTrue);
    });

    test('valida clave y modelo ausentes', () {
      expect(
        () => GeminiConfig(
          apiKey: 'missing-gemini-api-key',
          model: 'gemini-test',
        ),
        throwsA(isA<GeminiConfigurationException>()),
      );
      expect(
        () => GeminiConfig(apiKey: 'key', model: ''),
        throwsA(isA<GeminiConfigurationException>()),
      );
    });

    test('rechaza el endpoint OpenAI-compatible como Gemini base URL', () {
      expect(
        () => GeminiConfig(
          apiKey: 'key',
          model: 'gemini-test',
          baseUri: Uri.parse(
            'https://generativelanguage.googleapis.com/'
            'v1beta/openai/chat/completions',
          ),
        ),
        throwsA(
          isA<GeminiConfigurationException>().having(
            (error) => error.message,
            'message',
            contains('must be the API root'),
          ),
        ),
      );
    });
  });
}

GeminiLlmClient _client(http.Client httpClient) => GeminiLlmClient(
  config: GeminiConfig(apiKey: 'gemini-test-key', model: 'gemini-test'),
  httpClient: httpClient,
);

List<CoachMessage> _messages() => [
  CoachMessage.system('Sistema'),
  CoachMessage.system('Contexto'),
  CoachMessage.user('Pregunta anterior'),
  CoachMessage.assistant('Respuesta anterior'),
  CoachMessage.assistant(''),
  CoachMessage.user('Pregunta actual'),
];

String _responseJson(String text) => jsonEncode({
  'candidates': [
    {
      'content': {
        'role': 'model',
        'parts': [
          {'text': text},
        ],
      },
    },
  ],
});

class _StreamingClient extends http.BaseClient {
  _StreamingClient(this.chunks, {this.statusCode = 200});

  final List<List<int>> chunks;
  final int statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async =>
      http.StreamedResponse(Stream.fromIterable(chunks), statusCode);
}

class _CancelableStreamingClient extends http.BaseClient {
  final started = Completer<void>();
  bool wasCancelled = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    late StreamController<List<int>> controller;
    controller = StreamController<List<int>>(
      onListen: () {
        started.complete();
        controller.add(utf8.encode('data: ${_responseJson('Inicio')}\n'));
      },
      onCancel: () => wasCancelled = true,
    );
    return http.StreamedResponse(controller.stream, 200);
  }
}
