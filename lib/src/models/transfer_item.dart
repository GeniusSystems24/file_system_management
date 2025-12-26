import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';

import '../core/app_directory.dart';
import '../core/extensions/string_extension.dart';

/// Type of transfer operation.
enum TransferType {
  download,
  upload;

  bool get isDownload => this == TransferType.download;
  bool get isUpload => this == TransferType.upload;
}

/// Unified transfer item model for both download and upload operations.
///
/// This model wraps a download/upload task with progress and status information,
/// providing a consistent interface for both operation types.
class TransferItem implements TaskProgressUpdate, TaskStatusUpdate {
  @override
  final Task task;

  /// The type of transfer (download or upload).
  final TransferType transferType;

  // Task properties
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

  // Status and progress
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

  // Additional tracking
  DateTime? _startedAt;
  DateTime? _completedAt;

  /// When the transfer started.
  DateTime? get startedAt => _startedAt;

  /// When the transfer completed.
  DateTime? get completedAt => _completedAt;

  /// Duration of the transfer.
  Duration? get duration {
    if (_startedAt == null) return null;
    final end = _completedAt ?? DateTime.now();
    return end.difference(_startedAt!);
  }

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

  /// Computed file path.
  String get filePath {
    String path = baseDirectory.path;
    var directoryPath = directory.textOrNull;
    if (directoryPath != null) path += "/$directoryPath";
    return "$path/${filename.trim()}";
  }

  /// Whether this is a download task.
  bool get isDownload => transferType == TransferType.download;

  /// Whether this is an upload task.
  bool get isUpload => transferType == TransferType.upload;

  /// Whether the transfer is complete.
  bool get isComplete => status == TaskStatus.complete || progress >= 1.0;

  /// Whether the transfer is in progress.
  bool get isRunning => status == TaskStatus.running;

  /// Whether the transfer is paused.
  bool get isPaused => status == TaskStatus.paused;

  /// Whether the transfer failed.
  bool get isFailed => status == TaskStatus.failed;

  /// Whether the transfer can be paused.
  bool get canPause => allowPause && isRunning;

  /// Whether the transfer can be resumed.
  bool get canResume => isPaused || isFailed;

  TransferItem({
    required this.task,
    required this.transferType,
    required this.expectedFileSize,
    this.status = TaskStatus.enqueued,
    this.progress = 0.0,
    this.networkSpeed = 0.0,
    this.timeRemaining = Duration.zero,
    this.exception,
    DateTime? startedAt,
    DateTime? completedAt,
  })  : _startedAt = startedAt,
        _completedAt = completedAt;

  /// Creates a TransferItem from a Task.
  factory TransferItem.from(Task task) {
    return TransferItem(
      task: task,
      transferType:
          task is UploadTask ? TransferType.upload : TransferType.download,
      expectedFileSize: 0,
    );
  }

  /// Creates a TransferItem from a TaskUpdate.
  factory TransferItem.fromUpdate(TaskUpdate update) {
    final isUpload = update.task is UploadTask;
    return TransferItem(
      task: update.task,
      transferType: isUpload ? TransferType.upload : TransferType.download,
      expectedFileSize: 0,
      status:
          update is TaskStatusUpdate ? update.status : TaskStatus.enqueued,
      progress: update is TaskProgressUpdate ? update.progress : 0.0,
      networkSpeed: update is TaskProgressUpdate ? update.networkSpeed : 0.0,
      timeRemaining: update is TaskProgressUpdate
          ? update.timeRemaining
          : Duration.zero,
      exception: update is TaskStatusUpdate ? update.exception : null,
    );
  }

  /// Creates a TransferItem from a TaskRecord.
  factory TransferItem.fromRecord(TaskRecord record) {
    final isUpload = record.task is UploadTask;
    return TransferItem(
      task: record.task,
      transferType: isUpload ? TransferType.upload : TransferType.download,
      expectedFileSize: record.expectedFileSize,
      status: record.status,
      progress: record.progress,
      networkSpeed: 0,
      timeRemaining: Duration.zero,
      exception: record.exception,
    );
  }

  /// Creates a TransferItem from JSON.
  factory TransferItem.fromJson(Map<String, dynamic> json) {
    return TransferItem(
      task: Task.createFromJson(json['task'] ?? json),
      transferType: json['transferType'] == 'upload'
          ? TransferType.upload
          : TransferType.download,
      expectedFileSize: json['expectedFileSize'] ?? 0,
      status: TaskStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TaskStatus.enqueued,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      networkSpeed: (json['networkSpeed'] as num?)?.toDouble() ?? 0.0,
      timeRemaining: Duration(seconds: json['timeRemaining'] ?? 0),
    );
  }

