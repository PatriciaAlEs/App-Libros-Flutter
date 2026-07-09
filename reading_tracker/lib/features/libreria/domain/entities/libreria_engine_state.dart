import '../enums/libreria_engine_route.dart';

enum LibreriaEnginePhase { ready, handling, failed }

class LibreriaEngineState {
  const LibreriaEngineState({
    this.phase = LibreriaEnginePhase.ready,
    this.lastRoute,
    this.message,
  });

  final LibreriaEnginePhase phase;
  final LibreriaEngineRoute? lastRoute;
  final String? message;
}
