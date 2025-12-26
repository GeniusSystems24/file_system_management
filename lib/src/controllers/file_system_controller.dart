import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';

import '../core/extensions/file_path_extension.dart';
import '../models/notifier.dart';
import '../models/task_item.dart';

/// Controller for managing file download tasks with progress tracking and notifications.
class FileSystemController {
  bool isInitialized = false;
  FileDownloader get fileDownloader => FileDownloader();
  final Map<String, String> _filePaths = {};
  final Map<String, TaskItem> fileUpdates = {};
  final Set<String> _taskUrlsInQueue = {};
  final MapNotifier<String, StreamController<TaskItem>> _fileControllers =
      MapNotifier<String, StreamController<TaskItem>>({});

  // Singleton pattern
  static final FileSystemController instance = FileSystemController._internal();
  factory FileSystemController() => instance;
  FileSystemController._internal();

  /// file stream controller get
  StreamController<TaskItem>? getFileController(String url) =>
      _fileControllers.value[url];

  /// file stream controller create
  StreamController<TaskItem> createFileController(String url) {
    var controller = getFileController(url);
    controller ??= _fileControllers.add(
      url,
      StreamController<TaskItem>.broadcast(),
    );

    return controller;
  }

  // Initialize the controller and setup listeners
  Future<void> initialize() async {
    if (isInitialized) return;
    isInitialized = true;

    // Registering a callback and configure notifications
    FileDownloader()
        .registerCallbacks(
          taskNotificationTapCallback: myNotificationTapCallback,
        )
        .configureNotificationForGroup(
          FileDownloader.defaultGroup,
          // For the main download button
          // which uses 'enqueue' and a default group
          running: const TaskNotification(
            'Download {filename}',
            'File: {filename} - {progress} - speed {networkSpeed} and {timeRemaining} remaining',
          ),
          complete: const TaskNotification(
            '{displayName} download {filename}',
            'Download complete',
          ),
          error: const TaskNotification(
            'Download {filename}',
            'Download failed',
          ),
          paused: const TaskNotification(
            'Download {filename}',
            'Paused with metadata {metadata}',
          ),
          // canceled: const TaskNotification('Download {filename}', 'Canceled'),
          progressBar: false,
        )
        .configureNotificationForGroup(
          'bunch',
          running: const TaskNotification(
            '{numFinished} out of {numTotal}',
            'Progress = {progress}',
          ),
          complete: const TaskNotification("Done!", "Loaded {numTotal} files"),
          error: const TaskNotification(
            'Error',
            '{numFailed}/{numTotal} failed',
          ),
          progressBar: false,
          groupNotificationId: 'notGroup',
        )
        .configureNotification(
          // for the 'Download & Open' dog picture
          // which uses 'download' which is not the .defaultGroup
          // but the .await group so won't use the above config
          complete: const TaskNotification(
            'Download {filename}',
            'Download complete',
          ),
          tapOpensFile: false,
        ); // dog can also open directly from tap

    fileDownloader.database.allRecords().then((records) {
      for (final record in records) {
        _addTaskItem(TaskItem.fromRecord(record));
      }
    });

    fileDownloader.updates.listen((update) {
      _addTaskItem(update);
    });

    // Start the library with database tracking
    await fileDownloader.trackTasks();
    fileDownloader.start();
  }

  void _addTaskItem(TaskUpdate taskUpdate) {
    var taskItem = fileUpdates[taskUpdate.task.url];
    if (taskItem != null) taskItem = taskItem.copyWithUpdate(taskUpdate);

    taskItem ??= TaskItem.fromUpdate(taskUpdate);

    if (taskItem.progress == 1.0) {
      _filePaths[taskItem.url] = taskItem.filePath;
    }

    fileUpdates[taskItem.url] = taskItem;
    createFileController(taskItem.url).add(taskItem);
  }

  Future<(String? filePath, StreamController<TaskItem>? streamController)>
  enqueueOrResume(Task task, bool autoStart) async {
    final filePath = _filePaths[task.url];

    if (filePath != null) return (filePath, null);

    final taskItem = fileUpdates[task.url];
    var streamController = createFileController(task.url);
    if (taskItem != null) return (null, streamController);

    if (autoStart && !_taskUrlsInQueue.contains(task.url)) {
      _taskUrlsInQueue.add(task.url);
      await fileDownloader.enqueue(task);
    }

    return (null, streamController);
  }

