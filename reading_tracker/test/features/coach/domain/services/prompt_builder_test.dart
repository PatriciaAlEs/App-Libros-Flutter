import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/books/domain/entities/book.dart';
import 'package:reading_tracker/features/books/domain/enums/book_status.dart';
import 'package:reading_tracker/features/coach/data/culture/bookish_culture_es_v1.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/models/reader_context.dart';
import 'package:reading_tracker/features/coach/domain/services/coach_system_prompt_builder.dart';
import 'package:reading_tracker/features/coach/domain/services/bookish_culture_retriever.dart';
import 'package:reading_tracker/features/coach/domain/services/context_formatter.dart';
import 'package:reading_tracker/features/coach/domain/services/prompt_builder.dart';

void main() {
  group('CoachPromptBuilder', () {
    const builder = CoachPromptBuilder(
      systemPromptBuilder: DefaultCoachSystemPromptBuilder(),
      contextFormatter: MarkdownContextFormatter(),
      bookishCultureRetriever: BookishCultureRetriever(
        entries: bookishCultureEsV1,
      ),
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
        expect(result[0].content, contains('LibrerIA'));
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

    test('un pendiente sigue contando como presente en la biblioteca', () {
      final result = builder.build(
        userMessage: 'Quiero un libro que no este en mi biblioteca',
        conversation: const [],
        readerContext: _readerContext(
          books: [
            _book('pending', 'Libro pendiente', status: BookStatus.pending),
          ],
        ),
      );

      expect(result[1].content, contains('## Inventario completo para exclusiones'));
      expect(result[1].content, contains('Titulo: Libro pendiente'));
      expect(result[1].content, contains('Estado en biblioteca: Pendiente'));
      expect(
        result.first.content,
        contains('«No completado» no significa «fuera de mi biblioteca»'),
      );
    });

    test('conserva las restricciones del caso QA en el seguimiento', () {
      const initial =
          'Estoy en bloqueo lector y mi TBR ya amenaza con independizarse. '
          'Quiero una fantasía cerrada y que no esté en mi biblioteca. '
          '¿Cuál me recomiendas?';
      const followUp =
          '¿Y si te pido que sea autoconclusivo y escrito por una mujer?';
      final result = builder.build(
        userMessage: followUp,
        conversation: [
          CoachMessage.user(initial),
          CoachMessage.assistant('Respuesta anterior'),
        ],
        readerContext: _readerContext(),
      );

      expect(result.first.content, contains('Acumula las restricciones'));
      expect(result.first.content, contains('deben cumplirse simultaneamente'));
      expect(result.first.content, contains('no infieras el genero'));
      expect(result[2].content, initial);
      expect(result.last.content, followUp);
      expect(result.where((message) => message.content == followUp), hasLength(1));
    });

    test('permite retirar expresamente una restriccion anterior', () {
      final result = builder.build(
        userMessage: 'Da igual que sea una saga',
        conversation: [
          CoachMessage.user('Quiero una fantasia autoconclusiva'),
        ],
        readerContext: _readerContext(),
      );

      expect(result.first.content, contains('solo retirala o sustituyela'));
      expect(result[2].content, 'Quiero una fantasia autoconclusiva');
      expect(result.last.content, 'Da igual que sea una saga');
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

    test('inyecta notas tras el contexto y antes del historial', () {
      final result = builder.build(
        userMessage: 'Tengo demasiados pendientes en mi TBR',
        conversation: [CoachMessage.user('Mensaje anterior')],
        readerContext: _readerContext(),
      );

      expect(result[0].content, contains('Eres LibrerIA'));
      expect(result[1].content, startsWith('# Contexto'));
      expect(result[1].content, contains('# Notas opcionales de cultura lectora'));
      expect(
        result[1].content.indexOf('# Notas opcionales de cultura lectora'),
        greaterThan(result[1].content.indexOf('# Contexto')),
      );
      expect(result[2].content, 'Mensaje anterior');
      expect(result.last.content, 'Tengo demasiados pendientes en mi TBR');
    });

    test('marca como preferente el humor para enemies to lovers opinativo', () {
      const current = '¿No está ya muy quemado el enemies to lovers?';
      final result = builder.build(
        userMessage: current,
        conversation: const [],
        readerContext: _readerContext(),
      );

      expect(result[1].content, contains('fase de enemistad'));
      expect(
        result[1].content,
        contains('usa exactamente un único ángulo recuperado'),
      );
      expect(result.where((message) => message.content == current), hasLength(1));
    });

    test('aplica el tono cotidiano y breve a cultura explicita', () {
      const current = '¿Los enemies to lovers están muy quemados?';
      final result = builder.build(
        userMessage: current,
        conversation: const [],
        readerContext: _readerContext(),
      );

      expect(result.first.content, contains('responde en 1 o 2 frases'));
      expect(result.first.content, contains('30 a 60 palabras'));
      expect(result.first.content, contains('evita un registro académico'));
      expect(result.first.content, contains('No añadas emojis automáticamente'));
      expect(result[1].content, contains('fase de enemistad'));
      expect(result.where((message) => message.content == current), hasLength(1));
    });

    test('no inyecta notas sin una coincidencia clara', () {
      final result = builder.build(
        userMessage: 'Cuantas paginas lei esta semana',
        conversation: const [],
        readerContext: _readerContext(),
      );
      expect(result[1].content, isNot(contains('Notas opcionales')));
    });

    test('mantiene una sola copia del mensaje al inyectar cultura lectora', () {
      const current = 'Quiero enemies to lovers';
      final result = builder.build(
        userMessage: current,
        conversation: [CoachMessage.user(current)],
        conversationIncludesCurrentMessage: true,
        readerContext: _readerContext(),
      );
      expect(result.where((message) => message.content == current), hasLength(1));
    });

    test('define respuestas breves y permite detalle solicitado', () {
      final prompt = builder.build(
        userMessage: 'Explicamelo con detalle',
        conversation: const [],
        readerContext: _readerContext(),
      ).first.content;
      expect(prompt, contains('consulta sencilla: normalmente entre 1 y 3 frases'));
      expect(prompt, contains('40 a 80 palabras'));
      expect(prompt, contains('máximo aproximado de 120 palabras'));
      expect(prompt, contains('máximo 3 acciones concretas'));
      expect(prompt, contains('máximo 3 propuestas'));
      expect(prompt, contains('pida expresamente detalle'));
    });

    test('limita el humor y lo evita en situaciones sensibles', () {
      final prompt = builder.build(
        userMessage: 'Estoy frustrada',
        conversation: const [],
        readerContext: _readerContext(),
      ).first.content;
      expect(prompt, contains('como máximo una observación humorística breve'));
      expect(prompt, contains('esté frustrada'));
      expect(prompt, contains('comunique un error'));
      expect(prompt, contains('tema sensible'));
      expect(prompt, contains('estrictamente factuales'));
    });
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
