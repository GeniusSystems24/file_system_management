import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';

import '../core/extensions/file_path_extension.dart';
import '../core/file_cache_manager.dart';
import '../core/task_mutex.dart';
import '../models/transfer_item.dart';

/// Result of an enqueue operation.
sealed class EnqueueResult {}

/// Task was found in cache - file already exists locally.
class EnqueueCached extends EnqueueResult {
  final String filePath;
  EnqueueCached(this.filePath);
}

/// Task is already in progress - returns existing stream.
class EnqueueInProgress extends EnqueueResult {
  final StreamController<TransferItem> controller;
  EnqueueInProgress(this.controller);
}

/// Task was newly enqueued - returns new stream.
class EnqueueStarted extends EnqueueResult {
  final StreamController<TransferItem> controller;
  EnqueueStarted(this.controller);
}

/// Task was not started because autoStart was false.
class EnqueuePending extends EnqueueResult {
  final StreamController<TransferItem> controller;
  EnqueuePending(this.controller);
}

/// Controller for managing file download and upload tasks.
///
/// Features:
/// - Singleton pattern for global access
/// - Mutex-based locking to prevent duplicate operations
/// - Automatic cache management
/// - Stream-based progress updates
/// - Proper resource cleanup
class FileSystemController {
  // Singleton
  static final FileSystemController instance = FileSystemController._internal();
  factory FileSystemController() => instance;
  FileSystemController._internal();

  // State
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Core downloader
  FileDownloader get _fileDownloader => FileDownloader();

  // Mutex for thread-safe operations
  final _mutex = TaskMutex();

  // Cache: URL -> completed file path
  final Map<String, String> _completedPaths = {};

  // Active transfers: URL -> TransferItem
  final Map<String, TransferItem> _activeTransfers = {};

  // Stream controllers: URL -> StreamController
  final Map<String, StreamController<TransferItem>> _streamControllers = {};

  // Active task URLs (to prevent duplicate enqueues)
  final Set<String> _activeTaskUrls = {};

  // Subscriptions
  StreamSubscription<TaskUpdate>? _updatesSubscription;

  /// Gets all active transfers.
  Map<String, TransferItem> get activeTransfers =>
      Map.unmodifiable(_activeTransfers);

  /// Gets all completed file paths.
  Map<String, String> get completedPaths => Map.unmodifiable(_completedPaths);

  /// Gets a transfer item by URL.
  TransferItem? getTransfer(String url) => _activeTransfers[url];

  /// Gets the cached path for a URL.
  String? getCachedPath(String url) => _completedPaths[url];

  /// Checks if a URL is currently being processed.
  bool isProcessing(String url) => _activeTaskUrls.contains(url);

  /// Checks if a URL has been completed.
  bool isCompleted(String url) => _completedPaths.containsKey(url);

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initializes the controller.
  ///
  /// Must be called before any other operations.
  /// Safe to call multiple times - will only initialize once.
  ///
  /// [skipExistingFiles] - If true, skip downloads if file already exists.
  /// [skipExistingFilesMinSize] - Only skip files larger than this size (bytes).
  /// [runInForeground] - Run in foreground mode on Android for longer tasks.
  /// [requestTimeout] - Request timeout duration.
  Future<void> initialize({
    bool skipExistingFiles = false,
    int? skipExistingFilesMinSize,
    bool runInForeground = false,
    Duration? requestTimeout,
  }) async {
    if (_isInitialized) return;

    // Configure notifications
    _configureNotifications();

    // Configure downloader with new options
    await _configureDownloader(
      skipExistingFiles: skipExistingFiles,
      skipExistingFilesMinSize: skipExistingFilesMinSize,
      runInForeground: runInForeground,
      requestTimeout: requestTimeout,
    );

    // Load previous records from database FIRST (wait for it!)
    await _loadPreviousRecords();

    // Listen to updates
    _updatesSubscription = _fileDownloader.updates.listen(_handleTaskUpdate);

    // Start tracking
    await _fileDownloader.trackTasks();
    _fileDownloader.start();

    _isInitialized = true;
    debugPrint('FileSystemController: Initialized');
  }

