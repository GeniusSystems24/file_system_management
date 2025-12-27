import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';

import '../controllers/file_system_controller.dart';
import '../handlers/transfer_progress.dart';
import '../models/transfer_item.dart';
import 'transfer_queue_manager.dart';

/// A specialized queue manager for downloads.
///
/// This integrates with [FileSystemController] to manage downloads with
/// configurable concurrency.
///
/// Example:
/// ```dart
/// // Create a download queue with max 3 concurrent downloads
/// final downloadQueue = DownloadQueueManager(maxConcurrent: 3);
///
/// // Add downloads
/// downloadQueue.addUrl('https://example.com/file1.pdf');
/// downloadQueue.addUrl('https://example.com/file2.pdf');
/// downloadQueue.addUrl('https://example.com/file3.pdf');
/// downloadQueue.addUrl('https://example.com/file4.pdf'); // Will queue
/// downloadQueue.addUrl('https://example.com/file5.pdf'); // Will queue
///
/// // Listen to queue state
/// downloadQueue.stateStream.listen((state) {
///   print('Running: ${state.runningCount}/${state.maxConcurrent}');
///   print('Pending: ${state.pendingCount}');
/// });
///
/// // Wait for all downloads to complete
/// await downloadQueue.waitForAll();
/// ```
class DownloadQueueManager {
  late final TransferQueueManager<DownloadTask> _queue;
  final FileSystemController _controller;

  /// Stream controller for download progress.
  final _progressController =
      StreamController<Map<String, TransferProgress>>.broadcast();

  /// Track progress per download.
  final Map<String, TransferProgress> _progressMap = {};

  /// Track TransferItems per download.
  final Map<String, TransferItem> _transferItems = {};

  /// Stream subscriptions.
  final Map<String, StreamSubscription> _subscriptions = {};

