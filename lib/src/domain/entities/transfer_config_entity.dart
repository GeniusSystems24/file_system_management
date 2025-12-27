/// Domain entity for transfer configuration.
class TransferConfigEntity {
  /// Request headers.
  final Map<String, String>? headers;

  /// Request timeout.
  final Duration? timeout;

  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Delay between retry attempts.
  final Duration retryDelay;

  /// Whether to allow resumable transfers.
  final bool allowResume;

  /// Chunk size for uploads (in bytes).
  final int? chunkSize;

  /// Number of parallel chunks for downloads.
  final int parallelChunks;

  /// Whether to skip if file already exists.
  final bool skipExistingFiles;

  /// Minimum file size for skipping (bytes).
  final int? skipExistingFilesMinSize;

  /// Whether to run in foreground mode.
  final bool runInForeground;

  /// Custom metadata.
  final Map<String, dynamic>? metadata;

  const TransferConfigEntity({
    this.headers,
    this.timeout,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 2),
    this.allowResume = true,
    this.chunkSize,
    this.parallelChunks = 1,
    this.skipExistingFiles = false,
    this.skipExistingFilesMinSize,
    this.runInForeground = false,
    this.metadata,
  });

  /// Creates a copy with updated values.
  TransferConfigEntity copyWith({
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
    Duration? retryDelay,
    bool? allowResume,
    int? chunkSize,
    int? parallelChunks,
    bool? skipExistingFiles,
    int? skipExistingFilesMinSize,
    bool? runInForeground,
    Map<String, dynamic>? metadata,
  }) {
    return TransferConfigEntity(
      headers: headers ?? this.headers,
      timeout: timeout ?? this.timeout,
      maxRetries: maxRetries ?? this.maxRetries,
      retryDelay: retryDelay ?? this.retryDelay,
      allowResume: allowResume ?? this.allowResume,
      chunkSize: chunkSize ?? this.chunkSize,
      parallelChunks: parallelChunks ?? this.parallelChunks,
      skipExistingFiles: skipExistingFiles ?? this.skipExistingFiles,
      skipExistingFilesMinSize:
          skipExistingFilesMinSize ?? this.skipExistingFilesMinSize,
      runInForeground: runInForeground ?? this.runInForeground,
      metadata: metadata ?? this.metadata,
    );
  }
}
