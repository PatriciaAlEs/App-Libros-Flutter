import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/data/providers/coach_repository_provider.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_conversation.dart';
import 'package:reading_tracker/features/coach/domain/models/reader_context.dart';
import 'package:reading_tracker/features/coach/domain/repositories/coach_repository.dart';
import 'package:reading_tracker/features/coach/domain/repositories/coach_conversation_repository.dart';
import 'package:reading_tracker/features/coach/presentation/controllers/coach_controller.dart';

void main() {
  group('CoachController streaming', () {
    test('crea un provisional y lo actualiza acumulando chunks', () async {
      final repository = _ControlledRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller = container.read(coachControllerProvider.notifier);

      final future = controller.sendMessage(
        userMessage: 'Como voy?',
        readerContext: _readerContext(),
      );

      var state = container.read(coachControllerProvider);
      expect(state.isLoading, isTrue);
      expect(state.generationStatus, CoachGenerationStatus.waitingFirstChunk);
      expect(state.messages, hasLength(2));
      expect(state.messages[0].role, CoachMessageRole.user);
      expect(state.messages[1].role, CoachMessageRole.assistant);
      expect(state.messages[1].content, isEmpty);

      repository.add('Vas ');
      await _flush();
      state = container.read(coachControllerProvider);
      expect(state.messages, hasLength(2));
      expect(state.messages[1].content, 'Vas ');
      expect(state.generationStatus, CoachGenerationStatus.streaming);

      repository.add('bien.');
      await _flush();
      expect(
        container.read(coachControllerProvider).messages[1].content,
        'Vas bien.',
      );

      await repository.close();
      await future;
      state = container.read(coachControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.messages, hasLength(2));
      expect(state.generationStatus, CoachGenerationStatus.completed);
    });

    test('pasa historial anterior y mensaje actual por separado', () async {
      final repository = _ImmediateRepository(['Respuesta']);
      final container = _container(repository);
      addTearDown(container.dispose);

      await container
          .read(coachControllerProvider.notifier)
          .sendMessage(userMessage: 'Actual', readerContext: _readerContext());

      expect(repository.lastUserMessage, 'Actual');
      expect(repository.lastConversation, isEmpty);
      expect(repository.lastIncludesCurrentMessage, isFalse);
    });

    test('error antes del primer chunk elimina el provisional', () async {
      final container = _container(_ErrorRepository());
      addTearDown(container.dispose);

      await container
          .read(coachControllerProvider.notifier)
          .sendMessage(
            userMessage: 'Pregunta',
            readerContext: _readerContext(),
          );

      final state = container.read(coachControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotEmpty);
      expect(state.messages, hasLength(1));
      expect(state.messages.single.role, CoachMessageRole.user);
    });

    test('error posterior conserva el contenido parcial', () async {
      final repository = _ControlledRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final future = container
          .read(coachControllerProvider.notifier)
          .sendMessage(
            userMessage: 'Pregunta',
            readerContext: _readerContext(),
          );

      repository.add('Parcial');
      await _flush();
      repository.addError(StateError('failure'));
      await future;

      final state = container.read(coachControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotEmpty);
      expect(state.messages, hasLength(2));
      expect(state.messages.last.content, 'Parcial');
    });

    test('stream vacio no deja un mensaje assistant vacio', () async {
      final container = _container(_ImmediateRepository(const []));
      addTearDown(container.dispose);

      await container
          .read(coachControllerProvider.notifier)
          .sendMessage(
            userMessage: 'Pregunta',
            readerContext: _readerContext(),
          );

      final state = container.read(coachControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotEmpty);
      expect(state.messages, hasLength(1));
    });

    test('ignora un segundo envio durante una generacion activa', () async {
      final repository = _ControlledRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller = container.read(coachControllerProvider.notifier);
      final first = controller.sendMessage(
        userMessage: 'Primero',
        readerContext: _readerContext(),
      );
      await _flush();

      await controller.sendMessage(
        userMessage: 'Segundo',
        readerContext: _readerContext(),
      );

      expect(repository.callCount, 1);
      expect(
        container.read(coachControllerProvider).messages.first.content,
        'Primero',
      );
      await repository.close();
      await first;
    });

    test('cancelar elimina provisional vacio y permite otro envio', () async {
      final repository = _ControlledRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller = container.read(coachControllerProvider.notifier);
      final future = controller.sendMessage(
        userMessage: 'Pregunta',
        readerContext: _readerContext(),
      );

      await controller.cancelGeneration();
      await future;

      final state = container.read(coachControllerProvider);
      expect(state.generationStatus, CoachGenerationStatus.cancelled);
      expect(state.messages, hasLength(1));
      expect(state.errorMessage, isNull);
    });

    test('cancelar conserva parcial e ignora fragmentos posteriores', () async {
      final repository = _ControlledRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller = container.read(coachControllerProvider.notifier);
      final future = controller.sendMessage(
        userMessage: 'Pregunta',
        readerContext: _readerContext(),
      );
      repository.add('Parcial');
      await _flush();

      await controller.cancelGeneration();
      repository.add('Obsoleto');
      await _flush();
      await future;

      expect(
        container.read(coachControllerProvider).messages.last.content,
        'Parcial',
      );
    });

    test('regenera sin duplicar el mensaje user', () async {
      final repository = _QueuedRepository([
        Stream.value('Primera'),
        Stream.fromIterable(['Nueva ', 'respuesta']),
      ]);
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller = container.read(coachControllerProvider.notifier);
      await controller.sendMessage(
        userMessage: 'Pregunta',
        readerContext: _readerContext(),
      );

      await controller.regenerateLastResponse();

      final state = container.read(coachControllerProvider);
      expect(state.messages, hasLength(2));
      expect(
        state.messages.where(
          (message) => message.role == CoachMessageRole.user,
        ),
        hasLength(1),
      );
      expect(state.messages.last.content, 'Nueva respuesta');
      expect(repository.conversations.last, isEmpty);
    });

    test('reintenta un error sin duplicar el mensaje user', () async {
      final repository = _QueuedRepository([
        Stream<String>.error(StateError('failure')),
        Stream.value('Recuperada'),
      ]);
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller = container.read(coachControllerProvider.notifier);
      await controller.sendMessage(
        userMessage: 'Pregunta',
        readerContext: _readerContext(),
      );
      expect(container.read(coachControllerProvider).canRetry, isTrue);

      await controller.retryLastResponse();

      final state = container.read(coachControllerProvider);
      expect(state.messages, hasLength(2));
      expect(state.messages.last.content, 'Recuperada');
      expect(state.errorMessage, isNull);
    });
  });
}

