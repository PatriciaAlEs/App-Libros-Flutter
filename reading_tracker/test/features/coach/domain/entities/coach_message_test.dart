import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/coach/domain/entities/coach_message.dart';

void main() {
  group('CoachMessage', () {
    test('crea mensaje system correctamente', () {
      final message = CoachMessage.system('Eres ReadPp Coach.');

      expect(message.role, CoachMessageRole.system);
      expect(message.content, 'Eres ReadPp Coach.');
    });

    test('crea mensaje user correctamente', () {
      final message = CoachMessage.user('Ayudame con mi lectura.');

      expect(message.role, CoachMessageRole.user);
      expect(message.content, 'Ayudame con mi lectura.');
    });

    test('crea mensaje assistant correctamente', () {
      final message = CoachMessage.assistant('Vamos a revisar tu progreso.');

      expect(message.role, CoachMessageRole.assistant);
      expect(message.content, 'Vamos a revisar tu progreso.');
    });

    test('permite un assistant vacio como mensaje provisional', () {
      final message = CoachMessage.assistant('');

      expect(message.role, CoachMessageRole.assistant);
      expect(message.content, isEmpty);
    });

    test('rechaza contenido vacio', () {
      expect(() => CoachMessage.user(''), throwsArgumentError);
    });

    test('rechaza contenido con solo espacios', () {
      expect(() => CoachMessage.user('   '), throwsArgumentError);
    });

    test('conserva el contenido original cuando es valido', () {
      final message = CoachMessage.user('  Leer 20 minutos hoy.  ');

      expect(message.content, '  Leer 20 minutos hoy.  ');
    });

    test('copyWith conserva identidad persistente y asociacion', () {
      final message = CoachMessage.assistant(
        '',
        id: 'assistant-1',
        conversationId: 'conversation-1',
        parentUserMessageId: 'user-1',
        sequence: 2,
      );

      final updated = message.copyWith(content: 'Respuesta');

      expect(updated.id, 'assistant-1');
      expect(updated.conversationId, 'conversation-1');
      expect(updated.parentUserMessageId, 'user-1');
      expect(updated.sequence, 2);
      expect(updated.content, 'Respuesta');
    });
  });
}
