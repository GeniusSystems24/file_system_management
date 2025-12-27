import 'dart:async';
import 'dart:math';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/foundation.dart';

/// A task representing a widget download request.
class WidgetDownloadTask {
  final String url;
  final String? fileName;
  final int? expectedSize;
  final Map<String, dynamic>? metadata;

  const WidgetDownloadTask({
    required this.url,
    this.fileName,
    this.expectedSize,
    this.metadata,
  });
}

/// Provider that manages queued downloads for widgets.
///
/// This provider integrates the queue manager with message widgets,
/// allowing you to control concurrent downloads across multiple widgets.
///
/// Example:
/// ```dart
/// // Create a provider with max 3 concurrent downloads
/// final provider = QueuedTransferProvider(maxConcurrent: 3);
///
/// // Use in a widget
/// ImageMessageTransferWidget(
///   url: 'https://example.com/image.jpg',
///   onDownload: (payload) => provider.enqueueDownload(
///     url: payload.url,
///     expectedSize: payload.expectedSize,
///   ),
/// )
///
/// // Listen to queue state
/// provider.stateStream.listen((state) {
///   print('Downloads: ${state.runningCount}/${state.maxConcurrent}');
/// });
/// ```
class QueuedTransferProvider {
  late final TransferQueueManager<WidgetDownloadTask> _queue;
  final Random _random = Random();

  /// Map to track active streams for each URL.
  final Map<String, StreamController<TransferProgress>> _activeStreams = {};

