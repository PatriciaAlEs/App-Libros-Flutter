import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/models/reader_context.dart';
import 'package:reading_tracker/features/coach/domain/services/coach_engine.dart';
import 'package:reading_tracker/features/coach/domain/services/coach_system_prompt_builder.dart';
import 'package:reading_tracker/features/coach/domain/services/context_formatter.dart';
import 'package:reading_tracker/features/reading_sessions/domain/entities/reading_session.dart';

import 'fakes/fake_llm_client.dart';

void main() {
  group('DefaultCoachEngine', () {
    test('implementa CoachEngine', () {
      final engine = _engine(FakeLlmClient('Respuesta'));

      expect(engine, isA<CoachEngine>());
    });

    test('sendMessage devuelve un CoachMessage assistant', () async {
      final engine = _engine(FakeLlmClient('Respuesta'));

      final message = await engine.sendMessage(
        userMessage: 'Como voy?',
        readerContext: _readerContext(),
      );

      expect(message.role, CoachMessageRole.assistant);
    });

    test('sendMessage usa la respuesta devuelta por LlmClient', () async {
      final engine = _engine(FakeLlmClient('Respuesta configurada'));

      final message = await engine.sendMessage(
        userMessage: 'Como voy?',
        readerContext: _readerContext(),
      );

      expect(message.content, 'Respuesta configurada');
    });

    test('sendMessage rechaza mensaje vacio con ArgumentError', () {
      final engine = _engine(FakeLlmClient('Respuesta'));

      expect(
        engine.sendMessage(userMessage: '', readerContext: _readerContext()),
        throwsArgumentError,
      );
    });

    test('sendMessage rechaza mensaje con solo espacios con ArgumentError', () {
      final engine = _engine(FakeLlmClient('Respuesta'));

      expect(
        engine.sendMessage(userMessage: '   ', readerContext: _readerContext()),
        throwsArgumentError,
      );
    });

    test(
      'sendMessage construye exactamente 3 mensajes para el LlmClient',
      () async {
        final client = FakeLlmClient('Respuesta');
        final engine = _engine(client);

        await engine.sendMessage(
          userMessage: 'Como voy?',
          readerContext: _readerContext(),
        );

        expect(client.lastMessages, hasLength(3));
      },
    );

    test('los mensajes se construyen en orden', () async {
      final client = FakeLlmClient('Respuesta');
      final engine = _engine(client);

      await engine.sendMessage(
        userMessage: 'Como voy?',
        readerContext: _readerContext(),
      );

      expect(client.lastMessages?[0].role, CoachMessageRole.system);
      expect(client.lastMessages?[0].content, contains('ReadPp Coach'));
      expect(client.lastMessages?[1].role, CoachMessageRole.system);
      expect(client.lastMessages?[1].content, startsWith('# Contexto'));
      expect(client.lastMessages?[2].role, CoachMessageRole.user);
      expect(client.lastMessages?[2].content, 'Como voy?');
    });

    test(
      'el mensaje de contexto contiene contenido generado por MarkdownContextFormatter',
      () async {
        final client = FakeLlmClient('Respuesta');
        final engine = _engine(client);

        await engine.sendMessage(
          userMessage: 'Como voy?',
          readerContext: _readerContext(),
        );

        final contextMessage = client.lastMessages?[1];

        expect(contextMessage?.content, contains('# Contexto'));
        expect(contextMessage?.content, contains('# Biblioteca'));
        expect(contextMessage?.content, contains('Libro actual'));
        expect(contextMessage?.content, contains('# Actividad'));
      },
    );

    test('el mensaje user conserva el contenido original valido', () async {
      final client = FakeLlmClient('Respuesta');
      final engine = _engine(client);

      await engine.sendMessage(
        userMessage: '  Como voy esta semana?  ',
        readerContext: _readerContext(),
      );

      expect(client.lastMessages?[2].content, '  Como voy esta semana?  ');
    });

    test('no modifica ReaderContext', () async {
      final client = FakeLlmClient('Respuesta');
      final engine = _engine(client);
      final book = _book();
      final session = _session();
      final context = _readerContext(book: book, session: session);

      await engine.sendMessage(
        userMessage: 'Como voy?',
        readerContext: context,
      );

      expect(context.library.allBooks, [book]);
      expect(context.library.currentBooks, [book]);
      expect(context.library.completedBooks, isEmpty);
      expect(context.library.pendingBooks, isEmpty);
      expect(context.library.abandonedBooks, isEmpty);
      expect(context.activity.readingSessions, [session]);
      expect(context.metadata.generatedAt, DateTime(2026, 7, 9, 10, 30));
    });
  });
}

DefaultCoachEngine _engine(FakeLlmClient client) {
  return DefaultCoachEngine(
    contextFormatter: const MarkdownContextFormatter(),
    systemPromptBuilder: const DefaultCoachSystemPromptBuilder(),
    llmClient: client,
  );
}

ReaderContext _readerContext({Book? book, ReadingSession? session}) {
  final currentBook = book ?? _book();
  final readingSession = session ?? _session();

  return ReaderContext(
    metadata: ReaderContextMetadata(generatedAt: DateTime(2026, 7, 9, 10, 30)),
    library: ReaderLibraryContext(
      allBooks: [currentBook],
      currentBooks: [currentBook],
      completedBooks: const [],
      pendingBooks: const [],
      abandonedBooks: const [],
    ),
    activity: ReaderActivityContext(readingSessions: [readingSession]),
  );
}

Book _book() {
  return Book(
    id: 'book-1',
    title: 'Libro actual',
    status: BookStatus.reading,
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 8),
  );
}

ReadingSession _session() {
  return ReadingSession(
    id: 'session-1',
    bookId: 'book-1',
    date: DateTime(2026, 7, 8),
    minutes: 30,
    pagesRead: 12,
    createdAt: DateTime(2026, 7, 8, 20),
  );
}
