import 'dart:async';
import 'dart:collection';

/// A simple mutex implementation for preventing race conditions.
/// Used to ensure only one task with a given URL is processed at a time.
class TaskMutex {
  final _locks = HashMap<String, Completer<void>>();
  final _pendingCounts = HashMap<String, int>();

  /// Acquires a lock for the given [key].
  /// If another operation is already in progress for this key,
  /// this will wait until that operation completes.
  Future<void> acquire(String key) async {
    while (_locks.containsKey(key)) {
      _pendingCounts[key] = (_pendingCounts[key] ?? 0) + 1;
      try {
        await _locks[key]!.future;
      } finally {
        final count = (_pendingCounts[key] ?? 1) - 1;
        if (count <= 0) {
          _pendingCounts.remove(key);
        } else {
          _pendingCounts[key] = count;
        }
      }
    }
    _locks[key] = Completer<void>();
  }

  /// Releases the lock for the given [key].
  void release(String key) {
    final completer = _locks.remove(key);
    completer?.complete();
  }

  /// Executes [action] while holding the lock for [key].
  /// Ensures the lock is released even if an exception occurs.
  Future<T> synchronized<T>(String key, Future<T> Function() action) async {
    await acquire(key);
    try {
      return await action();
    } finally {
      release(key);
    }
  }

  /// Checks if a lock is currently held for [key].
  bool isLocked(String key) => _locks.containsKey(key);

  /// Returns the number of pending operations waiting for [key].
  int pendingCount(String key) => _pendingCounts[key] ?? 0;

  /// Clears all locks. Use with caution.
  void clear() {
    for (final completer in _locks.values) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _locks.clear();
    _pendingCounts.clear();
  }
}

/// Global mutex instance for task operations.
final taskMutex = TaskMutex();