  DownloadQueueManager({
    int maxConcurrent = 3,
    bool autoStart = true,
    bool autoRetry = false,
    int maxRetries = 3,
    FileSystemController? controller,
  }) : _controller = controller ?? FileSystemController.instance {
    _queue = TransferQueueManager<DownloadTask>(
      maxConcurrent: maxConcurrent,
      autoStart: autoStart,
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

  /// Total number of downloads.
  int get totalCount => _queue.totalCount;

  /// Whether the queue is paused.
  bool get isPaused => _queue.isPaused;

  /// Stream of queue state changes.
  Stream<TransferQueueState<DownloadTask>> get stateStream => _queue.stateStream;

  /// Stream of all download progress updates.
  Stream<Map<String, TransferProgress>> get progressStream =>
      _progressController.stream;

  /// Current queue state.
  TransferQueueState<DownloadTask> get state => _queue.state;

  /// Gets a download by ID.
  QueuedTransfer<DownloadTask>? getDownload(String id) => _queue.getTransfer(id);

  /// Gets the TransferItem for a download.
  TransferItem? getTransferItem(String id) => _transferItems[id];

  /// Gets all running downloads.
  List<QueuedTransfer<DownloadTask>> get runningDownloads =>
      _queue.runningTransfers;

  /// Gets all pending downloads.
  List<QueuedTransfer<DownloadTask>> get pendingDownloads =>
      _queue.pendingTransfers;

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Adds a download by URL.
  QueuedTransfer<DownloadTask> addUrl(
    String url, {
    String? filename,
    String? directory,
    BaseDirectory baseDirectory = BaseDirectory.temporary,
    TransferPriority priority = TransferPriority.normal,
    Map<String, String>? headers,
    String? metaData,
  }) {
    final task = createDownloadTask(
      url: url,
      filename: filename,
      directory: directory ?? '',
      baseDirectory: baseDirectory,
      headers: headers,
      metaData: metaData,
    );

    return addTask(task, priority: priority);
  }

  /// Adds a download task.
  QueuedTransfer<DownloadTask> addTask(
    DownloadTask task, {
    TransferPriority priority = TransferPriority.normal,
  }) {
    return _queue.add(
      task,
      id: task.url,
      priority: priority,
      metadata: {'taskId': task.taskId},
    );
  }

  /// Adds multiple downloads by URLs.
  List<QueuedTransfer<DownloadTask>> addUrls(
    List<String> urls, {
    TransferPriority priority = TransferPriority.normal,
  }) {
    return urls.map((url) => addUrl(url, priority: priority)).toList();
  }

  /// Adds multiple download tasks.
  List<QueuedTransfer<DownloadTask>> addTasks(
    List<DownloadTask> tasks, {
    TransferPriority priority = TransferPriority.normal,
  }) {
    return tasks.map((task) => addTask(task, priority: priority)).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Starts processing the queue.
  void start() => _queue.start();

  /// Pauses the queue (running downloads continue).
  void pause() => _queue.pause();

  /// Pauses a specific download.
  Future<bool> pauseDownload(String id) async {
    final transfer = _queue.getTransfer(id);
    if (transfer == null) return false;

    final item = _transferItems[id];
    if (item != null) {
      return await _controller.pause(item);
    }
    return false;
  }

  /// Resumes a specific download.
  Future<bool> resumeDownload(String id) async {
    final transfer = _queue.getTransfer(id);
    if (transfer == null) return false;

    final item = _transferItems[id];
    if (item != null) {
      return await _controller.resume(item);
    }
    return false;
  }

  /// Cancels a specific download.
  bool cancel(String id) {
    final item = _transferItems[id];
    if (item != null) {
      _controller.cancel(item);
    }
    return _queue.cancel(id);
  }

  /// Cancels all downloads.
  void cancelAll() {
    for (final item in _transferItems.values) {
      _controller.cancel(item);
    }
    _queue.cancelAll();
  }

  /// Retries a failed download.
  bool retry(String id) => _queue.retry(id);

  /// Changes the priority of a queued download.
  bool changePriority(String id, TransferPriority priority) =>
      _queue.changePriority(id, priority);

  /// Moves a download to the front of the queue.
  bool moveToFront(String id) => _queue.moveToFront(id);

  /// Removes a download from tracking.
  bool remove(String id) {
    _subscriptions[id]?.cancel();
    _subscriptions.remove(id);
    _progressMap.remove(id);
    _transferItems.remove(id);
    return _queue.remove(id);
  }

  /// Clears all finished downloads.
  void clearFinished() => _queue.clearFinished();

  // ═══════════════════════════════════════════════════════════════════════════
  // WAIT OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Waits for a specific download to complete.
  Future<TransferQueueResult<DownloadTask>> waitFor(String id) async {
    final transfer = _queue.getTransfer(id);
    if (transfer == null) {
      throw ArgumentError('Download not found: $id');
    }
    return transfer.future;
  }

  /// Waits for all downloads to complete.
  Future<List<TransferQueueResult<DownloadTask>>> waitForAll() async {
    final futures = _queue._allTransfers.values
        .where((t) => !t.isFinished)
        .map((t) => t.future)
        .toList();

    return Future.wait(futures);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EXECUTOR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Executes a download using [FileSystemController].
  Stream<TransferProgress> _executeDownload(
    QueuedTransfer<DownloadTask> transfer,
  ) async* {
    final task = transfer.task;
    final url = task.url;

    try {
      final result = await _controller.enqueueDownload(task);

      switch (result) {
        case EnqueueCached(:final filePath):
          // Already cached - yield completed immediately
          yield TransferProgress.completed(totalBytes: 0);
          debugPrint('DownloadQueue: Cached $url -> $filePath');
          return;

        case EnqueueStarted(:final controller):
        case EnqueueInProgress(:final controller):
        case EnqueuePending(:final controller):
          // Listen to the stream and convert to TransferProgress
          final streamController = controller;

          await for (final item in streamController.stream) {
            // Check for cancellation
            if (transfer.cancellationToken.isCancelled) {
              yield TransferProgress(
                bytesTransferred: item.transferredBytes,
                totalBytes: item.expectedFileSize,
                status: TransferStatus.cancelled,
              );
              return;
            }

            // Store the transfer item
            _transferItems[url] = item;

            // Convert to TransferProgress
            final progress = TransferProgress(
              bytesTransferred: item.transferredBytes,
              totalBytes: item.expectedFileSize,
              bytesPerSecond: item.networkSpeed,
              estimatedTimeRemaining: item.timeRemaining,
              status: _convertStatus(item.status),
              errorMessage: item.exception?.description,
            );

            // Update progress map
            _progressMap[url] = progress;
            _emitProgress();

            yield progress;

            // Check for terminal states
            if (item.isComplete) {
              yield TransferProgress.completed(
                totalBytes: item.expectedFileSize,
              );
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
      yield TransferProgress.failed(
        errorMessage: e.toString(),
      );
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

  void _emitProgress() {
    if (!_progressController.isClosed) {
      _progressController.add(Map.unmodifiable(_progressMap));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Disposes the queue manager.
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    _progressMap.clear();
    _transferItems.clear();
    _progressController.close();
    _queue.dispose();
  }
}

/// A specialized queue manager for uploads.
///
/// Similar to [DownloadQueueManager] but for upload operations.
class UploadQueueManager {
  late final TransferQueueManager<UploadTask> _queue;
  final FileSystemController _controller;

  /// Track progress per upload.
  final Map<String, TransferProgress> _progressMap = {};

  /// Track TransferItems per upload.
  final Map<String, TransferItem> _transferItems = {};

  /// Stream controller for upload progress.
  final _progressController =
      StreamController<Map<String, TransferProgress>>.broadcast();

  UploadQueueManager({
    int maxConcurrent = 3,
    bool autoStart = true,
    bool autoRetry = false,
    int maxRetries = 3,
    FileSystemController? controller,
  }) : _controller = controller ?? FileSystemController.instance {
    _queue = TransferQueueManager<UploadTask>(
      maxConcurrent: maxConcurrent,
      autoStart: autoStart,
      autoRetry: autoRetry,
      maxRetries: maxRetries,
      executor: _executeUpload,
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
  Stream<TransferQueueState<UploadTask>> get stateStream => _queue.stateStream;
  Stream<Map<String, TransferProgress>> get progressStream =>
      _progressController.stream;
  TransferQueueState<UploadTask> get state => _queue.state;

  // ═══════════════════════════════════════════════════════════════════════════
  // ADD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Adds an upload task.
  QueuedTransfer<UploadTask> addTask(
    UploadTask task, {
    TransferPriority priority = TransferPriority.normal,
  }) {
    return _queue.add(
      task,
      id: task.taskId,
      priority: priority,
    );
  }

  /// Adds an upload by file path.
  QueuedTransfer<UploadTask> addFile(
    String uploadUrl,
    String filePath, {
    String? filename,
    TransferPriority priority = TransferPriority.normal,
    Map<String, String>? headers,
  }) {
    final task = createUploadTask(
      url: uploadUrl,
      filePath: filePath,
      filename: filename,
      headers: headers,
    );
    return addTask(task, priority: priority);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void start() => _queue.start();
  void pause() => _queue.pause();
  bool cancel(String id) => _queue.cancel(id);
  void cancelAll() => _queue.cancelAll();
  bool retry(String id) => _queue.retry(id);
  bool changePriority(String id, TransferPriority priority) =>
      _queue.changePriority(id, priority);

  // ═══════════════════════════════════════════════════════════════════════════
  // EXECUTOR
  // ═══════════════════════════════════════════════════════════════════════════

  Stream<TransferProgress> _executeUpload(
    QueuedTransfer<UploadTask> transfer,
  ) async* {
    final task = transfer.task;

    try {
      final result = await _controller.enqueueUpload(task);

      switch (result) {
        case EnqueueStarted(:final controller):
        case EnqueueInProgress(:final controller):
        case EnqueuePending(:final controller):
          await for (final item in controller.stream) {
            if (transfer.cancellationToken.isCancelled) {
              yield TransferProgress(
                bytesTransferred: item.transferredBytes,
                totalBytes: item.expectedFileSize,
                status: TransferStatus.cancelled,
              );
              return;
            }

            _transferItems[task.taskId] = item;

            final progress = TransferProgress(
              bytesTransferred: item.transferredBytes,
              totalBytes: item.expectedFileSize,
              bytesPerSecond: item.networkSpeed,
              estimatedTimeRemaining: item.timeRemaining,
              status: _convertStatus(item.status),
              errorMessage: item.exception?.description,
            );

            _progressMap[task.taskId] = progress;
            _emitProgress();

            yield progress;

            if (item.isComplete) {
              yield TransferProgress.completed(totalBytes: item.expectedFileSize);
              return;
            }

            if (item.isFailed) {
              yield TransferProgress.failed(
                bytesTransferred: item.transferredBytes,
                totalBytes: item.expectedFileSize,
                errorMessage: item.exception?.description ?? 'Upload failed',
              );
              return;
            }
          }

        default:
          break;
      }
    } catch (e) {
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

  void _emitProgress() {
    if (!_progressController.isClosed) {
      _progressController.add(Map.unmodifiable(_progressMap));
    }
  }

  void dispose() {
    _progressMap.clear();
    _transferItems.clear();
    _progressController.close();
    _queue.dispose();
  }
}
