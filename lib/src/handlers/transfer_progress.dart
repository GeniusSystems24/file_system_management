import 'package:flutter/foundation.dart';

/// Represents the progress of a file transfer operation.
///
/// This class provides detailed information about the current state
/// of an upload or download operation, including bytes transferred,
/// speed, and estimated time remaining.
class TransferProgress {
  /// Number of bytes transferred so far.
  final int bytesTransferred;

  /// Total number of bytes to transfer.
  /// May be -1 if the total size is unknown.
  final int totalBytes;

  /// Transfer speed in bytes per second.
  final double bytesPerSecond;

  /// Estimated time remaining to complete the transfer.
  final Duration? estimatedTimeRemaining;

  /// Current status of the transfer.
  final TransferStatus status;

  /// Optional error message if the transfer failed.
  final String? errorMessage;

  /// Optional error code for programmatic error handling.
  final String? errorCode;

  /// Timestamp when this progress update was created.
  final DateTime timestamp;

  /// Custom metadata associated with this progress update.
  final Map<String, dynamic>? metadata;

  const TransferProgress({
    required this.bytesTransferred,
    required this.totalBytes,
    this.bytesPerSecond = 0,
    this.estimatedTimeRemaining,
    this.status = TransferStatus.running,
    this.errorMessage,
    this.errorCode,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? const _CurrentDateTime();

  /// Creates an initial progress with zero bytes transferred.
  factory TransferProgress.initial({
    int totalBytes = -1,
    Map<String, dynamic>? metadata,
  }) {
    return TransferProgress(
      bytesTransferred: 0,
      totalBytes: totalBytes,
      status: TransferStatus.pending,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Creates a completed progress.
  factory TransferProgress.completed({
    required int totalBytes,
    Map<String, dynamic>? metadata,
  }) {
    return TransferProgress(
      bytesTransferred: totalBytes,
      totalBytes: totalBytes,
      status: TransferStatus.completed,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Creates a failed progress with error information.
  factory TransferProgress.failed({
    int bytesTransferred = 0,
    int totalBytes = -1,
    required String errorMessage,
    String? errorCode,
    Map<String, dynamic>? metadata,
  }) {
    return TransferProgress(
      bytesTransferred: bytesTransferred,
      totalBytes: totalBytes,
      status: TransferStatus.failed,
      errorMessage: errorMessage,
      errorCode: errorCode,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Creates a paused progress.
  factory TransferProgress.paused({
    required int bytesTransferred,
    required int totalBytes,
    Map<String, dynamic>? metadata,
  }) {
    return TransferProgress(
      bytesTransferred: bytesTransferred,
      totalBytes: totalBytes,
      status: TransferStatus.paused,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
  }

  /// Progress percentage (0.0 to 1.0).
  /// Returns 0.0 if total bytes is unknown.
  double get progress {
    if (totalBytes <= 0) return 0.0;
    return (bytesTransferred / totalBytes).clamp(0.0, 1.0);
  }

  /// Progress percentage (0 to 100).
  double get progressPercent => progress * 100;

  /// Whether the total size is known.
  bool get hasTotalBytes => totalBytes > 0;

  /// Whether the transfer is in progress.
  bool get isRunning => status == TransferStatus.running;

  /// Whether the transfer is paused.
  bool get isPaused => status == TransferStatus.paused;

  /// Whether the transfer has completed.
  bool get isCompleted => status == TransferStatus.completed;

  /// Whether the transfer has failed.
  bool get isFailed => status == TransferStatus.failed;

  /// Whether the transfer is pending.
  bool get isPending => status == TransferStatus.pending;

  /// Whether the transfer was cancelled.
  bool get isCancelled => status == TransferStatus.cancelled;

  /// Whether the transfer is in a terminal state (completed, failed, or cancelled).
  bool get isTerminal => isCompleted || isFailed || isCancelled;

  /// Formatted progress percentage text.
  String get progressText => '${progressPercent.toStringAsFixed(1)}%';

  /// Formatted bytes transferred text.
  String get bytesTransferredText => _formatBytes(bytesTransferred);

  /// Formatted total bytes text.
  String get totalBytesText =>
      hasTotalBytes ? _formatBytes(totalBytes) : '--';

  /// Formatted transfer speed text.
  String get speedText => _formatSpeed(bytesPerSecond);

  /// Formatted estimated time remaining text.
  String get etaText => _formatDuration(estimatedTimeRemaining);

  /// Creates a copy with updated values.
  TransferProgress copyWith({
    int? bytesTransferred,
    int? totalBytes,
    double? bytesPerSecond,
    Duration? estimatedTimeRemaining,
    TransferStatus? status,
    String? errorMessage,
    String? errorCode,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return TransferProgress(
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      bytesPerSecond: bytesPerSecond ?? this.bytesPerSecond,
      estimatedTimeRemaining:
          estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'TransferProgress('
        'status: $status, '
        'progress: $progressText, '
        'bytes: $bytesTransferredText / $totalBytesText, '
        'speed: $speedText'
        ')';
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond <= 0) return '--';
    if (bytesPerSecond < 1024) {
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    }
    if (bytesPerSecond < 1024 * 1024) {
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  static String _formatDuration(Duration? duration) {
    if (duration == null || duration.inSeconds <= 0) return '--';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

/// Status of a file transfer operation.
enum TransferStatus {
  /// Transfer is pending and has not started yet.
  pending,

  /// Transfer is currently in progress.
  running,

  /// Transfer is paused.
  paused,

  /// Transfer completed successfully.
  completed,

  /// Transfer failed with an error.
  failed,

  /// Transfer was cancelled by the user.
  cancelled,

  /// Transfer is waiting to retry after a failure.
  waitingToRetry,
}

/// A [ValueNotifier] that holds the current [TransferProgress].
///
/// This can be used to listen to progress updates in a reactive way.
class TransferProgressNotifier extends ValueNotifier<TransferProgress> {
  TransferProgressNotifier([TransferProgress? initial])
      : super(initial ?? TransferProgress.initial());

  /// Updates the progress.
  void updateProgress(TransferProgress progress) {
    value = progress;
  }

  /// Marks the transfer as running.
  void markRunning() {
    value = value.copyWith(status: TransferStatus.running);
  }

  /// Marks the transfer as paused.
  void markPaused() {
    value = value.copyWith(status: TransferStatus.paused);
  }

  /// Marks the transfer as completed.
  void markCompleted() {
    value = value.copyWith(
      status: TransferStatus.completed,
      bytesTransferred: value.totalBytes > 0 ? value.totalBytes : value.bytesTransferred,
    );
  }

  /// Marks the transfer as failed.
  void markFailed(String errorMessage, {String? errorCode}) {
    value = value.copyWith(
      status: TransferStatus.failed,
      errorMessage: errorMessage,
      errorCode: errorCode,
    );
  }

  /// Marks the transfer as cancelled.
  void markCancelled() {
    value = value.copyWith(status: TransferStatus.cancelled);
  }
}

/// Helper class for const DateTime initialization.
class _CurrentDateTime implements DateTime {
  const _CurrentDateTime();

  DateTime get _now => DateTime.now();

  @override
  DateTime add(Duration duration) => _now.add(duration);

  @override
  int compareTo(DateTime other) => _now.compareTo(other);

  @override
  int get day => _now.day;

  @override
  Duration difference(DateTime other) => _now.difference(other);

  @override
  int get hour => _now.hour;

  @override
  bool isAfter(DateTime other) => _now.isAfter(other);

  @override
  bool isAtSameMomentAs(DateTime other) => _now.isAtSameMomentAs(other);

  @override
  bool isBefore(DateTime other) => _now.isBefore(other);

  @override
  bool get isUtc => _now.isUtc;

  @override
  int get microsecond => _now.microsecond;

  @override
  int get microsecondsSinceEpoch => _now.microsecondsSinceEpoch;

  @override
  int get millisecond => _now.millisecond;

  @override
  int get millisecondsSinceEpoch => _now.millisecondsSinceEpoch;

  @override
  int get minute => _now.minute;

  @override
  int get month => _now.month;

  @override
  int get second => _now.second;

  @override
  DateTime subtract(Duration duration) => _now.subtract(duration);

  @override
  String get timeZoneName => _now.timeZoneName;

  @override
  Duration get timeZoneOffset => _now.timeZoneOffset;

  @override
  String toIso8601String() => _now.toIso8601String();

  @override
  DateTime toLocal() => _now.toLocal();

  @override
  DateTime toUtc() => _now.toUtc();

  @override
  int get weekday => _now.weekday;

  @override
  int get year => _now.year;
}