  @override
  TransferItem copyWith({
    Task? task,
    TransferType? transferType,
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
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return TransferItem(
      task: task ?? this.task,
      transferType: transferType ?? this.transferType,
      expectedFileSize: expectedFileSize ?? this.expectedFileSize,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      networkSpeed: networkSpeed ?? this.networkSpeed,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      exception: exception ?? this.exception,
      startedAt: startedAt ?? _startedAt,
      completedAt: completedAt ?? _completedAt,
    );
  }

  /// Creates a copy with updated values from a TaskUpdate.
  TransferItem copyWithUpdate(TaskUpdate update) {
    final newProgress =
        update is TaskProgressUpdate ? update.progress : progress;
    final newStatus = update is TaskStatusUpdate ? update.status : status;

    // Track timing
    DateTime? newStartedAt = _startedAt;
    DateTime? newCompletedAt = _completedAt;

    if (newStatus == TaskStatus.running && _startedAt == null) {
      newStartedAt = DateTime.now();
    }
    if (newStatus == TaskStatus.complete && _completedAt == null) {
      newCompletedAt = DateTime.now();
    }

    return copyWith(
      status: newStatus,
      progress: newProgress > 0 ? newProgress : progress,
      networkSpeed:
          update is TaskProgressUpdate ? update.networkSpeed : networkSpeed,
      timeRemaining:
          update is TaskProgressUpdate ? update.timeRemaining : timeRemaining,
      exception: update is TaskStatusUpdate ? update.exception : exception,
      startedAt: newStartedAt,
      completedAt: newCompletedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'task': task.toJson(),
      'transferType': transferType.name,
      'expectedFileSize': expectedFileSize,
      'status': status.name,
      'progress': progress,
      'networkSpeed': networkSpeed,
      'timeRemaining': timeRemaining.inSeconds,
      'exception': exception?.toJson(),
    };
  }

  // Localized status text
  String get statusText {
    final prefix = isUpload ? 'رفع' : 'تحميل';
    switch (status) {
      case TaskStatus.enqueued:
        return 'في الانتظار';
      case TaskStatus.running:
        return 'جاري ال$prefix';
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

  /// Formatted network speed.
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

  /// Formatted time remaining.
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

  /// Formatted file size.
  String get fileSizeText {
    if (expectedFileSize <= 0) return '--';
    return _formatBytes(expectedFileSize);
  }

  /// Formatted progress percentage.
  String get progressText {
    return '${(progress * 100).toStringAsFixed(1)}%';
  }

  /// Downloaded/uploaded bytes.
  int get transferredBytes {
    if (expectedFileSize <= 0) return 0;
    return (expectedFileSize * progress).round();
  }

  /// Formatted transferred size.
  String get transferredSizeText {
    return _formatBytes(transferredBytes);
  }

  /// Progress text when paused.
  String get pausedProgressText {
    if (expectedFileSize <= 0) {
      return '$progressText مكتمل';
    }
    return '$transferredSizeText من $fileSizeText ($progressText)';
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';

    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  String toString() {
    return 'TransferItem(type: $transferType, task: $taskId, status: $status, '
        'progress: ${progressText}, url: $url)';
  }
}

/// Extension on [BaseDirectory] to get the path of the base directory.
extension BaseDirectoryPath on BaseDirectory {
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

/// Extension on [TaskStatus] to get UI properties.
extension TaskStatusUI on TaskStatus {
  Color get color {
    return switch (this) {
      TaskStatus.enqueued => Colors.blue,
      TaskStatus.running => Colors.purple,
      TaskStatus.complete => Colors.green,
      TaskStatus.failed => Colors.red,
      TaskStatus.paused => Colors.orange,
      TaskStatus.canceled => Colors.grey,
      TaskStatus.waitingToRetry => Colors.amber,
      TaskStatus.notFound => Colors.grey,
    };
  }

  IconData get icon {
    return switch (this) {
      TaskStatus.enqueued => Icons.hourglass_empty,
      TaskStatus.running => Icons.downloading,
      TaskStatus.complete => Icons.check_circle,
      TaskStatus.failed => Icons.error,
      TaskStatus.paused => Icons.pause_circle,
      TaskStatus.canceled => Icons.cancel,
      TaskStatus.waitingToRetry => Icons.refresh,
      TaskStatus.notFound => Icons.help,
    };
  }
}
