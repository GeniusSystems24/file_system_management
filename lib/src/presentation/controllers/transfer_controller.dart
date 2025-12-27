import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/domain.dart';
import '../../data/data.dart';
import '../../infrastructure/infrastructure.dart';
import '../../core/extensions/file_path_extension.dart';

/// Facade controller that provides a simple API for file transfers.
///
/// This controller follows Clean Architecture principles:
/// - Uses domain use cases for business logic
/// - Depends on abstractions (repositories) not implementations
/// - Provides a clean interface for the presentation layer
class TransferController {
  // Singleton
  static final TransferController instance = TransferController._internal();
  factory TransferController() => instance;
  TransferController._internal();

  // State
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Dependencies (late initialized)
  late final DownloaderDataSource _dataSource;
  late final TransferRepositoryImpl _repository;
  late final FileCacheManager _cacheManager;

  // Use cases
  late final EnqueueDownloadUseCase _enqueueDownload;
  late final EnqueueParallelDownloadUseCase _enqueueParallelDownload;
  late final EnqueueUploadUseCase _enqueueUpload;
  late final PauseTransferUseCase _pauseTransfer;
  late final ResumeTransferUseCase _resumeTransfer;
  late final CancelTransferUseCase _cancelTransfer;
  late final GetTransferUseCase _getTransfer;
  late final GetAllTransfersUseCase _getAllTransfers;

  // Stream subscription
  StreamSubscription? _updatesSubscription;

  /// Initializes the controller with optional configuration.
  Future<void> initialize({
    bool skipExistingFiles = false,
    int? skipExistingFilesMinSize,
    bool runInForeground = false,
    Duration? requestTimeout,
  }) async {
    if (_isInitialized) return;

    // Initialize infrastructure
    await AppDirectory.init();
    _cacheManager = FileCacheManager.instance;
    await _cacheManager.initialize();

    // Initialize data source
    _dataSource = DownloaderDataSource();
    await _configureDataSource(
      skipExistingFiles: skipExistingFiles,
      skipExistingFilesMinSize: skipExistingFilesMinSize,
      runInForeground: runInForeground,
      requestTimeout: requestTimeout,
    );

    // Initialize repository
    _repository = TransferRepositoryImpl(
      dataSource: _dataSource,
      cacheManager: _cacheManager,
      hashUrl: (url) => url.toHashName(),
    );

    // Initialize use cases
    _enqueueDownload = EnqueueDownloadUseCase(_repository);
    _enqueueParallelDownload = EnqueueParallelDownloadUseCase(_repository);
    _enqueueUpload = EnqueueUploadUseCase(_repository);
    _pauseTransfer = PauseTransferUseCase(_repository);
    _resumeTransfer = ResumeTransferUseCase(_repository);
    _cancelTransfer = CancelTransferUseCase(_repository);
    _getTransfer = GetTransferUseCase(_repository);
    _getAllTransfers = GetAllTransfersUseCase(_repository);

    // Listen to updates
    _updatesSubscription = _dataSource.updates.listen(_repository.handleUpdate);

    // Start tracking
    await _dataSource.trackTasks();
    _dataSource.start();

    _isInitialized = true;
    debugPrint('TransferController: Initialized with Clean Architecture');
  }

  Future<void> _configureDataSource({
    bool skipExistingFiles = false,
    int? skipExistingFilesMinSize,
    bool runInForeground = false,
    Duration? requestTimeout,
  }) async {
    final globalConfig = <(dynamic, Object)>[];
    final androidConfig = <(dynamic, Object)>[];

    // This would use Config from background_downloader
    // Simplified for now

    if (globalConfig.isNotEmpty || androidConfig.isNotEmpty) {
      await _dataSource.configure(
        globalConfig: globalConfig.isNotEmpty ? globalConfig : null,
        androidConfig: androidConfig.isNotEmpty ? androidConfig : null,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Downloads a file.
  ///
  /// Returns a stream of transfer updates or an error.
  Future<Result<Stream<TransferEntity>>> download({
    required String url,
    String? fileName,
    String? directory,
    TransferConfigEntity? config,
  }) async {
    return _enqueueDownload(EnqueueDownloadParams(
      url: url,
      fileName: fileName,
      directory: directory,
      config: config,
    ));
  }

  /// Downloads a file in parallel chunks for faster speeds.
  Future<Result<Stream<TransferEntity>>> downloadParallel({
    required String url,
    List<String>? mirrorUrls,
    int chunks = 4,
    String? fileName,
    String? directory,
    TransferConfigEntity? config,
  }) async {
    return _enqueueParallelDownload(EnqueueParallelDownloadParams(
      url: url,
      mirrorUrls: mirrorUrls,
      chunks: chunks,
      fileName: fileName,
      directory: directory,
      config: config,
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPLOAD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Uploads a file.
  Future<Result<Stream<TransferEntity>>> upload({
    required String url,
    required String filePath,
    String? fileName,
    Map<String, String>? fields,
    TransferConfigEntity? config,
  }) async {
    return _enqueueUpload(EnqueueUploadParams(
      url: url,
      filePath: filePath,
      fileName: fileName,
      fields: fields,
      config: config,
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Pauses a transfer.
  Future<Result<bool>> pause(String transferId) => _pauseTransfer(transferId);

  /// Resumes a transfer.
  Future<Result<bool>> resume(String transferId) => _resumeTransfer(transferId);

  /// Cancels a transfer.
  Future<Result<bool>> cancel(String transferId) => _cancelTransfer(transferId);

  /// Retries a failed transfer.
  Future<Result<Stream<TransferEntity>>> retry(String transferId) =>
      _repository.retry(transferId);

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gets a transfer by ID.
  Future<Result<TransferEntity?>> getTransfer(String transferId) =>
      _getTransfer(transferId);

  /// Gets all transfers.
  Future<Result<List<TransferEntity>>> getAllTransfers() => _getAllTransfers();

  /// Gets transfers by status.
  Future<Result<List<TransferEntity>>> getTransfersByStatus(
          TransferStatusEntity status) =>
      _repository.getByStatus(status);

  /// Gets the cached path for a URL.
  Future<Result<String?>> getCachedPath(String url) =>
      _repository.getCachedPath(url);

  // ═══════════════════════════════════════════════════════════════════════════
  // DATABASE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Deletes a transfer record.
  Future<Result<void>> deleteTransfer(String transferId) =>
      _repository.delete(transferId);

  /// Deletes all transfer records.
  Future<Result<void>> deleteAllTransfers() => _repository.deleteAll();

  /// Reschedules missing tasks after crash.
  Future<Result<(List<TransferEntity>, List<TransferEntity>)>>
      rescheduleMissing() => _repository.rescheduleMissing();

  // ═══════════════════════════════════════════════════════════════════════════
  // FILE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Opens a completed file.
  Future<Result<bool>> openFile(String transferId) =>
      _repository.openFile(transferId);

  /// Moves a file to shared storage.
  Future<Result<String?>> moveToSharedStorage(
    String transferId, {
    String? directory,
    String? mimeType,
  }) =>
      _repository.moveToSharedStorage(
        transferId,
        directory: directory,
        mimeType: mimeType,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  /// Disposes the controller.
  void dispose() {
    _updatesSubscription?.cancel();
    _updatesSubscription = null;
    _repository.dispose();
    _cacheManager.dispose();
    _isInitialized = false;
    debugPrint('TransferController: Disposed');
  }
}
