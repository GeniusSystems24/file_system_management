import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../storage/app_directory.dart';
import '../../core/extensions/file_path_extension.dart';

/// Entry in the file cache containing file metadata.
class FileCacheEntry {
  /// The original URL of the file.
  final String url;

  /// The local file path.
  final String localPath;

  /// When this entry was created.
  final DateTime createdAt;

  /// When this entry was last accessed.
  DateTime lastAccessedAt;

  /// File size in bytes (optional).
  final int? fileSize;

  FileCacheEntry({
    required this.url,
    required this.localPath,
    required this.createdAt,
    required this.lastAccessedAt,
    this.fileSize,
  });

  /// Creates a new entry from URL and path.
  factory FileCacheEntry.create(String url, String localPath, {int? fileSize}) {
    final now = DateTime.now();
    return FileCacheEntry(
      url: url,
      localPath: localPath,
      createdAt: now,
      lastAccessedAt: now,
      fileSize: fileSize,
    );
  }

  /// Updates the last accessed time.
  void touch() => lastAccessedAt = DateTime.now();

  /// Checks if the cached file still exists.
  Future<bool> exists() async => File(localPath).exists();

  /// Synchronous check if file exists.
  bool existsSync() => File(localPath).existsSync();

  Map<String, dynamic> toJson() => {
        'url': url,
        'localPath': localPath,
        'createdAt': createdAt.toIso8601String(),
        'lastAccessedAt': lastAccessedAt.toIso8601String(),
        'fileSize': fileSize,
      };

  factory FileCacheEntry.fromJson(Map<String, dynamic> json) {
    return FileCacheEntry(
      url: json['url'] as String,
      localPath: json['localPath'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastAccessedAt: DateTime.parse(json['lastAccessedAt'] as String),
      fileSize: json['fileSize'] as int?,
    );
  }
}

/// Result of a cache lookup operation.
sealed class CacheLookupResult {}

/// File was found in cache and exists on disk.
class CacheHit extends CacheLookupResult {
  final FileCacheEntry entry;
  CacheHit(this.entry);
}

/// File was not found in cache.
class CacheMiss extends CacheLookupResult {}

/// File was in cache but the file no longer exists on disk.
class CacheStale extends CacheLookupResult {
  final FileCacheEntry entry;
  CacheStale(this.entry);
}

/// Manages the file cache with URL-to-path mapping.
///
/// Features:
/// - In-memory cache for fast lookups
/// - Automatic stale entry cleanup
/// - LRU-based eviction when cache is full
/// - Thread-safe operations
class FileCacheManager {
  static FileCacheManager? _instance;
  static FileCacheManager get instance => _instance ??= FileCacheManager._();

  FileCacheManager._();

  /// Maximum number of entries in the cache.
  static const int maxCacheEntries = 1000;

  /// In-memory cache: URL -> FileCacheEntry
  final Map<String, FileCacheEntry> _cache = {};

  /// Reverse lookup: local path -> URL (for uploaded files)
  final Map<String, String> _pathToUrl = {};

  bool _isInitialized = false;

  /// Initializes the cache manager.
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint('FileCacheManager: Initialized');
  }

  /// Gets the cached path for a URL if it exists.
  Future<String?> get(String url) async {
    final result = await lookup(url);
    return switch (result) {
      CacheHit(:final entry) => entry.localPath,
      _ => null,
    };
  }

  /// Looks up a URL in the cache.
  Future<CacheLookupResult> lookup(String url) async {
    final entry = _cache[url];
    if (entry == null) return CacheMiss();

    // Verify file still exists
    if (await entry.exists()) {
      entry.touch();
      return CacheHit(entry);
    }

    // File was deleted externally
    return CacheStale(entry);
  }

  /// Synchronous lookup - doesn't verify file existence.
  FileCacheEntry? lookupSync(String url) => _cache[url];

  /// Gets the cached path for a URL if it exists.
  String? getPath(String url) => _cache[url]?.localPath;

  /// Gets the URL for a local path (useful for uploaded files).
  String? getUrlForPath(String path) => _pathToUrl[path];

  /// Adds a file to the cache.
  void put(String url, String localPath, {int? fileSize}) {
    // Enforce cache size limit
    _enforceLimit();

    final entry = FileCacheEntry.create(url, localPath, fileSize: fileSize);
    _cache[url] = entry;
    _pathToUrl[localPath] = url;
  }

  /// Removes a URL from the cache.
  void remove(String url) {
    final entry = _cache.remove(url);
    if (entry != null) {
      _pathToUrl.remove(entry.localPath);
    }
  }

  /// Removes a path from the cache.
  void removeByPath(String path) {
    final url = _pathToUrl.remove(path);
    if (url != null) {
      _cache.remove(url);
    }
  }

  /// Checks if a URL is in the cache.
  bool contains(String url) => _cache.containsKey(url);

  /// Checks if a local path is in the cache.
  bool containsPath(String path) => _pathToUrl.containsKey(path);

  /// Gets the expected cache path for a URL.
  String getCachePathForUrl(String url, {String? directory}) {
    final hashName = url.toHashName();
    if (directory != null && directory.isNotEmpty) {
      return '${AppDirectory.instance.cachedDir!.path}/$directory/$hashName';
    }
    return '${AppDirectory.instance.cachedDir!.path}/$hashName';
  }

  /// Cleans up stale entries (files that no longer exist).
  Future<int> cleanStaleEntries() async {
    int cleaned = 0;
    final toRemove = <String>[];

    for (final entry in _cache.entries) {
      if (!await entry.value.exists()) {
        toRemove.add(entry.key);
        cleaned++;
      }
    }

    for (final url in toRemove) {
      remove(url);
    }

    if (cleaned > 0) {
      debugPrint('FileCacheManager: Cleaned $cleaned stale entries');
    }
    return cleaned;
  }

  /// Enforces cache size limit using LRU eviction.
  void _enforceLimit() {
    if (_cache.length < maxCacheEntries) return;

    // Find least recently used entries
    final sorted = _cache.entries.toList()
      ..sort(
          (a, b) => a.value.lastAccessedAt.compareTo(b.value.lastAccessedAt));

    // Remove oldest 10% of entries
    final removeCount = (maxCacheEntries * 0.1).ceil();
    for (int i = 0; i < removeCount && i < sorted.length; i++) {
      remove(sorted[i].key);
    }
  }

  /// Clears the entire cache.
  void clear() {
    _cache.clear();
    _pathToUrl.clear();
  }

  /// Gets cache statistics.
  Map<String, dynamic> getStats() => {
        'entries': _cache.length,
        'maxEntries': maxCacheEntries,
        'pathMappings': _pathToUrl.length,
      };

  /// Number of entries in the cache.
  int get length => _cache.length;

  /// Disposes the cache manager.
  void dispose() {
    clear();
    _isInitialized = false;
  }
}

/// Global cache manager instance.
final fileCacheManager = FileCacheManager.instance;
