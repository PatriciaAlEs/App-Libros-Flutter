import '../entities/libreria_request.dart';
import '../entities/libreria_response.dart';
import '../enums/libreria_engine_route.dart';
import 'libreria_engine.dart';

class SkeletonLibreriaEngine implements LibreriaEngine {
  const SkeletonLibreriaEngine();

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
