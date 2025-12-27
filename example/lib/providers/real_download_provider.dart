import 'dart:async';
import 'dart:io';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/foundation.dart';

/// Provider that uses FileSystemController for real downloads with queue management.
///
/// This provider integrates with the actual download system and caching.
class RealDownloadProvider {
  late final TransferQueueManager<RealDownloadTask> _queue;
  final FileSystemController _controller;

  /// Map to track active streams for each URL.
  final Map<String, StreamController<TransferProgress>> _activeStreams = {};

  /// Map to track completed file paths.
  final Map<String, String> _completedPaths = {};

  RealDownloadProvider({
    int maxConcurrent = 3,
    bool autoRetry = true,
    int maxRetries = 2,
    FileSystemController? controller,
  }) : _controller = controller ?? FileSystemController.instance {
    _queue = TransferQueueManager<RealDownloadTask>(
      maxConcurrent: maxConcurrent,
      autoRetry: autoRetry,
      maxRetries: maxRetries,
      executor: _executeDownload,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  int get maxConcurrent => _queue.maxConcurrent;
  set maxConcurrent(int value) => _queue.maxConcurrent = value;
  int get runningCount => _queue.runningCount;
  int get pendingCount => _queue.pendingCount;
  int get totalCount => _queue.totalCount;
  bool get isPaused => _queue.isPaused;
  Stream<TransferQueueState<RealDownloadTask>> get stateStream => _queue.stateStream;
  TransferQueueState<RealDownloadTask> get state => _queue.state;

  /// Gets the cached file path for a URL (if completed).
  String? getCompletedPath(String url) => _completedPaths[url];

  /// Checks if a file is already cached.
  Future<String?> getCachedPath(String url) async {
    return await _controller.getFilePath(url);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enqueues a download and returns a progress stream.
  Stream<TransferProgress> enqueueDownload({
    required String url,
    String? fileName,
    int? expectedSize,
    TransferPriority priority = TransferPriority.normal,
  }) {
    // Check if already completed
    if (_completedPaths.containsKey(url)) {
      return Stream.value(TransferProgress.completed(totalBytes: expectedSize ?? 0));
    }

    // Create a stream controller for this download
    final controller = StreamController<TransferProgress>.broadcast();
    _activeStreams[url] = controller;

    // Create the task
    final task = RealDownloadTask(
      url: url,
      fileName: fileName,
      expectedSize: expectedSize,
    );

    // Add to queue
    final queuedTransfer = _queue.add(task, id: url, priority: priority);

    // Forward progress from queued transfer to widget stream
    queuedTransfer.progressStream.listen(
      (progress) {
        if (!controller.isClosed) {
          controller.add(progress);
        }
      },
      onDone: () {
        if (!controller.isClosed) {
          controller.close();
        }
        _activeStreams.remove(url);
      },
      onError: (error) {
        if (!controller.isClosed) {
          controller.addError(error);
          controller.close();
        }
        _activeStreams.remove(url);
      },
    );

    // Emit initial pending status
    controller.add(TransferProgress(
      bytesTransferred: 0,
      totalBytes: expectedSize ?? -1,
      status: TransferStatus.pending,
    ));

    return controller.stream;
  }

  /// Creates a download callback for use with widgets.
  Stream<TransferProgress> Function(DownloadPayload payload) createDownloadCallback({
    TransferPriority priority = TransferPriority.normal,
  }) {
    return (payload) => enqueueDownload(
          url: payload.url,
          fileName: payload.fileName,
          expectedSize: payload.expectedSize,
          priority: priority,
        );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void pause() => _queue.pause();
  void start() => _queue.start();
  bool cancel(String url) => _queue.cancel(url);
  void cancelAll() => _queue.cancelAll();
  bool retry(String url) => _queue.retry(url);
  bool changePriority(String url, TransferPriority priority) =>
      _queue.changePriority(url, priority);
  bool moveToFront(String url) => _queue.moveToFront(url);

  int getQueuePosition(String url) {
    final transfer = _queue.getTransfer(url);
    return transfer?.queuePosition ?? -1;
  }

  bool isDownloading(String url) {
    final transfer = _queue.getTransfer(url);
    return transfer?.isRunning ?? false;
  }

  bool isQueued(String url) {
    final transfer = _queue.getTransfer(url);
    return transfer?.isQueued ?? false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXECUTOR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Executes the download using FileSystemController.
  Stream<TransferProgress> _executeDownload(
    QueuedTransfer<RealDownloadTask> transfer,
  ) async* {
    final task = transfer.task;
    final url = task.url;

    debugPrint('RealDownloadProvider: Starting download $url');

    try {
      // Create download task
      final downloadTask = createDownloadTask(
        url: url,
        filename: task.fileName,
      );

      final result = await _controller.enqueueDownload(downloadTask);

      switch (result) {
        case EnqueueCached(:final filePath):
          // Already cached
          _completedPaths[url] = filePath;
          yield TransferProgress.completed(totalBytes: task.expectedSize ?? 0);
          debugPrint('RealDownloadProvider: Cached $url -> $filePath');
          return;

        case EnqueueStarted(:final controller):
        case EnqueueInProgress(:final controller):
        case EnqueuePending(:final controller):
          await for (final item in controller.stream) {
            // Check for cancellation
            if (transfer.cancellationToken.isCancelled) {
              await _controller.cancel(item);
              yield TransferProgress(
                bytesTransferred: item.transferredBytes,
                totalBytes: item.expectedFileSize,
                status: TransferStatus.cancelled,
              );
              return;
            }

            // Convert to TransferProgress
            final progress = TransferProgress(
              bytesTransferred: item.transferredBytes,
              totalBytes: item.expectedFileSize,
              bytesPerSecond: item.networkSpeed,
              estimatedTimeRemaining: item.timeRemaining,
              status: _convertStatus(item.status),
              errorMessage: item.exception?.description,
            );

            yield progress;

            // Check for terminal states
            if (item.isComplete) {
              final filePath = item.filePath;
              if (filePath != null) {
                _completedPaths[url] = filePath;
              }
              yield TransferProgress.completed(
                totalBytes: item.expectedFileSize,
              );
              debugPrint('RealDownloadProvider: Completed $url -> $filePath');
              return;
            }

            if (item.isFailed) {
              yield TransferProgress.failed(
                bytesTransferred: item.transferredBytes,
                totalBytes: item.expectedFileSize,
                errorMessage: item.exception?.description ?? 'Download failed',
              );
              return;
            }
          }
      }
    } catch (e) {
      debugPrint('RealDownloadProvider: Error downloading $url: $e');
      yield TransferProgress.failed(errorMessage: e.toString());
    }
  }

  TransferStatus _convertStatus(TaskStatus status) {
    return switch (status) {
      TaskStatus.enqueued => TransferStatus.pending,
      TaskStatus.running => TransferStatus.running,
      TaskStatus.paused => TransferStatus.paused,
      TaskStatus.complete => TransferStatus.completed,
      TaskStatus.failed => TransferStatus.failed,
      TaskStatus.canceled => TransferStatus.cancelled,
      TaskStatus.waitingToRetry => TransferStatus.waitingToRetry,
      TaskStatus.notFound => TransferStatus.failed,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  void dispose() {
    for (final controller in _activeStreams.values) {
      controller.close();
    }
    _activeStreams.clear();
    _queue.dispose();
  }
}

/// Task for real downloads.
class RealDownloadTask {
  final String url;
  final String? fileName;
  final int? expectedSize;

  const RealDownloadTask({
    required this.url,
    this.fileName,
    this.expectedSize,
  });
}
