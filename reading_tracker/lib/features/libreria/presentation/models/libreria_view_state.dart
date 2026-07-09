import '../../domain/entities/libreria_engine_state.dart';

enum LibreriaViewStatus { initial, loading, response, error, unavailable }

class LibreriaViewState {
  const LibreriaViewState({
    this.status = LibreriaViewStatus.initial,
    this.message,
  });

  final LibreriaViewStatus status;
  final String? message;

  factory LibreriaViewState.fromEngineState(LibreriaEngineState engineState) {
    return switch (engineState.phase) {
      LibreriaEnginePhase.preparing => LibreriaViewState(
        message: engineState.message,
      ),
      LibreriaEnginePhase.handling => const LibreriaViewState(
        status: LibreriaViewStatus.loading,
        message: 'Preparando LibrerIA',
      ),
      LibreriaEnginePhase.failed => LibreriaViewState(
        status: LibreriaViewStatus.error,
        message: engineState.message,
      ),
    };
  }
}