  Future<void> _configureDownloader({
    bool skipExistingFiles = false,
    int? skipExistingFilesMinSize,
    bool runInForeground = false,
    Duration? requestTimeout,
  }) async {
    final globalConfig = <(Config, Object)>[];
    final androidConfig = <(Config, Object)>[];

    // Skip existing files configuration
    if (skipExistingFiles) {
      if (skipExistingFilesMinSize != null) {
        globalConfig.add((Config.skipExistingFiles, skipExistingFilesMinSize));
      } else {
        globalConfig.add((Config.skipExistingFiles, true));
      }
    }

    // Request timeout
    if (requestTimeout != null) {
      globalConfig.add((Config.requestTimeout, requestTimeout));
    }

    // Run in foreground mode on Android
    if (runInForeground) {
      androidConfig.add((Config.runInForeground, Config.always));
    }

    if (globalConfig.isNotEmpty || androidConfig.isNotEmpty) {
      await _fileDownloader.configure(
        globalConfig: globalConfig.isNotEmpty ? globalConfig : null,
        androidConfig: androidConfig.isNotEmpty ? androidConfig : null,
      );
    }
  }

  void _configureNotifications() {
    _fileDownloader
        .registerCallbacks(
          taskNotificationTapCallback: _onNotificationTap,
        )
        .configureNotificationForGroup(
          FileDownloader.defaultGroup,
          running: const TaskNotification(
            'تحميل {filename}',
            '{progress} - {networkSpeed}',
          ),
          complete: const TaskNotification(
            'اكتمل تحميل {filename}',
            'انقر لفتح الملف',
          ),
          error: const TaskNotification(
            'فشل تحميل {filename}',
            'انقر لإعادة المحاولة',
          ),
          paused: const TaskNotification(
            'تم إيقاف {filename}',
            '{progress} مكتمل',
          ),
          progressBar: true,
        );
  }

