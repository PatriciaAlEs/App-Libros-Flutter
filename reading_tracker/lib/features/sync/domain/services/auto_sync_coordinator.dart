import 'sync_orchestrator.dart';

enum AutoSyncStatus { completed, failed, skippedAlreadyRunning }

class AutoSyncResult {
  const AutoSyncResult._({
    required this.status,
    this.upload,
    this.download,
    this.errorMessage,
  });

  const AutoSyncResult.completed({
    required SyncOrchestrationResult upload,
    required SyncDownloadOrchestrationResult download,
  }) : this._(
         status: AutoSyncStatus.completed,
         upload: upload,
         download: download,
       );

  const AutoSyncResult.failed({
    required String errorMessage,
    SyncOrchestrationResult? upload,
    SyncDownloadOrchestrationResult? download,
  }) : this._(
         status: AutoSyncStatus.failed,
         upload: upload,
         download: download,
         errorMessage: errorMessage,
       );

  const AutoSyncResult.skippedAlreadyRunning()
    : this._(status: AutoSyncStatus.skippedAlreadyRunning);

  final AutoSyncStatus status;
  final SyncOrchestrationResult? upload;
  final SyncDownloadOrchestrationResult? download;
  final String? errorMessage;

  bool get isCompleted => status == AutoSyncStatus.completed;
  bool get isFailed => status == AutoSyncStatus.failed;
  bool get isSkippedAlreadyRunning =>
      status == AutoSyncStatus.skippedAlreadyRunning;
}

typedef AutoSyncUploadRunner =
    Future<SyncOrchestrationResult> Function({required String userId});
typedef AutoSyncDownloadRunner =
    Future<SyncDownloadOrchestrationResult> Function({required String userId});

class AutoSyncCoordinator {
  AutoSyncCoordinator({required SyncOrchestrator orchestrator})
    : this.withRunners(
        runUpload: orchestrator.runManualSync,
        runDownload: orchestrator.runManualDownload,
      );

  AutoSyncCoordinator.withRunners({
    required AutoSyncUploadRunner runUpload,
    required AutoSyncDownloadRunner runDownload,
  }) : _runUpload = runUpload,
       _runDownload = runDownload;

  final AutoSyncUploadRunner _runUpload;
  final AutoSyncDownloadRunner _runDownload;

  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<AutoSyncResult> run({required String userId}) async {
    if (_isRunning) {
      return const AutoSyncResult.skippedAlreadyRunning();
    }

    _isRunning = true;
    try {
      final upload = await _runUpload(userId: userId);
      if (upload.failed > 0) {
        return AutoSyncResult.failed(
          upload: upload,
          errorMessage: _failureMessage(
            phase: 'Subida',
            failed: upload.failed,
            messages: upload.failureMessages,
          ),
        );
      }

      try {
        final download = await _runDownload(userId: userId);
        if (download.failed > 0) {
          return AutoSyncResult.failed(
            upload: upload,
            download: download,
            errorMessage: _failureMessage(
              phase: 'Descarga',
              failed: download.failed,
              messages: download.failureMessages,
            ),
          );
        }
        return AutoSyncResult.completed(upload: upload, download: download);
      } catch (error) {
        return AutoSyncResult.failed(
          upload: upload,
          errorMessage: error.toString(),
        );
      }
    } catch (error) {
      return AutoSyncResult.failed(errorMessage: error.toString());
    } finally {
      _isRunning = false;
    }
  }

  String _failureMessage({
    required String phase,
    required int failed,
    required List<String> messages,
  }) {
    final detail = messages.isEmpty ? 'sin detalle adicional' : messages.first;
    return '$phase de sincronizacion con $failed fallo(s): $detail';
  }
}
