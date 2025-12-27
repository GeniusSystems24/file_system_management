/// Domain entity representing a file transfer operation.
///
/// This is a pure domain entity without any external dependencies.
/// It represents the core business data for file transfers.
class TransferEntity {
  /// Unique identifier for the transfer.
  final String id;

  /// URL for the transfer operation.
  final String url;

  /// Local file path.
  final String filePath;

  /// File name.
  final String fileName;

  /// Type of transfer operation.
  final TransferTypeEntity type;

  /// Current status of the transfer.
  final TransferStatusEntity status;

  /// Progress of the transfer (0.0 to 1.0).
  final double progress;

  /// Expected file size in bytes.
  final int expectedSize;

  /// Transferred bytes so far.
  final int transferredBytes;

  /// Transfer speed in bytes per second.
  final double speed;

  /// Estimated time remaining.
  final Duration timeRemaining;

  /// When the transfer was created.
  final DateTime createdAt;

  /// When the transfer started.
  final DateTime? startedAt;

  /// When the transfer completed.
  final DateTime? completedAt;

  /// Error message if failed.
  final String? errorMessage;

  /// Custom metadata.
  final Map<String, dynamic>? metadata;

  /// Task group.
  final String group;

  /// Task priority (0-10).
  final int priority;

  /// Whether the transfer requires WiFi.
  final bool requiresWiFi;

  /// Number of retry attempts.
  final int retries;

  /// Whether pause is allowed.
  final bool allowPause;

  const TransferEntity({
    required this.id,
    required this.url,
    required this.filePath,
    required this.fileName,
    required this.type,
    this.status = TransferStatusEntity.pending,
    this.progress = 0.0,
    this.expectedSize = 0,
    this.transferredBytes = 0,
    this.speed = 0.0,
    this.timeRemaining = Duration.zero,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.errorMessage,
    this.metadata,
    this.group = 'default',
    this.priority = 5,
    this.requiresWiFi = false,
    this.retries = 0,
    this.allowPause = true,
  });

  /// Whether the transfer is complete.
  bool get isComplete => status == TransferStatusEntity.complete;

  /// Whether the transfer is in progress.
  bool get isRunning => status == TransferStatusEntity.running;

  /// Whether the transfer is paused.
  bool get isPaused => status == TransferStatusEntity.paused;

  /// Whether the transfer failed.
  bool get isFailed => status == TransferStatusEntity.failed;

  /// Whether the transfer can be paused.
  bool get canPause => allowPause && isRunning;

  /// Whether the transfer can be resumed.
  bool get canResume => isPaused || isFailed;

  /// Duration of the transfer.
  Duration? get duration {
    if (startedAt == null) return null;
    final end = completedAt ?? DateTime.now();
    return end.difference(startedAt!);
  }

  /// Progress percentage (0-100).
  double get progressPercent => progress * 100;

  /// Creates a copy with updated values.
  TransferEntity copyWith({
    String? id,
    String? url,
    String? filePath,
    String? fileName,
    TransferTypeEntity? type,
    TransferStatusEntity? status,
    double? progress,
    int? expectedSize,
    int? transferredBytes,
    double? speed,
    Duration? timeRemaining,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? metadata,
    String? group,
    int? priority,
    bool? requiresWiFi,
    int? retries,
    bool? allowPause,
  }) {
    return TransferEntity(
      id: id ?? this.id,
      url: url ?? this.url,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      expectedSize: expectedSize ?? this.expectedSize,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      speed: speed ?? this.speed,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
      group: group ?? this.group,
      priority: priority ?? this.priority,
      requiresWiFi: requiresWiFi ?? this.requiresWiFi,
      retries: retries ?? this.retries,
      allowPause: allowPause ?? this.allowPause,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TransferEntity(id: $id, status: $status, progress: $progress)';
}

/// Type of transfer operation.
enum TransferTypeEntity {
  download,
  upload;

  bool get isDownload => this == TransferTypeEntity.download;
  bool get isUpload => this == TransferTypeEntity.upload;
}

/// Status of a transfer operation.
enum TransferStatusEntity {
  pending,
  running,
  paused,
  complete,
  failed,
  canceled,
  waitingToRetry,
  notFound;

  bool get isTerminal =>
      this == complete || this == failed || this == canceled;
}