  Future<bool> pause(TaskItem taskItem) async {
    final task = taskItem.task;
    if (task is! DownloadTask) return false;

    return await fileDownloader.pause(task);
  }

  Future<bool> resume(TaskItem taskItem) async {
    final task = taskItem.task;
    if (task is! DownloadTask) return false;

    return await fileDownloader.resume(task);
  }

  Future<bool> openFile(TaskItem taskItem) async {
    final task = taskItem.task;
    if (task is! DownloadTask) return false;

    return await fileDownloader.openFile(task: task);
  }

  Future<void> deleteFile(TaskItem taskItem) async {
    final task = taskItem.task;

    await fileDownloader.database.deleteRecordWithId(task.taskId);
    _filePaths.remove(task.url);
    fileUpdates.remove(task.url);
    _fileControllers.value.remove(task.url);
  }

  // Settings operations
  Future<bool> requireWiFi(
    RequireWiFi requireWiFi, {
    bool rescheduleRunningTasks = false,
  }) async {
    return fileDownloader.requireWiFi(
      requireWiFi,
      rescheduleRunningTasks: rescheduleRunningTasks,
    );
  }

  Future<void> configure({
    List<(Config, Object)>? globalConfig,
    List<(Config, Object)>? androidConfig,
    List<(Config, Object)>? iOSConfig,
    List<(Config, Object)>? desktopConfig,
  }) async {
    await fileDownloader.configure(
      globalConfig: globalConfig,
      androidConfig: androidConfig,
      iOSConfig: iOSConfig,
      desktopConfig: desktopConfig,
    );
  }

  // Notification configuration
  void configureNotificationForGroup(
    String group, {
    TaskNotification? running,
    TaskNotification? complete,
    TaskNotification? error,
    TaskNotification? paused,
    bool progressBar = false,
  }) {
    fileDownloader.configureNotificationForGroup(
      group,
      running: running,
      complete: complete,
      error: error,
      paused: paused,
      progressBar: progressBar,
    );
  }

  // File picker operations
  Future<Uri?> pickFile() async {
    // return await fileDownloader.uri.pickFile();
    return null;
  }

  // Batch operations
  Future<List<bool>> pauseAllTasks(List<TaskItem> tasks) async {
    final results = <bool>[];
    for (final task in tasks) {
      try {
        final success = await pause(task);
        results.add(success);
      } catch (e) {
        results.add(false);
      }
    }
    return results;
  }

  Future<List<bool>> resumeAllTasks(List<TaskItem> tasks) async {
    final results = <bool>[];
    for (final task in tasks) {
      try {
        final success = await resume(task);
        results.add(success);
      } catch (e) {
        results.add(false);
      }
    }
    return results;
  }

  Future<bool> cancelAllTasks(List<TaskItem> tasks) async {
    final taskIds = tasks.map((task) => task.taskId).toList();
    return await fileDownloader.cancelTasksWithIds(taskIds);
  }

  // Utility methods
  String get defaultGroup => FileDownloader.defaultGroup;

  // Dispose method
  void dispose() {
    _fileControllers.value.forEach((url, controller) => controller.close());
    _fileControllers.value.clear();
    fileUpdates.clear();
    _filePaths.clear();
    _fileControllers.dispose();
  }

  void myNotificationTapCallback(Task task, NotificationType notificationType) {
    debugPrint(
      'Tapped notification $notificationType for taskId ${task.taskId}',
    );
  }
}

/// Creates a download task with standard configuration.
DownloadTask createDownloadTask({
  required String url,
  String directory = "",
  BaseDirectory baseDirectory = BaseDirectory.temporary,
  bool allowPause = true,
  Updates updates = Updates.statusAndProgress,
}) {
  return DownloadTask(
    url: url,
    allowPause: allowPause,
    updates: updates,
    directory: directory,
    baseDirectory: baseDirectory,
    filename: url.toHashName(),
  );
}
