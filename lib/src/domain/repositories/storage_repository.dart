import 'transfer_repository.dart';

/// Repository interface for storage operations.
abstract class StorageRepository {
  /// Gets available storage space in bytes.
  Future<Result<int?>> getAvailableSpace({String? directory});

  /// Checks if a path is in shared storage.
  Future<Result<bool>> isInSharedStorage(String path);

  /// Gets the path for a base directory.
  Future<Result<String>> getDirectoryPath(StorageDirectory directory);

  /// Creates a directory if it doesn't exist.
  Future<Result<void>> ensureDirectory(String path);

  /// Deletes a file.
  Future<Result<void>> deleteFile(String path);

  /// Checks if a file exists.
  Future<Result<bool>> fileExists(String path);

  /// Gets file size.
  Future<Result<int>> getFileSize(String path);
}

/// Storage directory types.
enum StorageDirectory {
  temporary,
  applicationDocuments,
  applicationSupport,
  downloads,
  external,
}
