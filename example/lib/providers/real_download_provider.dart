import 'dart:async';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/foundation.dart';

/// Provider that uses TransferController for real downloads.
///
/// This provider integrates with the actual download system and caching.
class RealDownloadProvider {
  final TransferController _controller;

  /// Map to track active streams for each URL.
  final Map<String, StreamController<TransferProgress>> _activeStreams = {};

  /// Map to track completed file paths.
  final Map<String, String> _completedPaths = {};

  /// Map to track active entities for pause/resume.
  final Map<String, TransferEntity> _activeEntities = {};

  RealDownloadProvider({
    TransferController? controller,
  }) : _controller = controller ?? TransferController.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets the cached file path for a URL (if completed).
  String? getCompletedPath(String url) => _completedPaths[url];

  /// Checks if a file is already cached.
  Future<String?> getCachedPath(String url) async {
    // Check our completed paths first
    final completed = _completedPaths[url];
    if (completed != null) return completed;

    // Check the controller's cache
    final result = await _controller.getCachedPath(url);
    return result.fold(
      onSuccess: (path) => path,
      onFailure: (_) => null,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enqueues a download and returns a progress stream.
  Stream<TransferProgress> enqueueDownload({
    required String url,
    String? fileName,
    int? expectedSize,
  }) {
    // Check if already completed
    if (_completedPaths.containsKey(url)) {
      return Stream.value(TransferProgress.completed(totalBytes: expectedSize ?? 0));
    }

    // Create a stream controller for this download
    final progressController = StreamController<TransferProgress>.broadcast();
    _activeStreams[url] = progressController;

    // Start the download
    _startDownload(url, fileName, progressController);

    return progressController.stream;
  }

  Future<void> _startDownload(
    String url,
    String? fileName,
    StreamController<TransferProgress> progressController,
  ) async {
    // Emit initial pending status
    progressController.add(const TransferProgress(
      bytesTransferred: 0,
      totalBytes: -1,
      status: TransferStatus.pending,
    ));

    final result = await _controller.download(
      url: url,
      fileName: fileName,
    );

    result.fold(
      onSuccess: (stream) {
        stream.listen(
          (entity) {
            // Track the entity for pause/resume
            _activeEntities[url] = entity;

            // Convert to TransferProgress
            final TransferStatus status;
            if (entity.isComplete) {
              status = TransferStatus.completed;
            } else if (entity.isRunning) {
              status = TransferStatus.running;
            } else if (entity.isPaused) {
              status = TransferStatus.paused;
            } else if (entity.isFailed) {
              status = TransferStatus.failed;
            } else {
              status = TransferStatus.pending;
            }

            final progress = TransferProgress(
              bytesTransferred: entity.transferredBytes,
              totalBytes: entity.expectedSize,
              bytesPerSecond: entity.speed,
              estimatedTimeRemaining: entity.timeRemaining,
              status: status,
              errorMessage: entity.errorMessage,
            );

            if (!progressController.isClosed) {
              progressController.add(progress);
            }

            // Check for terminal states
            if (entity.isComplete) {
              _completedPaths[url] = entity.filePath;
              _activeEntities.remove(url);
              if (!progressController.isClosed) {
                progressController.add(TransferProgress.completed(
                  totalBytes: entity.expectedSize,
                ));
                progressController.close();
              }
              _activeStreams.remove(url);
              debugPrint('RealDownloadProvider: Completed $url');
            }

            if (entity.isFailed) {
              _activeEntities.remove(url);
              if (!progressController.isClosed) {
                progressController.add(TransferProgress.failed(
                  bytesTransferred: entity.transferredBytes,
                  totalBytes: entity.expectedSize,
                  errorMessage: entity.errorMessage ?? 'Download failed',
                ));
                progressController.close();
              }
              _activeStreams.remove(url);
            }
          },
          onError: (error) {
            _activeEntities.remove(url);
            if (!progressController.isClosed) {
              progressController.addError(error);
              progressController.close();
            }
            _activeStreams.remove(url);
          },
        );
      },
      onFailure: (failure) {
        if (!progressController.isClosed) {
          progressController.add(TransferProgress.failed(
            errorMessage: failure.message,
          ));
          progressController.close();
        }
        _activeStreams.remove(url);
      },
    );
  }

  /// Creates a download callback for use with widgets.
  Stream<TransferProgress> Function(DownloadPayload payload) createDownloadCallback() {
    return (payload) => enqueueDownload(
          url: payload.url,
          fileName: payload.fileName,
          expectedSize: payload.expectedSize,
        );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pauses a specific download.
  Future<bool> pauseDownload(String url) async {
    final entity = _activeEntities[url];
    if (entity == null) return false;

    final result = await _controller.pause(entity.id);
    return result.fold(
      onSuccess: (success) => success,
      onFailure: (_) => false,
    );
  }

  /// Resumes a specific download.
  Future<bool> resumeDownload(String url) async {
    final entity = _activeEntities[url];
    if (entity == null) return false;

    final result = await _controller.resume(entity.id);
    return result.fold(
      onSuccess: (success) => success,
      onFailure: (_) => false,
    );
  }

  /// Cancels a specific download.
  Future<bool> cancelDownload(String url) async {
    final entity = _activeEntities[url];
    if (entity == null) return false;

    final result = await _controller.cancel(entity.id);
    _activeEntities.remove(url);

    final streamController = _activeStreams.remove(url);
    if (streamController != null && !streamController.isClosed) {
      streamController.add(const TransferProgress(
        bytesTransferred: 0,
        totalBytes: 0,
        status: TransferStatus.cancelled,
      ));
      streamController.close();
    }

    return result.fold(
      onSuccess: (success) => success,
      onFailure: (_) => false,
    );
  }

  /// Checks if a download is paused.
  bool isDownloadPaused(String url) {
    final entity = _activeEntities[url];
    return entity?.isPaused ?? false;
  }

  /// Checks if a URL is currently downloading.
  bool isDownloading(String url) {
    final entity = _activeEntities[url];
    return entity?.isRunning ?? false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  void dispose() {
    for (final controller in _activeStreams.values) {
      controller.close();
    }
    _activeStreams.clear();
    _activeEntities.clear();
  }
}
