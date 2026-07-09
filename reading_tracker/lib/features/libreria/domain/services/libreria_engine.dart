import '../entities/libreria_engine_state.dart';
import '../entities/libreria_request.dart';
import '../entities/libreria_response.dart';
import '../enums/libreria_engine_route.dart';

abstract interface class LibreriaEngine {
  LibreriaEngineState get state;

  LibreriaEngineRoute classify(LibreriaRequest request);

  Future<LibreriaResponse> handle(LibreriaRequest request);
}
