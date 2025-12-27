import 'package:background_downloader/background_downloader.dart';

import '../../domain/entities/entities.dart';

/// Data model for transfer operations.
///
/// This model wraps the background_downloader types and provides
/// mapping to/from domain entities.
class TransferModel {
  final Task task;
  final TransferTypeEntity type;
  final TaskStatus status;
  final double progress;
  final int expectedFileSize;
  final double networkSpeed;
  final Duration timeRemaining;
  final TaskException? exception;
  final DateTime? startedAt;
  final DateTime? completedAt;

  TransferModel({
    required this.task,
    required this.type,
    this.status = TaskStatus.enqueued,
    this.progress = 0.0,
    this.expectedFileSize = 0,
    this.networkSpeed = 0.0,
    this.timeRemaining = Duration.zero,
    this.exception,
    this.startedAt,
    this.completedAt,
  });

  /// Creates a model from a Task.
  factory TransferModel.fromTask(Task task) {
    return TransferModel(
      task: task,
      type: task is UploadTask
          ? TransferTypeEntity.upload
          : TransferTypeEntity.download,
    );
  }

  /// Creates a model from a TaskUpdate.
  factory TransferModel.fromUpdate(TaskUpdate update) {
    return TransferModel(
      task: update.task,
      type: update.task is UploadTask
          ? TransferTypeEntity.upload
          : TransferTypeEntity.download,
      status: update is TaskStatusUpdate ? update.status : TaskStatus.enqueued,
      progress: update is TaskProgressUpdate ? update.progress : 0.0,
      networkSpeed: update is TaskProgressUpdate ? update.networkSpeed : 0.0,
      timeRemaining: update is TaskProgressUpdate
          ? update.timeRemaining
          : Duration.zero,
      exception: update is TaskStatusUpdate ? update.exception : null,
    );
  }

  /// Creates a model from a TaskRecord.
  factory TransferModel.fromRecord(TaskRecord record) {
    return TransferModel(
      task: record.task,
      type: record.task is UploadTask
          ? TransferTypeEntity.upload
          : TransferTypeEntity.download,
      status: record.status,
      progress: record.progress,
      expectedFileSize: record.expectedFileSize,
      exception: record.exception,
    );
  }

  /// Converts to domain entity.
  TransferEntity toEntity({String? filePath}) {
    return TransferEntity(
      id: task.taskId,
      url: task.url,
      filePath: filePath ?? _computeFilePath(),
      fileName: task.filename,
      type: type,
      status: _mapStatus(status),
      progress: progress,
      expectedSize: expectedFileSize,
      transferredBytes: (expectedFileSize * progress).round(),
      speed: networkSpeed,
      timeRemaining: timeRemaining,
      createdAt: task.creationTime,
      startedAt: startedAt,
      completedAt: completedAt,
      errorMessage: exception?.description,
      group: task.group,
      priority: task.priority,
      requiresWiFi: task.requiresWiFi,
      retries: task.retries,
      allowPause: task.allowPause,
    );
  }

  String _computeFilePath() {
    // This will be resolved by the infrastructure layer
    final dir = task.directory.isNotEmpty ? '${task.directory}/' : '';
    return '$dir${task.filename}';
  }

  TransferStatusEntity _mapStatus(TaskStatus status) {
    return switch (status) {
      TaskStatus.enqueued => TransferStatusEntity.pending,
      TaskStatus.running => TransferStatusEntity.running,
      TaskStatus.paused => TransferStatusEntity.paused,
      TaskStatus.complete => TransferStatusEntity.complete,
      TaskStatus.failed => TransferStatusEntity.failed,
      TaskStatus.canceled => TransferStatusEntity.canceled,
      TaskStatus.waitingToRetry => TransferStatusEntity.waitingToRetry,
      TaskStatus.notFound => TransferStatusEntity.notFound,
    };
  }

  /// Creates a copy with updated values.
  TransferModel copyWith({
    Task? task,
    TransferTypeEntity? type,
    TaskStatus? status,
    double? progress,
    int? expectedFileSize,
    double? networkSpeed,
    Duration? timeRemaining,
    TaskException? exception,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return TransferModel(
      task: task ?? this.task,
      type: type ?? this.type,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      expectedFileSize: expectedFileSize ?? this.expectedFileSize,
      networkSpeed: networkSpeed ?? this.networkSpeed,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      exception: exception ?? this.exception,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Updates from a TaskUpdate.
  TransferModel updateFrom(TaskUpdate update) {
    final newProgress =
        update is TaskProgressUpdate ? update.progress : progress;
    final newStatus = update is TaskStatusUpdate ? update.status : status;

    DateTime? newStartedAt = startedAt;
    DateTime? newCompletedAt = completedAt;

    if (newStatus == TaskStatus.running && startedAt == null) {
      newStartedAt = DateTime.now();
    }
    if (newStatus == TaskStatus.complete && completedAt == null) {
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
}
