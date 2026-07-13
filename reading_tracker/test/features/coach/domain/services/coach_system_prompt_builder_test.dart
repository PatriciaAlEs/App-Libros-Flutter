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

    test('limita el humor a una frase corta posterior a la respuesta', () {
      final prompt = builder.build();

      expect(prompt, contains('Da primero la respuesta útil'));
      expect(prompt, contains('una frase corta o una cláusula'));
      expect(prompt, contains('nunca debe convertirse en un segundo párrafo'));
    });

    test('hace preferente un angulo ante cultura explicita y opinativa', () {
      final prompt = builder.build();

      expect(prompt, contains('tenga tono informal u opinativo'));
      expect(prompt, contains('exactamente un ángulo recuperado'));
      expect(prompt, contains('No uses más de una referencia cultural'));
      expect(prompt, contains('En consultas generales y recomendaciones normales'));
    });

    test('da una longitud y una postura propias a la charla cultural', () {
      final prompt = builder.build();

      expect(prompt, contains('responde en 1 o 2 frases'));
      expect(prompt, contains('30 a 60 palabras'));
      expect(prompt, contains('Empieza con una postura clara'));
      expect(prompt, contains('cuándo funciona o falla'));
      expect(prompt, contains('No introduzcas recomendaciones ni preguntas finales'));
    });

    test('desaconseja el registro academico en la charla cultural', () {
      final prompt = builder.build();

      expect(prompt, contains('evita un registro académico'));
      expect(prompt, contains('«bien ejecutado»'));
      expect(prompt, contains('«la dinámica entre los personajes»'));
      expect(prompt, contains('«el desarrollo tiene suficiente peso»'));
      expect(prompt, contains('vocabulario cotidiano'));
    });

    test('no introduce emojis automaticamente', () {
      final prompt = builder.build();

      expect(prompt, contains('No añadas emojis automáticamente'));
      expect(prompt, contains('la persona ya los está utilizando'));
      expect(prompt, contains('no sustituye la broma'));
    });

    test('permite profundidad cuando se solicita analisis literario', () {
      final prompt = builder.build();

      expect(prompt, contains('análisis literario detallado'));
      expect(prompt, contains('puedes usar un registro más profundo'));
      expect(prompt, contains('superar el límite cultural'));
    });

    test('presenta las restricciones como filtros simultaneos y prioritarios', () {
      final prompt = builder.build();

      expect(prompt, contains('restricciones obligatorias indicadas'));
      expect(prompt, contains('deben cumplirse simultaneamente'));
      expect(prompt, contains('cumplir solo algunas no basta'));
      expect(prompt, contains('popularidad, humor o variedad'));
    });

    test('acumula y permite retirar restricciones conversacionales', () {
      final prompt = builder.build();

      expect(prompt, contains('Acumula las restricciones'));
      expect(prompt, contains('se combina con las anteriores'));
      expect(prompt, contains('solo retirala o sustituyela'));
      expect(prompt, contains('historial visible'));
    });

    test('distingue autoconclusivo saga y arco terminado', () {
      final prompt = builder.build();

      expect(prompt, contains('autoconclusivo: la historia principal'));
      expect(prompt, contains('trilogia completa'));
      expect(prompt, contains('saga terminada'));
      expect(prompt, contains('primer arco terminado'));
      expect(prompt, contains('no demuestra que sea una obra autoconclusiva'));
    });

    test('descarta candidatos incompatibles sin mencionarlos', () {
      final prompt = builder.build();

      expect(prompt, contains('descarta silenciosamente'));
      expect(prompt, contains('unicamente con candidatos'));
      expect(prompt, contains('no debe aparecer como recomendacion ni alternativa'));
      expect(prompt, contains('No muestres razonamiento interno'));
    });

    test('se abstiene ante metadatos no verificables', () {
      final prompt = builder.build();

      expect(prompt, contains('No aporta pertenencia o posicion en serie'));
      expect(prompt, contains('no infieras el genero de una persona por su nombre'));
      expect(
        prompt,
        contains('No puedo verificar con seguridad una opcion que cumpla todos esos filtros.'),
      );
      expect(prompt, contains('no rellenes la respuesta con un titulo dudoso'));
    });

    test('contrasta fuera de biblioteca contra todos los estados', () {
      final prompt = builder.build();

      expect(prompt, contains('Inventario completo para exclusiones'));
      expect(
        prompt,
        contains('pendiente, leyendo, completado, pausado o abandonado'),
      );
      expect(prompt, contains('«No completado» no significa'));
      expect(prompt, contains('mayusculas, tildes, puntuacion, espacios o subtitulos'));
    });

    test('subordina el humor a los filtros obligatorios', () {
      final prompt = builder.build();

      expect(prompt, contains('El humor queda por debajo de todos los filtros'));
      expect(prompt, contains('nunca puede sustituir la verificacion factual'));
      expect(prompt, contains('sin restricciones adicionales conserva'));
    });

    test('mantiene el humor desactivado en los casos protegidos', () {
      final prompt = builder.build();

      expect(prompt, contains('esté frustrada'));
      expect(prompt, contains('comunique un error'));
      expect(prompt, contains('asunto sensible'));
      expect(prompt, contains('datos estrictamente factuales'));
      expect(prompt, contains('respuesta sin bromas'));
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
