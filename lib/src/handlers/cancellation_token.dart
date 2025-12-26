import 'dart:async';

import 'package:flutter/foundation.dart';

/// A token that can be used to request cancellation of an operation.
///
/// This class provides a way to signal that an operation should be cancelled,
/// and allows the operation to check whether cancellation has been requested.
///
/// Example usage:
/// ```dart
/// final token = CancellationToken();
///
/// // Start an operation
/// final result = uploadFile(file, cancellationToken: token);
///
/// // Later, cancel the operation
/// token.cancel();
/// ```
class CancellationToken {
  final _controller = StreamController<void>.broadcast();
  bool _isCancelled = false;
  String? _cancellationReason;
  final List<VoidCallback> _callbacks = [];

  /// Whether cancellation has been requested.
  bool get isCancelled => _isCancelled;

  /// The reason for cancellation, if provided.
  String? get cancellationReason => _cancellationReason;

  /// A stream that emits when cancellation is requested.
  Stream<void> get onCancelled => _controller.stream;

  /// Requests cancellation of the operation.
  ///
  /// [reason] is an optional string describing why the operation was cancelled.
  void cancel([String? reason]) {
    if (_isCancelled) return;

    _isCancelled = true;
    _cancellationReason = reason;
    _controller.add(null);

    // Call all registered callbacks
    for (final callback in _callbacks) {
      try {
        callback();
      } catch (e) {
        debugPrint('CancellationToken callback error: $e');
      }
    }
    _callbacks.clear();
  }

  /// Registers a callback to be called when cancellation is requested.
  ///
  /// Returns a function that can be called to unregister the callback.
  VoidCallback onCancel(VoidCallback callback) {
    if (_isCancelled) {
      // If already cancelled, call immediately
      callback();
      return () {};
    }

    _callbacks.add(callback);
    return () => _callbacks.remove(callback);
  }

  /// Throws a [CancellationException] if cancellation has been requested.
  void throwIfCancelled() {
    if (_isCancelled) {
      throw CancellationException(_cancellationReason);
    }
  }

  /// Returns a Future that completes when cancellation is requested.
  Future<void> get cancelled {
    if (_isCancelled) return Future.value();
    return _controller.stream.first;
  }

  /// Creates a linked token that will be cancelled when this token is cancelled.
  CancellationToken createLinked() {
    final linked = CancellationToken();
    onCancel(() => linked.cancel(_cancellationReason));
    return linked;
  }

  /// Disposes of the token and releases resources.
  void dispose() {
    _callbacks.clear();
    _controller.close();
  }
}

/// A token source that manages multiple [CancellationToken]s.
///
/// This is useful when you need to cancel multiple operations at once.
class CancellationTokenSource {
  final _tokens = <CancellationToken>[];
  bool _isCancelled = false;
  String? _cancellationReason;

  /// Whether all tokens have been cancelled.
  bool get isCancelled => _isCancelled;

  /// Creates and returns a new token managed by this source.
  CancellationToken createToken() {
    final token = CancellationToken();
    _tokens.add(token);

    // If source is already cancelled, cancel the new token
    if (_isCancelled) {
      token.cancel(_cancellationReason);
    }

    return token;
  }

  /// Cancels all tokens managed by this source.
  void cancelAll([String? reason]) {
    if (_isCancelled) return;

    _isCancelled = true;
    _cancellationReason = reason;

    for (final token in _tokens) {
      token.cancel(reason);
    }
  }

  /// Removes a token from management.
  void removeToken(CancellationToken token) {
    _tokens.remove(token);
  }

  /// Disposes of all tokens and the source.
  void dispose() {
    for (final token in _tokens) {
      token.dispose();
    }
    _tokens.clear();
  }
}

/// Exception thrown when an operation is cancelled.
class CancellationException implements Exception {
  /// The reason for cancellation.
  final String? reason;

  const CancellationException([this.reason]);

  @override
  String toString() {
    if (reason != null) {
      return 'CancellationException: $reason';
    }
    return 'CancellationException: Operation was cancelled';
  }
}

/// Extension methods for [Future] to support cancellation.
extension CancellableFuture<T> on Future<T> {
  /// Returns a Future that will complete with the result of this Future,
  /// or throw a [CancellationException] if the token is cancelled.
  Future<T> withCancellation(CancellationToken token) {
    if (token.isCancelled) {
      return Future.error(CancellationException(token.cancellationReason));
    }

    final completer = Completer<T>();
    final unregister = token.onCancel(() {
      if (!completer.isCompleted) {
        completer.completeError(
          CancellationException(token.cancellationReason),
        );
      }
    });

    then((value) {
      unregister();
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }).catchError((Object error, StackTrace stackTrace) {
      unregister();
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }
}

/// Extension methods for [Stream] to support cancellation.
extension CancellableStream<T> on Stream<T> {
  /// Returns a Stream that will emit events from this Stream,
  /// until the token is cancelled.
  Stream<T> withCancellation(CancellationToken token) {
    if (token.isCancelled) {
      return Stream.error(CancellationException(token.cancellationReason));
    }

    final controller = StreamController<T>();

    StreamSubscription<T>? subscription;

    final unregister = token.onCancel(() {
      subscription?.cancel();
      if (!controller.isClosed) {
        controller.addError(CancellationException(token.cancellationReason));
        controller.close();
      }
    });

    subscription = listen(
      (data) {
        if (!controller.isClosed) {
          controller.add(data);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      },
      onDone: () {
        unregister();
        if (!controller.isClosed) {
          controller.close();
        }
      },
    );

    controller.onCancel = () {
      unregister();
      subscription?.cancel();
    };

    return controller.stream;
  }
}