  Future<void> _loadPreviousRecords() async {
    try {
      final records = await _fileDownloader.database.allRecords();
      for (final record in records) {
        final item = TransferItem.fromRecord(record);
        _addTransferItem(item);
      }
      debugPrint(
          'FileSystemController: Loaded ${records.length} previous records');
    } catch (e) {
      debugPrint('FileSystemController: Error loading records: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STREAM MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets or creates a stream controller for a URL.
  StreamController<TransferItem> _getOrCreateController(String url) {
    return _streamControllers.putIfAbsent(
      url,
      () => StreamController<TransferItem>.broadcast(),
    );
  }

  /// Gets the stream for a URL (read-only).
  Stream<TransferItem>? getStream(String url) {
    return _streamControllers[url]?.stream;
  }

  /// Cleans up a stream controller for a URL.
  void _cleanupController(String url) {
    final controller = _streamControllers.remove(url);
    controller?.close();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TASK UPDATE HANDLING
  // ═══════════════════════════════════════════════════════════════════════════

  void _handleTaskUpdate(TaskUpdate update) {
    final url = update.task.url;
    var item = _activeTransfers[url];

    if (item != null) {
      item = item.copyWithUpdate(update);
    } else {
      item = TransferItem.fromUpdate(update);
    }

    _addTransferItem(item);

    // Handle completion
    if (item.isComplete) {
      _onTaskCompleted(item);
    }

    // Handle failure/cancellation - cleanup queue
    if (item.isFailed || item.status == TaskStatus.canceled) {
      _activeTaskUrls.remove(url);
    }
  }

  void _addTransferItem(TransferItem item) {
    final url = item.url;

    // Store in active transfers
    _activeTransfers[url] = item;

    // Cache completed paths
    if (item.isComplete) {
      _completedPaths[url] = item.filePath;
      fileCacheManager.put(url, item.filePath, fileSize: item.expectedFileSize);
    }

    // Broadcast update
    _getOrCreateController(url).add(item);
  }

  void _onTaskCompleted(TransferItem item) {
    final url = item.url;

    // Remove from active queue
    _activeTaskUrls.remove(url);

    debugPrint('FileSystemController: Task completed - ${item.filename}');
  }

  void _onNotificationTap(Task task, NotificationType notificationType) {
    final item = _activeTransfers[task.url];
    if (item == null) return;

    switch (notificationType) {
      case NotificationType.complete:
        openFile(item);
        break;
      case NotificationType.error:
        // Could trigger retry
        break;
      default:
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enqueues a download task or returns cached/in-progress result.
  ///
  /// This method is thread-safe and prevents duplicate downloads.
  ///
  /// Returns:
  /// - [EnqueueCached] if the file is already downloaded
  /// - [EnqueueInProgress] if the download is already in progress
  /// - [EnqueueStarted] if a new download was started
  /// - [EnqueuePending] if autoStart is false and task wasn't started
  Future<EnqueueResult> enqueueDownload(
    Task task, {
    bool autoStart = true,
  }) async {
    final url = task.url;

    // Use mutex to prevent race conditions
    return await _mutex.synchronized(url, () async {
      // Check cache first
      final cachedPath = _completedPaths[url];
      if (cachedPath != null) {
        debugPrint('FileSystemController: Cache hit for $url');
        return EnqueueCached(cachedPath);
      }

      // Check if already in progress
      if (_activeTaskUrls.contains(url)) {
        debugPrint('FileSystemController: Already in progress - $url');
        return EnqueueInProgress(_getOrCreateController(url));
      }

      // Check if we have an existing transfer that's not complete
      final existingTransfer = _activeTransfers[url];
      if (existingTransfer != null && !existingTransfer.isComplete) {
        return EnqueueInProgress(_getOrCreateController(url));
      }

      // Mark as active
      _activeTaskUrls.add(url);

      final controller = _getOrCreateController(url);

      if (autoStart) {
        try {
          await _fileDownloader.enqueue(task);
          debugPrint('FileSystemController: Enqueued download - ${task.url}');
          return EnqueueStarted(controller);
        } catch (e) {
          _activeTaskUrls.remove(url);
          debugPrint('FileSystemController: Enqueue failed - $e');
          rethrow;
        }
      }

      return EnqueuePending(controller);
    });
  }

  /// Legacy method for compatibility - use [enqueueDownload] instead.
  @Deprecated('Use enqueueDownload instead')
  Future<(String? filePath, StreamController<TransferItem>? streamController)>
      enqueueOrResume(Task task, bool autoStart) async {
    final result = await enqueueDownload(task, autoStart: autoStart);

    return switch (result) {
      EnqueueCached(:final filePath) => (filePath, null),
      EnqueueInProgress(:final controller) => (null, controller),
      EnqueueStarted(:final controller) => (null, controller),
      EnqueuePending(:final controller) => (null, controller),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPLOAD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enqueues an upload task.
  Future<EnqueueResult> enqueueUpload(
    UploadTask task, {
    bool autoStart = true,
  }) async {
    final url = task.url;

    return await _mutex.synchronized(url, () async {
      // Check if already in progress
      if (_activeTaskUrls.contains(url)) {
        return EnqueueInProgress(_getOrCreateController(url));
      }

      _activeTaskUrls.add(url);
      final controller = _getOrCreateController(url);

      if (autoStart) {
        try {
          await _fileDownloader.enqueue(task);
          debugPrint('FileSystemController: Enqueued upload - ${task.url}');
          return EnqueueStarted(controller);
        } catch (e) {
          _activeTaskUrls.remove(url);
          rethrow;
        }
      }

      return EnqueuePending(controller);
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pauses a transfer.
  Future<bool> pause(TransferItem item) async {
    if (!item.canPause) return false;

    final task = item.task;
    if (task is DownloadTask) {
      return await _fileDownloader.pause(task);
    }
    return false;
  }

  /// Resumes a transfer.
  Future<bool> resume(TransferItem item) async {
    if (!item.canResume) return false;

    final task = item.task;
    if (task is DownloadTask) {
      return await _fileDownloader.resume(task);
    }
    return false;
  }

  /// Cancels a transfer.
  Future<bool> cancel(TransferItem item) async {
    final result = await _fileDownloader.cancelTaskWithId(item.taskId);
    if (result) {
      _activeTaskUrls.remove(item.url);
    }
    return result;
  }

  /// Retries a failed transfer.
  Future<bool> retry(TransferItem item) async {
    if (!item.isFailed) return false;

    final task = item.task;
    _activeTaskUrls.remove(item.url);

    if (task is DownloadTask) {
      final result = await enqueueDownload(task, autoStart: true);
      return result is EnqueueStarted;
    } else if (task is UploadTask) {
      final result = await enqueueUpload(task, autoStart: true);
      return result is EnqueueStarted;
    }
    return false;
  }

  /// Resumes a failed download from where it stopped.
  ///
  /// This attempts to continue the download from the point of failure,
  /// rather than starting from scratch. Only works if the server supports
  /// range requests (ETag validation).
  Future<bool> resumeFailedDownload(TransferItem item) async {
    if (!item.isFailed) return false;

    final task = item.task;
    if (task is! DownloadTask) return false;

    // Try to resume using the background_downloader's resume capability
    final result = await _fileDownloader.resume(task);
    if (result) {
      _activeTaskUrls.add(item.url);
    }
    return result;
  }

  /// Reschedules tasks that are in the database but not in the native downloader.
  ///
  /// This is useful for recovering tasks after app restart or crash.
  /// Returns two lists: (successfully rescheduled, failed to reschedule).
  Future<(List<Task>, List<Task>)> rescheduleMissingTasks() async {
    return await _fileDownloader.rescheduleMissingTasks();
  }

  /// Opens a completed file.
  Future<bool> openFile(TransferItem item) async {
    if (!item.isComplete) return false;

    final task = item.task;
    if (task is DownloadTask) {
      return await _fileDownloader.openFile(task: task);
    }
    return false;
  }

  /// Deletes a transfer and its file.
  Future<void> deleteTransfer(TransferItem item) async {
    final url = item.url;
    final task = item.task;

    // Remove from database
    await _fileDownloader.database.deleteRecordWithId(task.taskId);

    // Remove from memory
    _completedPaths.remove(url);
    _activeTransfers.remove(url);
    _activeTaskUrls.remove(url);

    // Cleanup controller
    _cleanupController(url);

    // Remove from cache
    fileCacheManager.remove(url);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pauses multiple transfers.
  Future<List<bool>> pauseAll(List<TransferItem> items) async {
    return Future.wait(items.map((item) => pause(item)));
  }

  /// Resumes multiple transfers.
  Future<List<bool>> resumeAll(List<TransferItem> items) async {
    return Future.wait(items.map((item) => resume(item)));
  }

  /// Cancels multiple transfers.
  Future<bool> cancelAll(List<TransferItem> items) async {
    final taskIds = items.map((item) => item.taskId).toList();
    final result = await _fileDownloader.cancelTasksWithIds(taskIds);
    if (result) {
      for (final item in items) {
        _activeTaskUrls.remove(item.url);
      }
    }
    return result;
  }

  /// Downloads multiple files in batch.
  ///
  /// Returns a stream of batch progress updates.
  /// Use [onTaskComplete] callback to handle individual task completion.
  Future<Batch> downloadBatch(
    List<DownloadTask> tasks, {
    BatchProgressCallback? onProgress,
    void Function(Task task, TaskStatus status)? onTaskComplete,
    int batchSize = 5,
  }) async {
    return await _fileDownloader.downloadBatch(
      tasks,
      batchProgressCallback: onProgress,
      taskStatusCallback: onTaskComplete,
    );
  }

  /// Uploads multiple files in batch.
  Future<Batch> uploadBatch(
    List<UploadTask> tasks, {
    BatchProgressCallback? onProgress,
    void Function(Task task, TaskStatus status)? onTaskComplete,
  }) async {
    return await _fileDownloader.uploadBatch(
      tasks,
      batchProgressCallback: onProgress,
      taskStatusCallback: onTaskComplete,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED STORAGE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Moves a completed download to shared storage (e.g., Downloads folder).
  ///
  /// [destination] - The shared storage destination.
  /// [directory] - Optional subdirectory within shared storage.
  /// [mimeType] - Optional MIME type for the file.
  ///
  /// Returns the path in shared storage, or null if failed.
  Future<String?> moveToSharedStorage(
    TransferItem item, {
    SharedStorage destination = SharedStorage.downloads,
    String? directory,
    String? mimeType,
  }) async {
    if (!item.isComplete) return null;

    final task = item.task;
    if (task is! DownloadTask) return null;

    return await _fileDownloader.moveToSharedStorage(
      task,
      destination,
      directory: directory ?? '',
      mimeType: mimeType,
    );
  }

  /// Checks if a path is in shared storage.
  Future<bool> isInSharedStorage(String path) async {
    return await _fileDownloader.pathInSharedStorage(path) != null;
  }

  /// Opens a file in shared storage by path.
  Future<bool> openFileByPath(String filePath, {String? mimeType}) async {
    return await _fileDownloader.openFile(
      filePath: filePath,
      mimeType: mimeType,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATABASE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets all task records from the database.
  Future<List<TaskRecord>> getAllRecords() async {
    return await _fileDownloader.database.allRecords();
  }

  /// Gets a task record by ID.
  Future<TaskRecord?> getRecordById(String taskId) async {
    return await _fileDownloader.database.recordForId(taskId);
  }

  /// Gets all records with a specific status.
  Future<List<TaskRecord>> getRecordsByStatus(TaskStatus status) async {
    return await _fileDownloader.database.allRecordsWithStatus(status);
  }

  /// Deletes a record from the database.
  Future<void> deleteRecord(String taskId) async {
    await _fileDownloader.database.deleteRecordWithId(taskId);
  }

  /// Deletes all records from the database.
  Future<void> deleteAllRecords() async {
    await _fileDownloader.database.deleteAllRecords();
  }

  /// Deletes records with specific status.
  Future<void> deleteRecordsByStatus(TaskStatus status) async {
    await _fileDownloader.database.deleteRecordsWithStatus(status);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TASK HOLD/RELEASE (for managing task execution)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Holds a task to prevent it from executing.
  ///
  /// Useful for queuing tasks without starting them immediately.
  Future<bool> holdTask(Task task) async {
    return await _fileDownloader.hold(task);
  }

  /// Releases a held task to allow execution.
  Future<bool> releaseTask(Task task) async {
    return await _fileDownloader.release(task);
  }

  /// Releases all held tasks in a group.
  Future<bool> releaseHeldTasks({String? group}) async {
    return await _fileDownloader.releaseHeldTasks(
      group: group ?? FileDownloader.defaultGroup,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TASK INFO & QUERIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets all tasks currently being tracked.
  Future<List<Task>> getAllTasks() async {
    return await _fileDownloader.allTasks();
  }

  /// Gets all tasks in a specific group.
  Future<List<Task>> getTasksByGroup(String group) async {
    return await _fileDownloader.allTasks(group: group);
  }

  /// Gets a task by ID.
  Future<Task?> getTaskById(String taskId) async {
    return await _fileDownloader.taskForId(taskId);
  }

  /// Resets the downloader (cancels all tasks and clears database).
  Future<void> reset({String? group}) async {
    await _fileDownloader.reset(group: group ?? FileDownloader.defaultGroup);
    _activeTaskUrls.clear();
    _activeTransfers.clear();
    _completedPaths.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Configures WiFi requirement.
  Future<bool> requireWiFi(
    RequireWiFi requirement, {
    bool rescheduleRunningTasks = false,
  }) async {
    return _fileDownloader.requireWiFi(
      requirement,
      rescheduleRunningTasks: rescheduleRunningTasks,
    );
  }

  /// Configures the downloader.
  Future<void> configure({
    List<(Config, Object)>? globalConfig,
    List<(Config, Object)>? androidConfig,
    List<(Config, Object)>? iOSConfig,
    List<(Config, Object)>? desktopConfig,
  }) async {
    await _fileDownloader.configure(
      globalConfig: globalConfig,
      androidConfig: androidConfig,
      iOSConfig: iOSConfig,
      desktopConfig: desktopConfig,
    );
  }

  /// Configures notifications for a group.
  void configureNotificationForGroup(
    String group, {
    TaskNotification? running,
    TaskNotification? complete,
    TaskNotification? error,
    TaskNotification? paused,
    bool progressBar = false,
  }) {
    _fileDownloader.configureNotificationForGroup(
      group,
      running: running,
      complete: complete,
      error: error,
      paused: paused,
      progressBar: progressBar,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERMISSIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets the permissions object for checking/requesting permissions.
  ///
  /// Use this to request permissions for notifications, storage, etc.
  /// Example:
  /// ```dart
  /// final status = await controller.permissions.status(PermissionType.notifications);
  /// if (status != PermissionStatus.granted) {
  ///   await controller.permissions.request(PermissionType.notifications);
  /// }
  /// ```
  Permissions get permissions => _fileDownloader.permissions;

  // ═══════════════════════════════════════════════════════════════════════════
  // STORAGE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Checks available storage space before download.
  ///
  /// Returns the available space in bytes, or null if unavailable.
  /// Use this to check if there's enough space before starting large downloads.
  Future<int?> availableSpace({
    BaseDirectory baseDirectory = BaseDirectory.applicationDocuments,
    String directory = '',
  }) async {
    return await _fileDownloader.availableSpace(
      baseDirectory: baseDirectory,
      directory: directory,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets the default group name.
  String get defaultGroup => FileDownloader.defaultGroup;

  /// Clears all cached data.
  void clearCache() {
    _completedPaths.clear();
    fileCacheManager.clear();
  }

  /// Gets transfer statistics.
  Map<String, dynamic> getStats() {
    int running = 0;
    int paused = 0;
    int completed = 0;
    int failed = 0;

    for (final item in _activeTransfers.values) {
      switch (item.status) {
        case TaskStatus.running:
          running++;
          break;
        case TaskStatus.paused:
          paused++;
          break;
        case TaskStatus.complete:
          completed++;
          break;
        case TaskStatus.failed:
          failed++;
          break;
        default:
          break;
      }
    }

    return {
      'total': _activeTransfers.length,
      'running': running,
      'paused': paused,
      'completed': completed,
      'failed': failed,
      'cached': _completedPaths.length,
      'activeUrls': _activeTaskUrls.length,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cleans up stale entries and resources.
  Future<void> cleanup() async {
    // Clean stale cache entries
    await fileCacheManager.cleanStaleEntries();

    // Clean up completed stream controllers (older than 5 minutes)
    final now = DateTime.now();
    final toCleanup = <String>[];

    for (final entry in _activeTransfers.entries) {
      final item = entry.value;
      if (item.isComplete &&
          item.completedAt != null &&
          now.difference(item.completedAt!).inMinutes > 5) {
        final controller = _streamControllers[entry.key];
        if (controller != null && !controller.hasListener) {
          toCleanup.add(entry.key);
        }
      }
    }

    for (final url in toCleanup) {
      _cleanupController(url);
    }

    debugPrint('FileSystemController: Cleaned up ${toCleanup.length} entries');
  }

  /// Disposes the controller and all resources.
  void dispose() {
    // Cancel subscription
    _updatesSubscription?.cancel();
    _updatesSubscription = null;

    // Close all controllers
    for (final controller in _streamControllers.values) {
      controller.close();
    }
    _streamControllers.clear();

    // Clear all data
    _activeTransfers.clear();
    _completedPaths.clear();
    _activeTaskUrls.clear();

    // Clear mutex
    _mutex.clear();

    // Reset state
    _isInitialized = false;

    debugPrint('FileSystemController: Disposed');
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TASK FACTORY
// ═══════════════════════════════════════════════════════════════════════════

/// Creates a download task with standard configuration.
///
/// [url] - The URL to download from.
/// [filename] - Optional filename (defaults to URL hash).
/// [directory] - Directory path relative to baseDirectory.
/// [baseDirectory] - Base directory for the download.
/// [allowPause] - Allow pausing the download.
/// [updates] - What updates to receive.
/// [group] - Task group for notifications.
/// [headers] - Custom HTTP headers.
/// [metaData] - Custom metadata string.
/// [priority] - Task priority (0-10, higher = more priority).
/// [requiresWiFi] - Require WiFi connection.
/// [retries] - Number of retries on failure.
/// [options] - Advanced task options.
DownloadTask createDownloadTask({
  required String url,
  String? filename,
  String directory = "",
  BaseDirectory baseDirectory = BaseDirectory.temporary,
  bool allowPause = true,
  Updates updates = Updates.statusAndProgress,
  String? group,
  Map<String, String>? headers,
  String? metaData,
  int priority = 5,
  bool requiresWiFi = false,
  int retries = 0,
  TaskOptions? options,
}) {
  return DownloadTask(
    url: url,
    filename: filename ?? url.toHashName(),
    allowPause: allowPause,
    updates: updates,
    directory: directory,
    baseDirectory: baseDirectory,
    group: group ?? FileDownloader.defaultGroup,
    headers: headers ?? {},
    metaData: metaData ?? '',
    priority: priority,
    requiresWiFi: requiresWiFi,
    retries: retries,
    options: options,
  );
}

/// Creates a parallel download task for faster downloads of large files.
///
/// Parallel downloads split the file into multiple chunks and download
/// them simultaneously, which can significantly speed up large file downloads.
///
/// [url] - The URL to download from (or primary URL if using multiple).
/// [urls] - Optional list of URLs for different chunks/mirrors.
/// [chunks] - Number of parallel chunks (default: 4).
/// [filename] - Optional filename (defaults to URL hash).
/// [directory] - Directory path relative to baseDirectory.
/// [baseDirectory] - Base directory for the download.
/// [updates] - What updates to receive.
/// [group] - Task group for notifications.
/// [headers] - Custom HTTP headers.
/// [metaData] - Custom metadata string.
/// [priority] - Task priority (0-10, higher = more priority).
/// [requiresWiFi] - Require WiFi connection.
/// [retries] - Number of retries on failure.
ParallelDownloadTask createParallelDownloadTask({
  required String url,
  List<String>? urls,
  int chunks = 4,
  String? filename,
  String directory = "",
  BaseDirectory baseDirectory = BaseDirectory.temporary,
  Updates updates = Updates.statusAndProgress,
  String? group,
  Map<String, String>? headers,
  String? metaData,
  int priority = 5,
  bool requiresWiFi = false,
  int retries = 0,
}) {
  return ParallelDownloadTask(
    url: url,
    urls: urls,
    chunks: chunks,
    filename: filename ?? url.toHashName(),
    updates: updates,
    directory: directory,
    baseDirectory: baseDirectory,
    group: group ?? FileDownloader.defaultGroup,
    headers: headers ?? {},
    metaData: metaData ?? '',
    priority: priority,
    requiresWiFi: requiresWiFi,
    retries: retries,
  );
}

/// Creates an upload task with standard configuration.
///
/// [url] - The URL to upload to.
/// [filePath] - The local file path to upload.
/// [filename] - Optional filename (defaults to extracted from path).
/// [updates] - What updates to receive.
/// [group] - Task group for notifications.
/// [headers] - Custom HTTP headers.
/// [metaData] - Custom metadata string.
/// [httpRequestMethod] - HTTP method (POST, PUT, etc.).
/// [mimeType] - MIME type of the file.
/// [fields] - Form fields to include with the upload.
/// [priority] - Task priority (0-10).
/// [retries] - Number of retries on failure.
UploadTask createUploadTask({
  required String url,
  required String filePath,
  String? filename,
  Updates updates = Updates.statusAndProgress,
  String? group,
  Map<String, String>? headers,
  String? metaData,
  String httpRequestMethod = 'POST',
  String? mimeType,
  Map<String, String>? fields,
  int priority = 5,
  int retries = 0,
}) {
  return UploadTask(
    url: url,
    filename: filename ?? filePath.extractFileName(),
    updates: updates,
    group: group ?? FileDownloader.defaultGroup,
    headers: headers ?? {},
    metaData: metaData ?? '',
    httpRequestMethod: httpRequestMethod,
    mimeType: mimeType ?? 'application/octet-stream',
    fields: fields ?? {},
    priority: priority,
    retries: retries,
  );
}

/// Creates a binary upload task (raw bytes, no multipart).
///
/// Use this for APIs that expect raw file content in the request body.
UploadTask createBinaryUploadTask({
  required String url,
  required String filePath,
  String? filename,
  Updates updates = Updates.statusAndProgress,
  String? group,
  Map<String, String>? headers,
  String? metaData,
  String httpRequestMethod = 'PUT',
  String? mimeType,
  int priority = 5,
  int retries = 0,
}) {
  return UploadTask(
    url: url,
    filename: filename ?? filePath.extractFileName(),
    updates: updates,
    group: group ?? FileDownloader.defaultGroup,
    headers: headers ?? {},
    metaData: metaData ?? '',
    httpRequestMethod: httpRequestMethod,
    mimeType: mimeType ?? 'application/octet-stream',
    post: 'binary',
    priority: priority,
    retries: retries,
  );
}

/// Creates a multi-file upload task.
///
/// Use this to upload multiple files in a single request.
MultiUploadTask createMultiUploadTask({
  required String url,
  required List<(String fieldName, String filePath)> files,
  Updates updates = Updates.statusAndProgress,
  String? group,
  Map<String, String>? headers,
  String? metaData,
  String httpRequestMethod = 'POST',
  Map<String, String>? fields,
  int priority = 5,
  int retries = 0,
}) {
  return MultiUploadTask(
    url: url,
    files: files,
    updates: updates,
    group: group ?? FileDownloader.defaultGroup,
    headers: headers ?? {},
    metaData: metaData ?? '',
    httpRequestMethod: httpRequestMethod,
    fields: fields ?? {},
    priority: priority,
    retries: retries,
  );
}

/// Creates a data upload task (upload data from memory).
///
/// Use this for uploading generated data or small payloads.
DataTask createDataUploadTask({
  required String url,
  required String data,
  String contentType = 'application/json',
  Updates updates = Updates.statusAndProgress,
  String? group,
  Map<String, String>? headers,
  String? metaData,
  String httpRequestMethod = 'POST',
  int priority = 5,
  int retries = 0,
}) {
  return DataTask(
    url: url,
    data: data,
    contentType: contentType,
    updates: updates,
    group: group ?? FileDownloader.defaultGroup,
    headers: headers ?? {},
    metaData: metaData ?? '',
    httpRequestMethod: httpRequestMethod,
    priority: priority,
    retries: retries,
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// TASK OPTIONS HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Creates TaskOptions with lifecycle callbacks.
///
/// [onTaskStart] - Called just before the task starts. Can modify the task.
/// [onTaskFinished] - Called when task completes (success, failure, or cancel).
/// [auth] - Authentication credentials for the request.
TaskOptions createTaskOptions({
  Future<Task?> Function(Task task)? onTaskStart,
  void Function(Task task, TaskStatus status)? onTaskFinished,
  (String username, String password)? auth,
}) {
  return TaskOptions(
    onTaskStart: onTaskStart,
    onTaskFinished: onTaskFinished,
    auth: auth,
  );
}

/// Creates TaskOptions for authenticated downloads.
TaskOptions createAuthenticatedOptions({
  required String username,
  required String password,
  Future<Task?> Function(Task task)? onTaskStart,
  void Function(Task task, TaskStatus status)? onTaskFinished,
}) {
  return TaskOptions(
    auth: (username, password),
    onTaskStart: onTaskStart,
    onTaskFinished: onTaskFinished,
  );
}
