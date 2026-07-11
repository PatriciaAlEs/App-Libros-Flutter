import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/data/providers/coach_repository_provider.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_conversation.dart';
import 'package:reading_tracker/features/coach/domain/models/reader_context.dart';
import 'package:reading_tracker/features/coach/domain/providers/reader_context_provider.dart';
import 'package:reading_tracker/features/coach/domain/repositories/coach_repository.dart';
import 'package:reading_tracker/features/coach/domain/repositories/coach_conversation_repository.dart';
import 'package:reading_tracker/features/coach/presentation/controllers/coach_controller.dart';
import 'package:reading_tracker/features/coach/presentation/screens/coach_screen.dart';

void main() {
  group('CoachScreen', () {
    testWidgets('muestra estado vacio y sugerencias', (tester) async {
      final repository = _WidgetRepository();
      await tester.pumpWidget(_app(repository));

      expect(find.text('¿Sobre qué quieres leer hoy?'), findsOneWidget);
      expect(find.text('Resume mi progreso de lectura'), findsOneWidget);
      expect(find.text('Recomiéndame un libro'), findsOneWidget);
    });

    testWidgets('sugerencia usa el flujo normal y muestra Escribiendo', (
      tester,
    ) async {
      final repository = _WidgetRepository();
      await tester.pumpWidget(_app(repository));

      await tester.tap(find.text('Resume mi progreso de lectura'));
      await _pumpAsyncWork(tester);
      await tester.pump(const Duration(milliseconds: 250));

      expect(repository.lastUserMessage, 'Resume mi progreso de lectura');
      expect(find.text('Escribiendo…'), findsOneWidget);
      expect(find.bySemanticsLabel('Detener respuesta'), findsOneWidget);
      final stopButton = tester.widget<IconButton>(
        find.byKey(const ValueKey('stop')),
      );
      stopButton.onPressed!();
      await _pumpAsyncWork(tester);
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('muestra cursor con parcial y lo oculta al completar', (
      tester,
    ) async {
      final repository = _WidgetRepository();
      await tester.pumpWidget(_app(repository));
      await tester.tap(find.text('Resume mi progreso de lectura'));
      await _pumpAsyncWork(tester);

      repository.add('**Hola**');
      await _pumpAsyncWork(tester);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Escribiendo…'), findsNothing);
      expect(find.byKey(const ValueKey('streaming-cursor')), findsOneWidget);

      await repository.close();
      await _pumpAsyncWork(tester);
      expect(find.byKey(const ValueKey('streaming-cursor')), findsNothing);
      expect(find.text('Regenerar'), findsOneWidget);
    });

    testWidgets('Stop cancela y elimina el provisional vacio', (tester) async {
      final repository = _WidgetRepository();
      await tester.pumpWidget(_app(repository));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CoachScreen)),
      );
      await tester.tap(find.text('Resume mi progreso de lectura'));
      await _pumpAsyncWork(tester);
      await tester.pump(const Duration(milliseconds: 250));

      final stopButton = tester.widget<IconButton>(
        find.byKey(const ValueKey('stop')),
      );
      stopButton.onPressed!();
      await _pumpAsyncWork(tester);
      await tester.pump(const Duration(milliseconds: 250));

      final state = container.read(coachControllerProvider);
      expect(state.generationStatus, CoachGenerationStatus.cancelled);
      expect(state.messages, hasLength(1));
      expect(state.messages.single.role, CoachMessageRole.user);
      expect(find.byKey(const ValueKey('send')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('transicion send stop no crea keys duplicadas', (tester) async {
      final repository = _WidgetRepository();
      await tester.pumpWidget(_app(repository));

      await tester.tap(find.text('Resume mi progreso de lectura'));
      await _pumpAsyncWork(tester);
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const ValueKey('composer-stop-state')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await repository.close();
      await _pumpAsyncWork(tester);
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byKey(const ValueKey('composer-send-state')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('desmonta la pantalla con una respuesta activa', (
      tester,
    ) async {
      final repository = _WidgetRepository();
      await tester.pumpWidget(_app(repository));
      await tester.tap(find.text('Resume mi progreso de lectura'));
      await _pumpAsyncWork(tester);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();

      expect(repository.hasListener, isFalse);
      repository.add('fragmento tardio');
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('compositor cabe en una vista web estrecha', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(_WidgetRepository()));
      await tester.pump();

      expect(tester.takeException(), isNull);
      final composer = tester.getRect(find.byType(TextField));
      expect(composer.left, greaterThanOrEqualTo(0));
      expect(composer.right, lessThanOrEqualTo(320));
    });

    testWidgets('muestra Reintentar despues de un error', (tester) async {
      await tester.pumpWidget(_app(_FailingWidgetRepository()));

      await tester.tap(find.text('Resume mi progreso de lectura'));
      await _pumpAsyncWork(tester);

      expect(find.bySemanticsLabel('Reintentar respuesta'), findsOneWidget);
      expect(
        find.text('No se ha podido generar la respuesta. Inténtalo de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'muestra Volver al final cuando el usuario se desplaza arriba',
      (tester) async {
        final repository = _RepeatingWidgetRepository();
        final controller = _PreloadedCoachController(repository);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coachControllerProvider.overrideWith((ref) => controller),
              readerContextProvider.overrideWith(
                (ref) async => _readerContext(),
              ),
            ],
            child: const MaterialApp(home: CoachScreen()),
          ),
        );
        await tester.pump();

        final list = find.byType(ListView).first;
        final scrollable = tester.state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)).first,
        );
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pump();
        scrollable.position.jumpTo(
          (scrollable.position.maxScrollExtent - 200)
              .clamp(
                scrollable.position.minScrollExtent,
                scrollable.position.maxScrollExtent,
              )
              .toDouble(),
        );
        await tester.pump();

        expect(find.byKey(const ValueKey('scroll-bottom')), findsOneWidget);
      },
    );
  });
}

Future<void> _pumpAsyncWork(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(Duration.zero);
  await tester.pump(const Duration(milliseconds: 1));
}

Widget _app(CoachRepository repository) => ProviderScope(
  overrides: [
    coachRepositoryProvider.overrideWithValue(repository),
    coachConversationRepositoryProvider.overrideWithValue(
      _MemoryConversationRepository(),
    ),
    readerContextProvider.overrideWith((ref) async => _readerContext()),
  ],
  child: const MaterialApp(home: CoachScreen()),
);

class _WidgetRepository implements CoachRepository {
  final StreamController<String> _controller = StreamController<String>();
  String? lastUserMessage;

  bool get hasListener => _controller.hasListener;

  @override
  Stream<String> streamReply({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
    String? conversationSummary,
  }) {
    lastUserMessage = userMessage;
    return _controller.stream;
  }

  void add(String value) => _controller.add(value);
  Future<void> close() => _controller.close();
}

class _FailingWidgetRepository implements CoachRepository {
  @override
  Stream<String> streamReply({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
    String? conversationSummary,
  }) {
    return Stream<String>.error(StateError('failure'));
  }
}

class _RepeatingWidgetRepository implements CoachRepository {
  @override
  Stream<String> streamReply({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
    String? conversationSummary,
  }) {
    return Stream.value(
      'Respuesta extensa para comprobar el desplazamiento inteligente de la conversación. '
      'Incluye varias frases y mantiene suficiente altura visual en la lista.',
    );
  }
}

class _PreloadedCoachController extends CoachController {
  _PreloadedCoachController(CoachRepository repository)
    : super(repository: repository) {
    state = CoachControllerState(
      generationStatus: CoachGenerationStatus.completed,
      messages: [
        for (var index = 0; index < 8; index++) ...[
          CoachMessage.user('Pregunta $index con contenido suficiente'),
          CoachMessage.assistant(
            'Respuesta extensa número $index para comprobar el desplazamiento '
            'inteligente de la conversación. Incluye varias frases y mantiene '
            'suficiente altura visual en la lista.',
          ),
        ],
      ],
    );
  }
}

class _MemoryConversationRepository implements CoachConversationRepository {
  final List<CoachConversation> conversations = [];
  final List<CoachMessage> messages = [];

  @override
  Future<CoachConversation> createFromFirstMessage(String message) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteConversation(String id) async {
    conversations.removeWhere((item) => item.id == id);
    messages.removeWhere((item) => item.conversationId == id);
  }

  @override
  Future<void> deleteMessage(String id) async =>
      messages.removeWhere((item) => item.id == id);
  @override
  Future<void> deleteMessagesAfter(String id, int sequence) async =>
      messages.removeWhere(
        (item) => item.conversationId == id && item.sequence > sequence,
      );
  @override
  Future<CoachConversation?> getConversation(String id) async {
    for (final item in conversations) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<List<CoachConversation>> getConversations() async =>
      List.unmodifiable(conversations);
  @override
  Future<List<CoachMessage>> getMessages(String id) async => messages
      .where((item) => item.conversationId == id)
      .toList(growable: false);
  @override
  Future<void> saveConversation(CoachConversation value) async {
    conversations.removeWhere((item) => item.id == value.id);
    conversations.add(value);
  }

  @override
  Future<void> saveMessage(CoachMessage value) async {
    messages.removeWhere((item) => item.id == value.id);
    messages.add(value);
  }

  @override
  Stream<List<CoachConversation>> watchConversations() =>
      Stream.value(List.unmodifiable(conversations));
}

ReaderContext _readerContext() => ReaderContext(
  metadata: ReaderContextMetadata(generatedAt: DateTime(2026, 7, 10)),
  library: ReaderLibraryContext(
    allBooks: const [],
    currentBooks: const [],
    completedBooks: const [],
    pendingBooks: const [],
    abandonedBooks: const [],
  ),
  activity: ReaderActivityContext(readingSessions: const []),
);