  QueuedTransferProvider({
    int maxConcurrent = 3,
    bool autoRetry = true,
    int maxRetries = 2,
  }) {
    _queue = TransferQueueManager<WidgetDownloadTask>(
      maxConcurrent: maxConcurrent,
      autoRetry: autoRetry,
      maxRetries: maxRetries,
      executor: _executeDownload,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Maximum concurrent downloads.
  int get maxConcurrent => _queue.maxConcurrent;

  /// Sets maximum concurrent downloads.
  set maxConcurrent(int value) => _queue.maxConcurrent = value;

  /// Number of downloads currently running.
  int get runningCount => _queue.runningCount;

  /// Number of downloads waiting in queue.
  int get pendingCount => _queue.pendingCount;

  /// Whether the queue is paused.
  bool get isPaused => _queue.isPaused;

  /// Stream of queue state changes.
  Stream<TransferQueueState<WidgetDownloadTask>> get stateStream =>
      _queue.stateStream;

  /// Current queue state.
  TransferQueueState<WidgetDownloadTask> get state => _queue.state;

  // ═══════════════════════════════════════════════════════════════════════════
  // WIDGET INTEGRATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enqueues a download and returns a progress stream for the widget.
  ///
  /// This method is designed to be used with message widgets' `onDownload` callback:
  /// ```dart
  /// ImageMessageTransferWidget(
  ///   url: 'https://example.com/image.jpg',
  ///   onDownload: (payload) => provider.enqueueDownload(
  ///     url: payload.url,
  ///     expectedSize: payload.expectedSize,
  ///   ),
  /// )
  /// ```
  Stream<TransferProgress> enqueueDownload({
    required String url,
    String? fileName,
    int? expectedSize,
    TransferPriority priority = TransferPriority.normal,
    Map<String, dynamic>? metadata,
  }) {
    // Create a stream controller for this download
    final controller = StreamController<TransferProgress>.broadcast();
    _activeStreams[url] = controller;

    // Create the task
    final task = WidgetDownloadTask(
      url: url,
      fileName: fileName,
      expectedSize: expectedSize,
      metadata: metadata,
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

    // Also emit initial pending status
    controller.add(TransferProgress(
      bytesTransferred: 0,
      totalBytes: expectedSize ?? -1,
      status: TransferStatus.pending,
    ));

    return controller.stream;
  }

  /// Creates a download callback for use with widgets.
  ///
  /// Example:
  /// ```dart
  /// ImageMessageTransferWidget(
  ///   url: 'https://example.com/image.jpg',
  ///   onDownload: provider.createDownloadCallback(
  ///     priority: TransferPriority.high,
  ///   ),
  /// )
  /// ```
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

  /// Pauses the queue (no new downloads start).
  void pause() => _queue.pause();

  /// Resumes the queue.
  void start() => _queue.start();

  /// Cancels a specific download by URL.
  bool cancel(String url) => _queue.cancel(url);

  /// Cancels all downloads.
  void cancelAll() => _queue.cancelAll();

  /// Retries a failed download.
  bool retry(String url) => _queue.retry(url);

  /// Changes priority of a queued download.
  bool changePriority(String url, TransferPriority priority) =>
      _queue.changePriority(url, priority);

  /// Moves a download to the front of the queue.
  bool moveToFront(String url) => _queue.moveToFront(url);

  /// Gets queue position for a URL (-1 if not in queue, 0 if running).
  int getQueuePosition(String url) {
    final transfer = _queue.getTransfer(url);
    return transfer?.queuePosition ?? -1;
  }

  /// Checks if a URL is currently downloading.
  bool isDownloading(String url) {
    final transfer = _queue.getTransfer(url);
    return transfer?.isRunning ?? false;
  }

  /// Checks if a URL is queued.
  bool isQueued(String url) {
    final transfer = _queue.getTransfer(url);
    return transfer?.isQueued ?? false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXECUTOR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Executes the download (simulated for demo purposes).
  Stream<TransferProgress> _executeDownload(
    QueuedTransfer<WidgetDownloadTask> transfer,
  ) async* {
    final task = transfer.task;
    final totalBytes = task.expectedSize ?? 1024 * 1024;
    const steps = 20;
    final stepDuration = Duration(
      milliseconds: 100 + _random.nextInt(200), // 100-300ms per step
    );

    debugPrint('QueuedTransferProvider: Starting download ${task.url}');

    for (int i = 1; i <= steps; i++) {
      // Check for cancellation
      if (transfer.cancellationToken.isCancelled) {
        yield TransferProgress(
          bytesTransferred: (totalBytes * (i - 1) / steps).round(),
          totalBytes: totalBytes,
          status: TransferStatus.cancelled,
        );
        return;
      }

      await Future.delayed(stepDuration);

      // Simulate occasional failures (5% chance after 30%)
      if (_random.nextDouble() < 0.05 && i > steps * 0.3) {
        yield TransferProgress.failed(
          bytesTransferred: (totalBytes * i / steps).round(),
          totalBytes: totalBytes,
          errorMessage: 'خطأ في الشبكة - سيتم إعادة المحاولة',
        );
        return;
      }

      final bytesTransferred = (totalBytes * i / steps).round();
      final bytesPerSecond = totalBytes / (steps * stepDuration.inMilliseconds / 1000);

      yield TransferProgress(
        bytesTransferred: bytesTransferred,
        totalBytes: totalBytes,
        bytesPerSecond: bytesPerSecond,
        estimatedTimeRemaining: Duration(
          milliseconds: ((steps - i) * stepDuration.inMilliseconds).round(),
        ),
        status: i == steps ? TransferStatus.completed : TransferStatus.running,
      );
    }

    debugPrint('QueuedTransferProvider: Completed download ${task.url}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Disposes the provider.
  void dispose() {
    for (final controller in _activeStreams.values) {
      controller.close();
    }
    _activeStreams.clear();
    _queue.dispose();
  }
}

/// Extension to easily create queued providers.
extension QueuedTransferProviderExtension on TransferQueueManager<WidgetDownloadTask> {
  /// Creates a download stream for a widget.
  Stream<TransferProgress> downloadForWidget(
    String url, {
    int? expectedSize,
    TransferPriority priority = TransferPriority.normal,
  }) {
    final task = WidgetDownloadTask(
      url: url,
      expectedSize: expectedSize,
    );

    final queuedTransfer = add(task, id: url, priority: priority);
    return queuedTransfer.progressStream;
  }
}
