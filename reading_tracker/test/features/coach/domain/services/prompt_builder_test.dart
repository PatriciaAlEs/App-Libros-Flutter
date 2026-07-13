import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/models/reader_context.dart';
import 'package:reading_tracker/features/coach/domain/services/coach_system_prompt_builder.dart';
import 'package:reading_tracker/features/coach/domain/services/context_formatter.dart';
import 'package:reading_tracker/features/coach/domain/services/prompt_builder.dart';

void main() {
  group('CoachPromptBuilder', () {
    const builder = CoachPromptBuilder(
      systemPromptBuilder: DefaultCoachSystemPromptBuilder(),
      contextFormatter: MarkdownContextFormatter(),
    );

    test(
      'compone instrucciones, contexto, historial y mensaje actual en orden',
      () {
        final result = builder.build(
          userMessage: 'Actual',
          conversation: [
            CoachMessage.user('Uno'),
            CoachMessage.assistant('Dos'),
          ],
          readerContext: _readerContext(),
        );

        expect(result.map((message) => message.role), [
          CoachMessageRole.system,
          CoachMessageRole.system,
          CoachMessageRole.user,
          CoachMessageRole.assistant,
          CoachMessageRole.user,
        ]);
        expect(result[0].content, contains('ReadPp Coach'));
        expect(result[1].content, startsWith('# Contexto'));
        expect(result.map((message) => message.content).skip(2), [
          'Uno',
          'Dos',
          'Actual',
        ]);
      },
    );

    test('maneja historial vacio y conserva espacios del mensaje actual', () {
      final result = builder.build(
        userMessage: '  Actual  ',
        conversation: const [],
        readerContext: _readerContext(),
      );

      expect(result, hasLength(3));
      expect(result.last.content, '  Actual  ');
    });

    test('elimina mensajes system del historial de dominio', () {
      final result = builder.build(
        userMessage: 'Actual',
        conversation: [
          CoachMessage.system('Temporal'),
          CoachMessage.user('Anterior'),
        ],
        readerContext: _readerContext(),
      );

      expect(result.where((message) => message.content == 'Temporal'), isEmpty);
      expect(
        result.where((message) => message.content == 'Actual'),
        hasLength(1),
      );
    });

    test('no duplica el mensaje actual si el historial ya lo incluye', () {
      final result = builder.build(
        userMessage: 'Actual',
        conversation: [
          CoachMessage.user('Anterior'),
          CoachMessage.user('Actual'),
        ],
        readerContext: _readerContext(),
        conversationIncludesCurrentMessage: true,
      );

      expect(
        result.where((message) => message.content == 'Actual'),
        hasLength(1),
      );
      expect(result.map((message) => message.content).skip(2), [
        'Anterior',
        'Actual',
      ]);
    });

    test(
      'conserva una repeticion intencionada cuando el contrato excluye el actual',
      () {
        final result = builder.build(
          userMessage: 'Repite',
          conversation: [
            CoachMessage.user('Repite'),
            CoachMessage.assistant('Respuesta'),
          ],
          readerContext: _readerContext(),
        );

        expect(
          result.where((message) => message.content == 'Repite'),
          hasLength(2),
        );
      },
    );

    test(
      'el limite prioriza historial reciente sin eliminar system ni actual',
      () {
        const limitedBuilder = CoachPromptBuilder(
          systemPromptBuilder: DefaultCoachSystemPromptBuilder(),
          contextFormatter: MarkdownContextFormatter(),
          maxConversationMessages: 2,
        );
        final result = limitedBuilder.build(
          userMessage: 'Actual',
          conversation: [
            CoachMessage.user('Antiguo'),
            CoachMessage.assistant('Reciente 1'),
            CoachMessage.user('Reciente 2'),
          ],
          readerContext: _readerContext(),
        );

        expect(result.map((message) => message.content).skip(2), [
          'Reciente 1',
          'Reciente 2',
          'Actual',
        ]);
        expect(
          result
              .take(2)
              .every((message) => message.role == CoachMessageRole.system),
          isTrue,
        );
      },
    );

    test(
      'el limite solo recorta historial y mantiene su orden cronologico',
      () {
        const limitedBuilder = CoachPromptBuilder(
          systemPromptBuilder: DefaultCoachSystemPromptBuilder(),
          contextFormatter: MarkdownContextFormatter(),
          maxConversationMessages: 3,
        );
        final result = limitedBuilder.build(
          userMessage: 'Actual',
          conversation: [
            CoachMessage.user('Descartado'),
            CoachMessage.assistant('Conservado antiguo'),
            CoachMessage.user('Conservado posterior'),
            CoachMessage.assistant('Conservado reciente'),
          ],
          readerContext: _readerContext(),
        );

        expect(result, hasLength(6));
        expect(result.map((message) => message.content).skip(2), [
          'Conservado antiguo',
          'Conservado posterior',
          'Conservado reciente',
          'Actual',
        ]);
      },
    );

    test('es determinista para las mismas entradas', () {
      final conversation = [CoachMessage.user('Anterior')];
      final context = _readerContext();
      final first = builder.build(
        userMessage: 'Actual',
        conversation: conversation,
        readerContext: context,
      );
      final second = builder.build(
        userMessage: 'Actual',
        conversation: conversation,
        readerContext: context,
      );

      expect(
        second.map((message) => (message.role, message.content)),
        first.map((message) => (message.role, message.content)),
      );
    });

    test('incluye resumen antes del historial reciente', () {
      final result = builder.build(
        userMessage: 'Actual',
        conversation: [CoachMessage.user('Anterior')],
        readerContext: _readerContext(),
        conversationSummary: 'Preferencia por novela histórica.',
      );

      expect(result[2].role, CoachMessageRole.system);
      expect(result[2].content, contains('Preferencia por novela histórica.'));
      expect(result[3].content, 'Anterior');
      expect(result.last.content, 'Actual');
    });

    test('rechaza mensaje actual vacio segun la regla de CoachMessage', () {
      expect(
        () => builder.build(
          userMessage: '   ',
          conversation: const [],
          readerContext: _readerContext(),
        ),
        throwsArgumentError,
      );
    });

    test(
      'usa terminados como preferencias y los marca como no recomendables',
      () {
        final result = builder.build(
          userMessage: 'Recomiendame un libro nuevo',
          conversation: const [],
          readerContext: _readerContext(
            books: [
              _book(
                'completed',
                'Vencer al dragon',
                status: BookStatus.completed,
                rating: 5,
                genre: 'Fantasia',
              ),
            ],
          ),
        );

        final contextPrompt = result[1].content;
        expect(contextPrompt, contains('valoracion 5.0'));
        expect(contextPrompt, contains('genero Fantasia'));
        expect(
          contextPrompt,
          contains('## No recomendar como lectura nueva (ya terminados)'),
        );
        expect(contextPrompt, contains('- Vencer al dragon'));
      },
    );

    test('distingue libros en curso de libros terminados', () {
      final result = builder.build(
        userMessage: 'Que puedo leer despues?',
        conversation: const [],
        readerContext: _readerContext(
          books: [
            _book('reading', 'Lectura actual', status: BookStatus.reading),
            _book(
              'completed',
              'Lectura terminada',
              status: BookStatus.completed,
            ),
          ],
        ),
      );

      final contextPrompt = result[1].content;
      expect(contextPrompt, contains('## Libros en lectura\n- Lectura actual'));
      expect(
        contextPrompt,
        contains('## Ultimos libros terminados\n- Lectura terminada'),
      );
      expect(
        contextPrompt,
        contains(
          '## No recomendar como lectura nueva (ya terminados)\n'
          'Estos libros pueden usarse para inferir preferencias, pero no como proxima lectura nueva:\n'
          '- Lectura terminada',
        ),
      );
    });

    test('permite una peticion explicita para hablar de un libro leido', () {
      final result = builder.build(
        userMessage: 'Resume Vencer al dragon, que ya lei',
        conversation: const [],
        readerContext: _readerContext(
          books: [
            _book(
              'completed',
              'Vencer al dragon',
              status: BookStatus.completed,
            ),
          ],
        ),
      );

      expect(
        result.first.content,
        contains(
          'Esta restriccion no impide comentar, resumir o proponer releer un libro terminado',
        ),
      );
      expect(result.last.content, 'Resume Vencer al dragon, que ya lei');
    });

    test(
      'no duplica el mensaje actual al aplicar las reglas de recomendacion',
      () {
        const currentMessage = 'Recomiendame un libro nuevo';
        final result = builder.build(
          userMessage: currentMessage,
          conversation: [CoachMessage.user(currentMessage)],
          conversationIncludesCurrentMessage: true,
          readerContext: _readerContext(),
        );

        expect(
          result.where((message) => message.content == currentMessage),
          hasLength(1),
        );
      },
    );
  });
}

ReaderContext _readerContext({List<Book> books = const []}) => ReaderContext(
  metadata: ReaderContextMetadata(generatedAt: DateTime(2026, 7, 10, 10)),
  library: ReaderLibraryContext(
    allBooks: books,
    currentBooks: books
        .where((book) => book.status == BookStatus.reading)
        .toList(),
    completedBooks: books
        .where((book) => book.status == BookStatus.completed)
        .toList(),
    pendingBooks: books
        .where((book) => book.status == BookStatus.pending)
        .toList(),
    abandonedBooks: books
        .where((book) => book.status == BookStatus.abandoned)
        .toList(),
  ),
  activity: ReaderActivityContext(readingSessions: const []),
);

Book _book(
  String id,
  String title, {
  required BookStatus status,
  double? rating,
  String? genre,
}) {
  return Book(
    id: id,
    title: title,
    status: status,
    rating: rating,
    genre: genre,
    createdAt: DateTime(2026, 7, 1),
  );
}
