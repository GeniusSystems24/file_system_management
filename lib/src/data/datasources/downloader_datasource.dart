import 'dart:async';

import 'package:background_downloader/background_downloader.dart';

/// Data source for the background_downloader package.
///
/// This class wraps all interactions with the background_downloader package.
class DownloaderDataSource {
  final FileDownloader _downloader;

  DownloaderDataSource([FileDownloader? downloader])
      : _downloader = downloader ?? FileDownloader();

  // ═══════════════════════════════════════════════════════════════════════════
  // CONFIGURATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Configures the downloader.
  Future<List<(String, String)>> configure({
    dynamic globalConfig,
    dynamic androidConfig,
    dynamic iOSConfig,
    dynamic desktopConfig,
  }) async {
    return await _downloader.configure(
      globalConfig: globalConfig,
      androidConfig: androidConfig,
      iOSConfig: iOSConfig,
      desktopConfig: desktopConfig,
    );
  }

  /// Registers callbacks for notifications.
  FileDownloader registerCallbacks({
    TaskNotificationTapCallback? taskNotificationTapCallback,
  }) {
    return _downloader.registerCallbacks(
      taskNotificationTapCallback: taskNotificationTapCallback,
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
    _downloader.configureNotificationForGroup(
      group,
      running: running,
      complete: complete,
      error: error,
      paused: paused,
      progressBar: progressBar,
    );
  }

  /// Gets the updates stream.
  Stream<TaskUpdate> get updates => _downloader.updates;

  /// Starts tracking tasks.
  Future<void> trackTasks() => _downloader.trackTasks();

  /// Starts the downloader.
  void start() => _downloader.start();

  // ═══════════════════════════════════════════════════════════════════════════
  // ENQUEUE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Enqueues a task.
  Future<bool> enqueue(Task task) => _downloader.enqueue(task);

  /// Downloads a batch of tasks.
  Future<Batch> downloadBatch(
    List<DownloadTask> tasks, {
    BatchProgressCallback? batchProgressCallback,
    TaskStatusCallback? taskStatusCallback,
  }) {
    return _downloader.downloadBatch(
      tasks,
      batchProgressCallback: batchProgressCallback,
      taskStatusCallback: taskStatusCallback,
    );
  }

  /// Uploads a batch of tasks.
  Future<Batch> uploadBatch(
    List<UploadTask> tasks, {
    BatchProgressCallback? batchProgressCallback,
    TaskStatusCallback? taskStatusCallback,
  }) {
    return _downloader.uploadBatch(
      tasks,
      batchProgressCallback: batchProgressCallback,
      taskStatusCallback: taskStatusCallback,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pauses a task.
  Future<bool> pause(DownloadTask task) => _downloader.pause(task);

  /// Resumes a task.
  Future<bool> resume(DownloadTask task) => _downloader.resume(task);

  /// Cancels a task by ID.
  Future<bool> cancelTaskWithId(String taskId) =>
      _downloader.cancelTaskWithId(taskId);

  /// Cancels multiple tasks.
  Future<bool> cancelTasksWithIds(List<String> taskIds) =>
      _downloader.cancelTasksWithIds(taskIds);

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets all tasks.
  Future<List<Task>> allTasks({String? group}) =>
      _downloader.allTasks(group: group ?? FileDownloader.defaultGroup);

  /// Gets a task by ID.
  Future<Task?> taskForId(String taskId) => _downloader.taskForId(taskId);

  // ═══════════════════════════════════════════════════════════════════════════
  // DATABASE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets all records.
  Future<List<TaskRecord>> allRecords() => _downloader.database.allRecords();

  /// Gets a record by ID.
  Future<TaskRecord?> recordForId(String taskId) =>
      _downloader.database.recordForId(taskId);

  /// Gets records by status.
  Future<List<TaskRecord>> allRecordsWithStatus(TaskStatus status) =>
      _downloader.database.allRecordsWithStatus(status);

  /// Deletes a record by ID.
  Future<void> deleteRecordWithId(String taskId) =>
      _downloader.database.deleteRecordWithId(taskId);

  /// Deletes all records.
  Future<void> deleteAllRecords() => _downloader.database.deleteAllRecords();

  /// Deletes records by status.
  Future<void> deleteRecordsWithStatus(TaskStatus status) async {
    final records = await _downloader.database.allRecordsWithStatus(status);

    await _downloader.database
        .deleteRecordsWithIds(records.map((e) => e.taskId).toList());
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Opens a file.
  Future<bool> openFile({Task? task, String? filePath, String? mimeType}) =>
      _downloader.openFile(task: task, filePath: filePath, mimeType: mimeType);

  /// Moves to shared storage.
  Future<String?> moveToSharedStorage(
    DownloadTask task,
    SharedStorage destination, {
    String directory = '',
    String? mimeType,
  }) {
    return _downloader.moveToSharedStorage(
      task,
      destination,
      directory: directory,
      mimeType: mimeType,
    );
  }

  /// Gets path in shared storage.
  Future<String?> pathInSharedStorage(
    String filePath,
    SharedStorage destination, {
    String directory = '',
  }) {
    return _downloader.pathInSharedStorage(filePath, destination,
        directory: directory);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UTILITY OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Reschedules killed tasks.
  Future<(List<Task>, List<Task>)> rescheduleKilledTasks() =>
      _downloader.rescheduleKilledTasks();

  /// Configures WiFi requirement.
  Future<bool> requireWiFi(
    RequireWiFi requirement, {
    bool rescheduleRunningTasks = false,
  }) {
    return _downloader.requireWiFi(
      requirement,
      rescheduleRunningTasks: rescheduleRunningTasks,
    );
  }

  /// Resets the downloader.
  Future<void> reset({required String group}) =>
      _downloader.reset(group: group);

  /// Gets the default group.
  String get defaultGroup => FileDownloader.defaultGroup;
}
