import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/domain/services/coach_system_prompt_builder.dart';

void main() {
  group('DefaultCoachSystemPromptBuilder', () {
    const builder = DefaultCoachSystemPromptBuilder();

    test('build devuelve un String no vacio', () {
      final prompt = builder.build();

      expect(prompt, isA<String>());
      expect(prompt.trim(), isNotEmpty);
    });

    test('el prompt contiene ReadPp Coach', () {
      expect(builder.build(), contains('ReadPp Coach'));
    });

    test('el prompt indica que debe usar el contexto lector', () {
      expect(builder.build(), contains('Usa siempre el contexto lector'));
    });

    test('el prompt indica que no debe inventar datos', () {
      expect(builder.build(), contains('inventar datos'));
    });

    test('limita preguntas y exige recomendaciones verificables', () {
      final prompt = builder.build();

      expect(prompt, contains('como maximo una pregunta aclaratoria'));
      expect(prompt, contains('inventar titulos, autores'));
      expect(prompt, contains('obras indie o poco conocidas'));
      expect(prompt, contains('no dispone de esa consulta en tiempo real'));
    });

    test('limita una consulta sencilla a 1-3 frases y 40-80 palabras', () {
      final prompt = builder.build();

      expect(prompt, contains('entre 1 y 3 frases'));
      expect(prompt, contains('40 a 80 palabras'));
      expect(prompt, contains('cada frase debe expresar una idea principal'));
    });

    test('exige escoger una opcion cuando el contexto permite priorizar', () {
      final prompt = builder.build();

      expect(prompt, contains('permiten priorizar una opción, escógela'));
      expect(prompt, contains('explica el criterio en una frase breve'));
      expect(prompt, contains('No enumeres varias opciones'));
      expect(prompt, contains('mayor porcentaje completado'));
      expect(prompt, contains('actividad más reciente'));
    });

    test('evita preguntas finales e invitaciones innecesarias', () {
      final prompt = builder.build();

      expect(prompt, contains('No finalices con una pregunta'));
      expect(prompt, contains('¿Quieres que te ayude...?'));
      expect(prompt, contains('¿Cuál prefieres?'));
      expect(prompt, contains('cambie de forma material la recomendación'));
    });

    test('limita el humor a una frase corta posterior a la recomendacion', () {
      final prompt = builder.build();

      expect(prompt, contains('Da primero la recomendación'));
      expect(prompt, contains('una frase corta o una cláusula'));
      expect(prompt, contains('nunca debe convertirse en un segundo párrafo'));
    });

    test('permite una pregunta ante ambiguedad real', () {
      final prompt = builder.build();

      expect(prompt, contains('Si no existe un criterio suficiente'));
      expect(prompt, contains('haz una sola pregunta'));
    });

    test('mantiene la excepcion para solicitudes detalladas', () {
      expect(
        builder.build(),
        contains('pida expresamente detalle, profundidad'),
      );
    });

    test('el prompt indica que debe responder en el idioma del usuario', () {
      expect(builder.build(), contains('Responde en el idioma del usuario'));
    });

    test('dos llamadas consecutivas a build devuelven el mismo String', () {
      final firstPrompt = builder.build();
      final secondPrompt = builder.build();

      expect(secondPrompt, firstPrompt);
    });

    test('el prompt no contiene placeholders', () {
      final prompt = builder.build();

      expect(prompt, isNot(contains('TODO')));
      expect(prompt, isNot(contains('FIXME')));
      expect(prompt, isNot(matches(RegExp(r'\{\{.*\}\}'))));
    });
  });
}
