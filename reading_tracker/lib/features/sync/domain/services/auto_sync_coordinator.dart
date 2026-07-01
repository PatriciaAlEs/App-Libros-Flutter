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
  }) : this._(
         status: AutoSyncStatus.failed,
         upload: upload,
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
      try {
        final download = await _runDownload(userId: userId);
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
}
