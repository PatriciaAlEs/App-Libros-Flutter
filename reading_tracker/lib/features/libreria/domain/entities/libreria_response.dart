enum LibreriaResponseStatus {
  answered,
  needsClarification,
  actionProposed,
  actionCompleted,
  actionCancelled,
  unavailableOffline,
  insufficientData,
  toolFailed,
  unsupported,
}

class LibreriaResponse {
  const LibreriaResponse({
    required this.status,
    required this.message,
  });

  final LibreriaResponseStatus status;
  final String message;
}
