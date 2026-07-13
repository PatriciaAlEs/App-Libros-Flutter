import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/data/culture/bookish_culture_es_v1.dart';
import 'package:reading_tracker/features/coach/domain/models/bookish_culture_entry.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';
import 'package:reading_tracker/features/coach/domain/services/bookish_culture_retriever.dart';

void main() {
  const retriever = BookishCultureRetriever(entries: bookishCultureEsV1);
  final now = DateTime(2026, 7, 13);

  List<String> ids(String message) => retriever
      .retrieve(userMessage: message, now: now)
      .map((entry) => entry.id)
      .toList();

  test('recupera TBR y pendientes normalizando mayusculas', () {
    expect(ids('TENGO DEMASIADOS PENDIENTES EN MI TBR'), contains('tbr_pendientes'));
  });

  test('recupera DNF y bloqueo lector', () {
    expect(ids('No consigo terminar este libro'), contains('dnf'));
    expect(ids('Tengo un BLOQUEO LECTOR'), contains('bloqueo_lector'));
  });

  test('recupera enemies to lovers y tropos', () {
    final result = ids('Quiero tropos ENEMIES TO LOVERS');
    expect(result, containsAll(['enemies_to_lovers', 'tropos']));
  });

  test('recupera ediciones especiales y cantos pintados', () {
    final result = ids('Esta edición especial tiene cantos pintados');
    expect(result, containsAll(['ediciones_especiales', 'cantos_pintados']));
  });

  test('recupera saga, cliffhanger y resaca en consultas relacionadas', () {
    expect(ids('Esta saga necesita un árbol genealógico'), contains('sagas'));
    expect(ids('El final tiene un CLIFFHANGER'), contains('cliffhangers'));
    expect(ids('Tengo resaca lectora después de terminar'), contains('resaca_lectora'));
  });

  test('normaliza tildes y variantes razonables', () {
    expect(ids('EDICION ESPECIAL'), contains('ediciones_especiales'));
    expect(ids('FANTASÍA ROMÁNTICA'), contains('romantasy'));
  });

  test('devuelve cero resultados para una consulta no relacionada', () {
    expect(ids('Cuántas páginas leí esta semana'), isEmpty);
  });

  test('devuelve como maximo dos entradas y es determinista', () {
    const message = 'Compré una edición especial con cantos pintados para mi TBR';
    final first = ids(message);
    final second = ids(message);
    expect(first, hasLength(2));
    expect(second, first);
  });

  test('prioriza el mensaje actual y evita repetir la entrada consecutiva', () {
    final result = retriever.retrieve(
      userMessage: 'Mi TBR sigue creciendo',
      recentConversation: [CoachMessage.user('Tengo muchos pendientes en mi TBR')],
      now: now,
    );
    expect(result.map((entry) => entry.id), isNot(contains('tbr_pendientes')));
  });

  test('puede usar el historial para una continuacion clara', () {
    final result = retriever.retrieve(
      userMessage: '¿Y qué hago ahora?',
      recentConversation: [CoachMessage.user('Tengo pendientes en mi TBR')],
      now: now,
    );
    expect(result.map((entry) => entry.id), contains('tbr_pendientes'));
  });

  test('excluye entradas caducadas', () {
    const expiredRetriever = BookishCultureRetriever(
      entries: [
        BookishCultureEntry(
          id: 'caducada',
          topics: ['tendencia'],
          triggers: ['tendencia fugaz'],
          context: 'Contexto temporal.',
          humorAngles: ['Ángulo temporal.'],
          avoidWhen: [],
          evergreen: false,
          reviewedAt: '2024-01-01',
          expiresAt: '2025-01-01',
        ),
      ],
    );
    expect(
      expiredRetriever.retrieve(
        userMessage: 'tendencia fugaz',
        now: DateTime(2026, 1, 1),
      ),
      isEmpty,
    );
  });

  test('frustracion, errores y peticiones factuales desaconsejan humor', () {
    expect(ids('Estoy frustrada: no consigo terminar este libro'), isEmpty);
    expect(ids('Ha fallado con un error al guardar mi TBR'), isEmpty);
    expect(ids('Solo los datos de mi saga, sin bromas'), isEmpty);
  });

  test('el corpus no contiene titulos ni datos ficticios de biblioteca', () {
    expect(bookishCultureCorpusVersion, 'bookish_culture_es_v1');
    for (final entry in bookishCultureEsV1) {
      final content = '${entry.context} ${entry.humorAngles.join(' ')}';
      expect(content, isNot(contains('ISBN')));
      expect(content, isNot(contains('Recomienda')));
      expect(entry.reviewedAt, isNotEmpty);
      expect(entry.evergreen || entry.expiresAt != null, isTrue);
    }
  });
}
