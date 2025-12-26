import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';

import '../core/app_directory.dart';
import '../core/extensions/string_extension.dart';

/// Task item model that wraps a download/upload task with progress and status information.
class TaskItem implements TaskProgressUpdate, TaskStatusUpdate {
  @override
  final Task task;
  String get taskId => task.taskId;
  String get filename => task.filename;
  String get url => task.url;
  String get displayName => task.displayName;
  String get directory => task.directory;
  BaseDirectory get baseDirectory => task.baseDirectory;
  DateTime get createdAt => task.creationTime;
  String get metaData => task.metaData;
  String get group => task.group;
  bool get requiresWiFi => task.requiresWiFi;
  int get retries => task.retries;
  bool get allowPause => task.allowPause;
  Updates get updates => task.updates;

  @override
  int expectedFileSize;
  @override
  TaskStatus status;
  @override
  double progress;
  @override
  double networkSpeed;
  @override
  Duration timeRemaining;
  @override
  TaskException? exception;

  @override
  String? get charSet => null;

  @override
  bool get hasExpectedFileSize => expectedFileSize > 0;

  @override
  bool get hasNetworkSpeed => networkSpeed > 0;

  @override
  bool get hasTimeRemaining => timeRemaining.inSeconds > 0;

  @override
  String? get mimeType => filename.split('.').last.split("?").first;

  @override
  String get networkSpeedAsString => networkSpeedText;

  @override
  String? get responseBody => null;

  @override
  Map<String, String>? get responseHeaders => null;

  @override
  int? get responseStatusCode => null;

  @override
  String get timeRemainingAsString => timeRemainingText;

  String get filePath {
    String path = baseDirectory.path;

    var directoryPath = directory.textOrNull;
    if (directoryPath != null) path += "/$directoryPath";
    return "$path/${filename.trim()}";
  }

  TaskItem({
    required this.task,
    required this.expectedFileSize,
    this.status = TaskStatus.enqueued,
    this.progress = 0.0,
    this.networkSpeed = 0.0,
    this.timeRemaining = Duration.zero,
    this.exception,
  });

  TaskItem.from(this.task)
    : expectedFileSize = 0,
      status = TaskStatus.enqueued,
      progress = 0.0,
      networkSpeed = 0.0,
      timeRemaining = Duration.zero,
      exception = null;

  TaskItem.fromJson(Map<String, dynamic> json)
    : task = Task.createFromJson(json['task'] ?? json),
      expectedFileSize = json['expectedFileSize'] ?? 0,
      status = json['status'] ?? TaskStatus.enqueued,
      progress = json['progress'] ?? 0.0,
      networkSpeed = json['networkSpeed'] ?? 0.0,
      timeRemaining = json['timeRemaining'] ?? Duration.zero,
      exception = json['exception'];

  TaskItem.fromUpdate(TaskUpdate update)
    : task = update.task,
      expectedFileSize = 0,
      status = update is TaskStatusUpdate ? update.status : TaskStatus.enqueued,
      progress = update is TaskProgressUpdate ? update.progress : 0.0,
      networkSpeed = update is TaskProgressUpdate ? update.networkSpeed : 0.0,
      timeRemaining =
          update is TaskProgressUpdate ? update.timeRemaining : Duration.zero,
      exception = update is TaskStatusUpdate ? update.exception : null;

  TaskItem.fromRecord(TaskRecord record)
    : task = record.task,
      expectedFileSize = record.expectedFileSize,
      status = record.status,
      progress = record.progress,
      networkSpeed = 0,
      timeRemaining = Duration.zero,
      exception = record.exception;

  @override
  TaskItem copyWith({
    Task? task,
    TaskStatus? status,
    TaskException? exception,
    String? responseBody,
    Map<String, String>? responseHeaders,
    int? responseStatusCode,
    String? mimeType,
    String? charSet,
    int? expectedFileSize,
    double? progress,
    double? networkSpeed,
    Duration? timeRemaining,
  }) {
    return TaskItem(
      task: task ?? this.task,
      expectedFileSize: expectedFileSize ?? this.expectedFileSize,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      networkSpeed: networkSpeed ?? this.networkSpeed,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      exception: exception ?? this.exception,
    );
  }

