enum LibreriaViewStatus {
  initial,
  loading,
  response,
  error,
  unavailable,
}

class LibreriaViewState {
  const LibreriaViewState({
    this.status = LibreriaViewStatus.initial,
    this.message,
  });

  final LibreriaViewStatus status;
  final String? message;
}
