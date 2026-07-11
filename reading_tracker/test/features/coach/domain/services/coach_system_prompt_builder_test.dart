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
