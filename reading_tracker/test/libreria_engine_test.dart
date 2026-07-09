import 'package:flutter_test/flutter_test.dart';
import 'package:reading_tracker/features/libreria/domain/entities/libreria_engine_state.dart';
import 'package:reading_tracker/features/libreria/domain/entities/libreria_request.dart';
import 'package:reading_tracker/features/libreria/domain/entities/libreria_response.dart';
import 'package:reading_tracker/features/libreria/domain/enums/libreria_engine_route.dart';
import 'package:reading_tracker/features/libreria/engine/libreria_engine.dart';

void main() {
  const engine = LibrerIAEngine();

  group('LibrerIAEngine', () {
    test('instantiates in the preparation state without AI, data or tools', () {
      expect(engine, isA<LibrerIAEngine>());
      expect(engine.state.phase, LibreriaEnginePhase.preparing);
      expect(engine.state.lastRoute, isNull);
      expect(engine.state.message, 'Preparando coach de lectura');
      expect(engine.state.hasConsultedData, isFalse);
      expect(engine.state.isAiActive, isFalse);
      expect(engine.state.hasAvailableActions, isFalse);
      expect(engine.state.hasRealTools, isFalse);
    });

    test('asks for clarification when the message is empty', () async {
      const request = LibreriaRequest(message: '  ');

      expect(engine.classify(request), LibreriaEngineRoute.clarification);

      final response = await engine.handle(request);
      expect(response.status, LibreriaResponseStatus.needsClarification);
    });

    test('recognizes an in-domain reading request', () async {
      const request = LibreriaRequest(
        message: '¿Cómo va mi progreso de lectura?',
      );

      expect(engine.classify(request), LibreriaEngineRoute.localDeterministic);

      final response = await engine.handle(request);
      expect(response.status, LibreriaResponseStatus.unsupported);
      expect(response.message, contains('todavía no están disponibles'));
    });

    test('rejects a clearly out-of-domain request', () async {
      const request = LibreriaRequest(
        message: 'Escribe un programa para ordenar archivos',
      );

      expect(engine.classify(request), LibreriaEngineRoute.unsupported);

      final response = await engine.handle(request);
      expect(response.status, LibreriaResponseStatus.unsupported);
      expect(response.message, contains('especializada'));
    });
  });
}
