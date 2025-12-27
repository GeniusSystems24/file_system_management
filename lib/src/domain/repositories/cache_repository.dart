import '../failures/failures.dart';
import 'transfer_repository.dart';

/// Repository interface for cache operations.
abstract class CacheRepository {
  /// Gets cached file path for a URL.
  Future<Result<String?>> get(String url);

  /// Stores a cached path for a URL.
  Future<Result<void>> put(String url, String path, {int? fileSize});

  /// Removes a cached entry.
  Future<Result<void>> remove(String url);

  /// Clears all cached entries.
  Future<Result<void>> clear();

  /// Checks if a URL is cached.
  Future<Result<bool>> contains(String url);

  /// Gets cache statistics.
  Future<Result<CacheStats>> getStats();

  /// Cleans stale cache entries.
  Future<Result<int>> cleanStale({Duration? maxAge});
}

/// Cache statistics.
class CacheStats {
  final int totalEntries;
  final int totalSizeBytes;
  final DateTime? oldestEntry;
  final DateTime? newestEntry;

  const CacheStats({
    required this.totalEntries,
    required this.totalSizeBytes,
    this.oldestEntry,
    this.newestEntry,
  });
}