Future<void> _flush() => Future<void>.delayed(Duration.zero);

ProviderContainer _container(CoachRepository repository) => ProviderContainer(
  overrides: [
    coachRepositoryProvider.overrideWithValue(repository),
    coachConversationRepositoryProvider.overrideWithValue(
      _TestConversationRepository(),
    ),
  ],
);

class _TestConversationRepository implements CoachConversationRepository {
  final List<CoachConversation> conversations = [];
  final List<CoachMessage> messages = [];
  @override
  Future<CoachConversation> createFromFirstMessage(String message) =>
      throw UnimplementedError();
  @override
  Future<void> deleteConversation(String id) async {}
  @override
  Future<void> deleteMessage(String id) async =>
      messages.removeWhere((item) => item.id == id);
  @override
  Future<void> deleteMessagesAfter(String id, int sequence) async {}
  @override
  Future<CoachConversation?> getConversation(String id) async => null;
  @override
  Future<List<CoachConversation>> getConversations() async => const [];
  @override
  Future<List<CoachMessage>> getMessages(String id) async => const [];
  @override
  Future<void> saveConversation(CoachConversation value) async {
    conversations.add(value);
  }

  @override
  Future<void> saveMessage(CoachMessage value) async {
    messages.removeWhere((item) => item.id == value.id);
    messages.add(value);
  }

  @override
  Stream<List<CoachConversation>> watchConversations() => const Stream.empty();
}

class _ControlledRepository implements CoachRepository {
  final StreamController<String> _controller = StreamController<String>();
  int callCount = 0;

  @override
  Stream<String> streamReply({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
    String? conversationSummary,
  }) {
    callCount++;
    return _controller.stream;
  }

  void add(String chunk) => _controller.add(chunk);
  void addError(Object error) => _controller.addError(error);
  Future<void> close() => _controller.close();
}

class _ImmediateRepository implements CoachRepository {
  _ImmediateRepository(this.chunks);
  final List<String> chunks;
  String? lastUserMessage;
  List<CoachMessage>? lastConversation;
  bool? lastIncludesCurrentMessage;

  @override
  Stream<String> streamReply({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
    String? conversationSummary,
  }) {
    lastUserMessage = userMessage;
    lastConversation = List.unmodifiable(conversation);
    lastIncludesCurrentMessage = conversationIncludesCurrentMessage;
    return Stream.fromIterable(chunks);
  }
}

class _ErrorRepository implements CoachRepository {
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

class _QueuedRepository implements CoachRepository {
  _QueuedRepository(this.streams);
  final List<Stream<String>> streams;
  final List<List<CoachMessage>> conversations = [];
  int _index = 0;

  @override
  Stream<String> streamReply({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
    bool conversationIncludesCurrentMessage = false,
    String? conversationSummary,
  }) {
    conversations.add(List.unmodifiable(conversation));
    return streams[_index++];
  }
}

ReaderContext _readerContext() => ReaderContext(
  metadata: ReaderContextMetadata(generatedAt: DateTime(2026, 7, 10, 10)),
  library: ReaderLibraryContext(
    allBooks: const [],
    currentBooks: const [],
    completedBooks: const [],
    pendingBooks: const [],
    abandonedBooks: const [],
  ),
  activity: ReaderActivityContext(readingSessions: const []),
);