  TaskItem copyWithUpdate(TaskUpdate update) {
    var newProgress = update is TaskProgressUpdate ? update.progress : progress;
    return copyWith(
      status: update is TaskStatusUpdate ? update.status : status,
      progress: newProgress > 0 ? newProgress : progress,
      networkSpeed:
          update is TaskProgressUpdate ? update.networkSpeed : networkSpeed,
      timeRemaining:
          update is TaskProgressUpdate ? update.timeRemaining : timeRemaining,
      exception: update is TaskStatusUpdate ? update.exception : exception,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'task': task.toJson(),
      'expectedFileSize': expectedFileSize,
      'status': status.name,
      'progress': progress,
      'networkSpeed': networkSpeed,
      'timeRemaining': timeRemaining.inSeconds,
      'exception': exception?.toJson(),
    };
  }

  String get statusText {
    switch (status) {
      case TaskStatus.enqueued:
        return 'في الانتظار';
      case TaskStatus.running:
        return 'جاري التحميل';
      case TaskStatus.complete:
        return 'مكتمل';
      case TaskStatus.failed:
        return 'فشل';
      case TaskStatus.canceled:
        return 'ملغى';
      case TaskStatus.paused:
        return 'متوقف';
      case TaskStatus.notFound:
        return 'غير موجود';
      case TaskStatus.waitingToRetry:
        return 'انتظار إعادة المحاولة';
    }
  }

  String get networkSpeedText {
    if (networkSpeed <= 0) return '--';

    if (networkSpeed < 1024) {
      return '${networkSpeed.toStringAsFixed(1)} B/s';
    } else if (networkSpeed < 1024 * 1024) {
      return '${(networkSpeed / 1024).toStringAsFixed(1)} KB/s';
    } else {
      return '${(networkSpeed / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    }
  }

  String get timeRemainingText {
    if (timeRemaining.inSeconds <= 0) return '--';

    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes.remainder(60);
    final seconds = timeRemaining.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}س ${minutes}د';
    } else if (minutes > 0) {
      return '${minutes}د ${seconds}ث';
    } else {
      return '${seconds}ث';
    }
  }

  String get fileSizeText {
    if (expectedFileSize <= 0) return '--';

    final size = expectedFileSize;
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String get progressText {
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  int get downloadedBytes {
    if (expectedFileSize <= 0) return 0;
    return (expectedFileSize * progress).round();
  }

  String get downloadedSizeText {
    final downloaded = downloadedBytes;
    if (downloaded <= 0) return '0 B';

    if (downloaded < 1024) {
      return '$downloaded B';
    } else if (downloaded < 1024 * 1024) {
      return '${(downloaded / 1024).toStringAsFixed(1)} KB';
    } else if (downloaded < 1024 * 1024 * 1024) {
      return '${(downloaded / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(downloaded / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String get pausedProgressText {
    if (expectedFileSize <= 0) {
      return '$progressText مكتمل';
    }
    return '$downloadedSizeText من $fileSizeText ($progressText)';
  }

  @override
  String toString() {
    return 'TaskItem(task: $task, expectedFileSize: $expectedFileSize, status: $status, progress: $progress, networkSpeed: $networkSpeed, timeRemaining: $timeRemaining, exception: $exception)';
  }
}

/// Extension on [BaseDirectory] to get the path of the base directory.
extension BaseDirectoryExtension on BaseDirectory {
  String get path {
    return switch (this) {
      BaseDirectory.applicationDocuments =>
        AppDirectory.instance.applicationDocumentsDirectory!.path,
      BaseDirectory.temporary => AppDirectory.instance.temporaryDirectory!.path,
      BaseDirectory.applicationSupport =>
        AppDirectory.instance.applicationSupportDirectory!.path,
      BaseDirectory.applicationLibrary =>
        AppDirectory.instance.applicationSupportDirectory!.path,
      BaseDirectory.root => AppDirectory.instance.rootDirectory!.path,
    };
  }
}

/// Extension on [TaskStatus] to get the color representation of the status.
extension TaskStatusExtension on TaskStatus {
  Color get color {
    return switch (this) {
      TaskStatus.enqueued => Colors.blue,
      TaskStatus.running => Colors.purple,
      TaskStatus.complete => Colors.green,
      TaskStatus.failed => Colors.red,
      TaskStatus.paused => Colors.orange,
      TaskStatus.canceled => Colors.grey,
      TaskStatus.waitingToRetry => Colors.grey,
      TaskStatus.notFound => Colors.grey,
    };
  }
}
