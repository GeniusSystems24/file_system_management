import 'dart:async';

import 'package:background_downloader/background_downloader.dart';

import '../../domain/entities/entities.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/repositories.dart';
import '../../infrastructure/cache/file_cache_manager.dart';
import '../datasources/datasources.dart';
import '../models/models.dart';

/// Implementation of [TransferRepository] using background_downloader.
class TransferRepositoryImpl implements TransferRepository {
  final DownloaderDataSource _dataSource;
  final FileCacheManager _cacheManager;
  final String Function(String url) _hashUrl;

  // Active transfers tracking
  final Map<String, TransferModel> _activeTransfers = {};
  final Map<String, StreamController<TransferEntity>> _controllers = {};
  final Set<String> _activeUrls = {};

  TransferRepositoryImpl({
    required DownloaderDataSource dataSource,
    required FileCacheManager cacheManager,
    required String Function(String url) hashUrl,
  })  : _dataSource = dataSource,
        _cacheManager = cacheManager,
        _hashUrl = hashUrl;

  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Result<Stream<TransferEntity>>> enqueueDownload({
    required String url,
    String? fileName,
    String? directory,
    TransferConfigEntity? config,
  }) async {
    try {
      // Check cache
      final cached = await _cacheManager.get(url);
      if (cached != null) {
        return Success(Stream.value(_createCompletedEntity(url, cached)));
      }

      // Check if already in progress
      if (_activeUrls.contains(url)) {
        final controller = _getOrCreateController(url);
        return Success(controller.stream);
      }

      _activeUrls.add(url);

      final task = DownloadTask(
        url: url,
        filename: fileName ?? _hashUrl(url),
        directory: directory ?? '',
        baseDirectory: BaseDirectory.temporary,
        allowPause: config?.allowResume ?? true,
        updates: Updates.statusAndProgress,
        headers: config?.headers ?? {},
        priority: 5,
        requiresWiFi: false,
        retries: config?.maxRetries ?? 0,
      );

      await _dataSource.enqueue(task);

      final controller = _getOrCreateController(url);
      return Success(controller.stream);
    } catch (e, st) {
      _activeUrls.remove(url);
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<Stream<TransferEntity>>> enqueueParallelDownload({
    required String url,
    List<String>? mirrorUrls,
    int chunks = 4,
    String? fileName,
    String? directory,
    TransferConfigEntity? config,
  }) async {
    try {
      // Check cache
      final cached = await _cacheManager.get(url);
      if (cached != null) {
        return Success(Stream.value(_createCompletedEntity(url, cached)));
      }

      if (_activeUrls.contains(url)) {
        final controller = _getOrCreateController(url);
        return Success(controller.stream);
      }

      _activeUrls.add(url);

      final task = ParallelDownloadTask(
        url: url,
        urls: mirrorUrls,
        chunks: chunks,
        filename: fileName ?? _hashUrl(url),
        directory: directory ?? '',
        baseDirectory: BaseDirectory.temporary,
        updates: Updates.statusAndProgress,
        headers: config?.headers ?? {},
        priority: 5,
        requiresWiFi: false,
        retries: config?.maxRetries ?? 0,
      );

      await _dataSource.enqueue(task);

      final controller = _getOrCreateController(url);
      return Success(controller.stream);
    } catch (e, st) {
      _activeUrls.remove(url);
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPLOAD OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Result<Stream<TransferEntity>>> enqueueUpload({
    required String url,
    required String filePath,
    String? fileName,
    Map<String, String>? fields,
    TransferConfigEntity? config,
  }) async {
    try {
      if (_activeUrls.contains(url)) {
        final controller = _getOrCreateController(url);
        return Success(controller.stream);
      }

      _activeUrls.add(url);

      final task = UploadTask(
        url: url,
        filename: fileName ?? filePath.split('/').last,
        updates: Updates.statusAndProgress,
        headers: config?.headers ?? {},
        fields: fields ?? {},
        priority: 5,
        retries: config?.maxRetries ?? 0,
      );

      await _dataSource.enqueue(task);

      final controller = _getOrCreateController(url);
      return Success(controller.stream);
    } catch (e, st) {
      _activeUrls.remove(url);
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<Stream<TransferEntity>>> enqueueBinaryUpload({
    required String url,
    required String filePath,
    String? mimeType,
    TransferConfigEntity? config,
  }) async {
    try {
      if (_activeUrls.contains(url)) {
        final controller = _getOrCreateController(url);
        return Success(controller.stream);
      }

      _activeUrls.add(url);

      final task = UploadTask(
        url: url,
        filename: filePath.split('/').last,
        updates: Updates.statusAndProgress,
        headers: config?.headers ?? {},
        httpRequestMethod: 'PUT',
        mimeType: mimeType ?? 'application/octet-stream',
        post: 'binary',
        priority: 5,
        retries: config?.maxRetries ?? 0,
      );

      await _dataSource.enqueue(task);

      final controller = _getOrCreateController(url);
      return Success(controller.stream);
    } catch (e, st) {
      _activeUrls.remove(url);
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<Stream<TransferEntity>>> enqueueMultiUpload({
    required String url,
    required List<(String fieldName, String filePath)> files,
    Map<String, String>? fields,
    TransferConfigEntity? config,
  }) async {
    try {
      if (_activeUrls.contains(url)) {
        final controller = _getOrCreateController(url);
        return Success(controller.stream);
      }

      _activeUrls.add(url);

      final task = MultiUploadTask(
        url: url,
        files: files,
        updates: Updates.statusAndProgress,
        headers: config?.headers ?? {},
        fields: fields ?? {},
        priority: 5,
        retries: config?.maxRetries ?? 0,
      );

      await _dataSource.enqueue(task);

      final controller = _getOrCreateController(url);
      return Success(controller.stream);
    } catch (e, st) {
      _activeUrls.remove(url);
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROL OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Result<bool>> pause(String transferId) async {
    try {
      final task = await _dataSource.taskForId(transferId);
      if (task is DownloadTask) {
        final result = await _dataSource.pause(task);
        return Success(result);
      }
      return const Success(false);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<bool>> resume(String transferId) async {
    try {
      final task = await _dataSource.taskForId(transferId);
      if (task is DownloadTask) {
        final result = await _dataSource.resume(task);
        return Success(result);
      }
      return const Success(false);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<bool>> cancel(String transferId) async {
    try {
      final result = await _dataSource.cancelTaskWithId(transferId);
      if (result) {
        final model = _activeTransfers.values
            .where((m) => m.task.taskId == transferId)
            .firstOrNull;
        if (model != null) {
          _activeUrls.remove(model.task.url);
        }
      }
      return Success(result);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<Stream<TransferEntity>>> retry(String transferId) async {
    try {
      final model = _activeTransfers.values
          .where((m) => m.task.taskId == transferId)
          .firstOrNull;
      if (model == null) {
        return const Fail(FileNotFoundFailure(filePath: 'Transfer not found'));
      }

      _activeUrls.remove(model.task.url);

      if (model.task is DownloadTask) {
        return enqueueDownload(url: model.task.url);
      } else if (model.task is UploadTask) {
        return enqueueUpload(
          url: model.task.url,
          filePath: model.task.filename,
        );
      }

      return const Fail(
          UnknownFailure(message: 'Unknown task type', code: 'UNKNOWN_TYPE'));
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<bool>> resumeFailed(String transferId) async {
    try {
      final task = await _dataSource.taskForId(transferId);
      if (task is DownloadTask) {
        final result = await _dataSource.resume(task);
        if (result) {
          _activeUrls.add(task.url);
        }
        return Success(result);
      }
      return const Success(false);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BATCH OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Result<List<bool>>> pauseAll(List<String> transferIds) async {
    try {
      final results = await Future.wait(
        transferIds.map((id) async {
          final result = await pause(id);
          return result.valueOrNull ?? false;
        }),
      );
      return Success(results);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<List<bool>>> resumeAll(List<String> transferIds) async {
    try {
      final results = await Future.wait(
        transferIds.map((id) async {
          final result = await resume(id);
          return result.valueOrNull ?? false;
        }),
      );
      return Success(results);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<bool>> cancelAll(List<String> transferIds) async {
    try {
      final result = await _dataSource.cancelTasksWithIds(transferIds);
      return Success(result);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // QUERY OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Result<TransferEntity?>> getById(String transferId) async {
    try {
      final record = await _dataSource.recordForId(transferId);
      if (record == null) return const Success(null);

      final model = TransferModel.fromRecord(record);
      return Success(model.toEntity());
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<List<TransferEntity>>> getAll() async {
    try {
      final records = await _dataSource.allRecords();
      final entities =
          records.map((r) => TransferModel.fromRecord(r).toEntity()).toList();
      return Success(entities);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<List<TransferEntity>>> getByStatus(
      TransferStatusEntity status) async {
    try {
      final taskStatus = _mapStatusToTaskStatus(status);
      final records = await _dataSource.allRecordsWithStatus(taskStatus);
      final entities =
          records.map((r) => TransferModel.fromRecord(r).toEntity()).toList();
      return Success(entities);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<List<TransferEntity>>> getByGroup(String group) async {
    try {
      final tasks = await _dataSource.allTasks(group: group);
      final entities =
          tasks.map((t) => TransferModel.fromTask(t).toEntity()).toList();
      return Success(entities);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<String?>> getCachedPath(String url) async {
    try {
      final path = await _cacheManager.get(url);
      return Success(path);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATABASE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Result<void>> delete(String transferId) async {
    try {
      await _dataSource.deleteRecordWithId(transferId);
      return const Success(null);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<void>> deleteAll() async {
    try {
      await _dataSource.deleteAllRecords();
      return const Success(null);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<void>> deleteByStatus(TransferStatusEntity status) async {
    try {
      final taskStatus = _mapStatusToTaskStatus(status);
      await _dataSource.deleteRecordsWithStatus(taskStatus);
      return const Success(null);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECOVERY OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Result<(List<TransferEntity>, List<TransferEntity>)>>
      rescheduleMissing() async {
    try {
      final (succeeded, failed) = await _dataSource.rescheduleMissingTasks();
      return Success((
        succeeded.map((t) => TransferModel.fromTask(t).toEntity()).toList(),
        failed.map((t) => TransferModel.fromTask(t).toEntity()).toList(),
      ));
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILE OPERATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Result<bool>> openFile(String transferId) async {
    try {
      final task = await _dataSource.taskForId(transferId);
      if (task != null) {
        final result = await _dataSource.openFile(task: task);
        return Success(result);
      }
      return const Success(false);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<String?>> moveToSharedStorage(
    String transferId, {
    String? directory,
    String? mimeType,
  }) async {
    try {
      final task = await _dataSource.taskForId(transferId);
      if (task is DownloadTask) {
        final result = await _dataSource.moveToSharedStorage(
          task,
          SharedStorage.downloads,
          directory: directory ?? '',
          mimeType: mimeType,
        );
        return Success(result);
      }
      return const Success(null);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  @override
  Future<Result<bool>> openFileByPath(String filePath,
      {String? mimeType}) async {
    try {
      final result =
          await _dataSource.openFile(filePath: filePath, mimeType: mimeType);
      return Success(result);
    } catch (e, st) {
      return Fail(UnknownFailure(
        message: e.toString(),
        exception: e,
        stackTrace: st,
      ));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  StreamController<TransferEntity> _getOrCreateController(String url) {
    return _controllers.putIfAbsent(
      url,
      () => StreamController<TransferEntity>.broadcast(),
    );
  }

  TransferEntity _createCompletedEntity(String url, String filePath) {
    return TransferEntity(
      id: url,
      url: url,
      filePath: filePath,
      fileName: filePath.split('/').last,
      type: TransferTypeEntity.download,
      status: TransferStatusEntity.complete,
      progress: 1.0,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
  }

  TaskStatus _mapStatusToTaskStatus(TransferStatusEntity status) {
    return switch (status) {
      TransferStatusEntity.pending => TaskStatus.enqueued,
      TransferStatusEntity.running => TaskStatus.running,
      TransferStatusEntity.paused => TaskStatus.paused,
      TransferStatusEntity.complete => TaskStatus.complete,
      TransferStatusEntity.failed => TaskStatus.failed,
      TransferStatusEntity.canceled => TaskStatus.canceled,
      TransferStatusEntity.waitingToRetry => TaskStatus.waitingToRetry,
      TransferStatusEntity.notFound => TaskStatus.notFound,
    };
  }

  /// Handles a task update.
  void handleUpdate(TaskUpdate update) {
    final url = update.task.url;
    var model = _activeTransfers[url];

    if (model != null) {
      model = model.updateFrom(update);
    } else {
      model = TransferModel.fromUpdate(update);
    }

    _activeTransfers[url] = model;
    _controllers[url]?.add(model.toEntity());

    // Handle completion
    if (model.status == TaskStatus.complete) {
      _activeUrls.remove(url);
      _cacheManager.put(url, model.toEntity().filePath);
    }

    // Handle failure/cancellation
    if (model.status == TaskStatus.failed ||
        model.status == TaskStatus.canceled) {
      _activeUrls.remove(url);
    }
  }

  /// Disposes resources.
  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _activeTransfers.clear();
    _activeUrls.clear();
  }
}
