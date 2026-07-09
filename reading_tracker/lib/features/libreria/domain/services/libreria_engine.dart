import '../entities/libreria_request.dart';
import '../entities/libreria_response.dart';
import '../enums/libreria_engine_route.dart';

abstract interface class LibreriaEngine {
  LibreriaEngineRoute classify(LibreriaRequest request);

  Future<LibreriaResponse> handle(LibreriaRequest request);
}
