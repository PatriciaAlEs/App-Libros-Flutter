import '../enums/libreria_engine_route.dart';

enum LibreriaEnginePhase { preparing, handling, failed }

class LibreriaEngineState {
  const LibreriaEngineState({
    this.phase = LibreriaEnginePhase.preparing,
    this.lastRoute,
    this.message = 'Preparando coach de lectura',
    this.hasConsultedData = false,
    this.isAiActive = false,
    this.hasAvailableActions = false,
    this.hasRealTools = false,
  });

  final LibreriaEnginePhase phase;
  final LibreriaEngineRoute? lastRoute;
  final String? message;
  final bool hasConsultedData;
  final bool isAiActive;
  final bool hasAvailableActions;
  final bool hasRealTools;
}
