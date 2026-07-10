import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/data/providers/coach_repository_provider.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/models/reader_context.dart';
import 'package:reading_tracker/features/coach/domain/repositories/coach_repository.dart';
import 'package:reading_tracker/features/coach/presentation/controllers/coach_controller.dart';

void main() {
  group('CoachController', () {
    test('estado inicial correcto', () {
      final container = _container(_CompletingCoachRepository('Respuesta'));
      addTearDown(container.dispose);

      final state = container.read(coachControllerProvider);

      expect(state.messages, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('envio satisfactorio actualiza mensajes y loading', () async {
      final repository = _PendingCoachRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final controller = container.read(coachControllerProvider.notifier);

      final future = controller.sendMessage(
        userMessage: 'Como voy?',
        readerContext: _readerContext(),
      );

      var state = container.read(coachControllerProvider);
      expect(state.isLoading, isTrue);
      expect(state.messages, hasLength(1));
      expect(state.messages.single.role, CoachMessageRole.user);
      expect(state.messages.single.content, 'Como voy?');

      repository.complete('Vas bien.');
      await future;

      state = container.read(coachControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.messages, hasLength(2));
      expect(state.messages[0].role, CoachMessageRole.user);
      expect(state.messages[1].role, CoachMessageRole.assistant);
      expect(state.messages[1].content, 'Vas bien.');
    });

    test(
      'envio usa repository con datos de dominio y sin construir prompt',
      () async {
        final repository = _CompletingCoachRepository('Respuesta');
        final container = _container(repository);
        addTearDown(container.dispose);

        await container
            .read(coachControllerProvider.notifier)
            .sendMessage(
              userMessage: '  Como voy?  ',
              readerContext: _readerContext(),
            );

        expect(repository.lastUserMessage, '  Como voy?  ');
        expect(repository.lastConversation, isEmpty);
        expect(repository.lastReaderContext, isNotNull);
      },
    );

    test('error desactiva loading y no anade respuesta falsa', () async {
      final repository = _FailingCoachRepository();
      final container = _container(repository);
      addTearDown(container.dispose);

      await container
          .read(coachControllerProvider.notifier)
          .sendMessage(
            userMessage: 'Como voy?',
            readerContext: _readerContext(),
          );

      final state = container.read(coachControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotEmpty);
      expect(state.messages, hasLength(1));
      expect(state.messages.single.role, CoachMessageRole.user);
    });

    test('respuesta vacia se representa como error', () async {
      final repository = _CompletingCoachRepository('   ');
      final container = _container(repository);
      addTearDown(container.dispose);

      await container
          .read(coachControllerProvider.notifier)
          .sendMessage(
            userMessage: 'Como voy?',
            readerContext: _readerContext(),
          );

      final state = container.read(coachControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotEmpty);
      expect(state.messages, hasLength(1));
      expect(state.messages.single.role, CoachMessageRole.user);
    });
  });
}

ProviderContainer _container(CoachRepository repository) {
  return ProviderContainer(
    overrides: [coachRepositoryProvider.overrideWithValue(repository)],
  );
}

ReaderContext _readerContext() {
  return ReaderContext(
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
}

class _CompletingCoachRepository implements CoachRepository {
  _CompletingCoachRepository(this.response);

  final String response;
  String? lastUserMessage;
  List<CoachMessage>? lastConversation;
  ReaderContext? lastReaderContext;

  @override
  Future<String> generateReply({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
  }) async {
    lastUserMessage = userMessage;
    lastConversation = List.unmodifiable(conversation);
    lastReaderContext = readerContext;
    return response;
  }
}

class _PendingCoachRepository implements CoachRepository {
  final Completer<String> _completer = Completer<String>();
  @override
  Future<String> generateReply({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
  }) {
    return _completer.future;
  }

  void complete(String response) {
    _completer.complete(response);
  }
}

class _FailingCoachRepository implements CoachRepository {
  @override
  Future<String> generateReply({
    required String userMessage,
    required List<CoachMessage> conversation,
    required ReaderContext readerContext,
  }) async {
    throw StateError('failure');
  }
}
