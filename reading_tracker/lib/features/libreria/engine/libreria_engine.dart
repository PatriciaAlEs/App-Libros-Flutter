import '../domain/entities/libreria_engine_state.dart';
import '../domain/entities/libreria_request.dart';
import '../domain/entities/libreria_response.dart';
import '../domain/enums/libreria_engine_route.dart';
import '../domain/services/libreria_engine.dart';

class LibrerIAEngine implements LibreriaEngine {
  const LibrerIAEngine();

  static const _readingTerms = <String>{
    'autor',
    'biblioteca',
    'libro',
    'lectura',
    'leer',
    'página',
    'paginas',
    'páginas',
    'progreso',
    'racha',
    'sesión',
    'sesiones',
  };

  @override
  LibreriaEngineState get state => const LibreriaEngineState();

  @override
  LibreriaEngineRoute classify(LibreriaRequest request) {
    final normalized = request.message.trim().toLowerCase();
    if (normalized.isEmpty) return LibreriaEngineRoute.clarification;

    final belongsToReadingDomain = _readingTerms.any(normalized.contains);
    return belongsToReadingDomain
        ? LibreriaEngineRoute.localDeterministic
        : LibreriaEngineRoute.unsupported;
  }

  @override
  Future<LibreriaResponse> handle(LibreriaRequest request) async {
    return switch (classify(request)) {
      LibreriaEngineRoute.clarification => const LibreriaResponse(
        status: LibreriaResponseStatus.needsClarification,
        message: 'Escribe una pregunta sobre tu lectura o tu biblioteca.',
      ),
      LibreriaEngineRoute.unsupported => const LibreriaResponse(
        status: LibreriaResponseStatus.unsupported,
        message:
            'LibrerIA está especializada en tu lectura y tu biblioteca de ReadPp.',
      ),
      _ => const LibreriaResponse(
        status: LibreriaResponseStatus.unsupported,
        message:
            'Las consultas de LibrerIA todavía no están disponibles en esta versión.',
      ),
    };
  }
}
