import 'dart:async';
import 'dart:ui';

import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:flutter/material.dart';

import '../../handlers/cancellation_token.dart';
import '../../handlers/transfer_handler.dart';
import '../../handlers/transfer_progress.dart';
import '../../handlers/transfer_result.dart';
import '../../theme/social_transfer_theme.dart';

/// The current state of a transfer widget.
enum TransferWidgetState {
  /// Initial state - no transfer started.
  idle,

  /// Transfer is pending/queued.
  pending,

  /// Transfer is in progress.
  transferring,

  /// Transfer is paused.
  paused,

  /// Transfer completed successfully.
  completed,

  /// Transfer failed.
  failed,

  /// Transfer was cancelled.
  cancelled,
}

/// Direction of the message bubble.
enum BubbleDirection {
  /// Incoming message (from others).
  incoming,

  /// Outgoing message (from user).
  outgoing,
}

/// Configuration for a transfer widget.
class TransferWidgetConfig {
  /// Whether to auto-start the transfer.
  final bool autoStart;

  /// Whether to show the action button.
  final bool showActionButton;

  /// Whether to show progress percentage.
  final bool showProgress;

  /// Whether to show transfer speed.
  final bool showSpeed;

  /// Whether to show file size.
  final bool showFileSize;

  /// Whether to show estimated time remaining.
  final bool showEta;

  /// Whether pause/resume is enabled.
  final bool allowPauseResume;

  /// Whether retry is enabled.
  final bool allowRetry;

  /// Whether cancel is enabled.
  final bool allowCancel;

  /// Whether to show linear progress bar.
  final bool showLinearProgress;

  /// Custom action button size.
  final double? actionButtonSize;

  /// Direction of the bubble.
  final BubbleDirection direction;

  const TransferWidgetConfig({
    this.autoStart = false,
    this.showActionButton = true,
    this.showProgress = true,
    this.showSpeed = true,
    this.showFileSize = true,
    this.showEta = false,
    this.allowPauseResume = true,
    this.allowRetry = true,
    this.allowCancel = true,
    this.showLinearProgress = true,
    this.actionButtonSize,
    this.direction = BubbleDirection.outgoing,
  });

  /// Creates a copy with updated values.
  TransferWidgetConfig copyWith({
    bool? autoStart,
    bool? showActionButton,
    bool? showProgress,
    bool? showSpeed,
    bool? showFileSize,
    bool? showEta,
    bool? allowPauseResume,
    bool? allowRetry,
    bool? allowCancel,
    bool? showLinearProgress,
    double? actionButtonSize,
    BubbleDirection? direction,
  }) {
    return TransferWidgetConfig(
      autoStart: autoStart ?? this.autoStart,
      showActionButton: showActionButton ?? this.showActionButton,
      showProgress: showProgress ?? this.showProgress,
      showSpeed: showSpeed ?? this.showSpeed,
      showFileSize: showFileSize ?? this.showFileSize,
      showEta: showEta ?? this.showEta,
      allowPauseResume: allowPauseResume ?? this.allowPauseResume,
      allowRetry: allowRetry ?? this.allowRetry,
      allowCancel: allowCancel ?? this.allowCancel,
      showLinearProgress: showLinearProgress ?? this.showLinearProgress,
      actionButtonSize: actionButtonSize ?? this.actionButtonSize,
      direction: direction ?? this.direction,
    );
  }
}

/// Base class for message transfer widgets.
///
/// This provides common functionality for all transfer widgets including:
/// - State management
/// - Progress tracking
/// - Theme integration
/// - Custom handler support
abstract class BaseMessageTransferWidget extends StatefulWidget {
  /// Configuration for the widget.
  final TransferWidgetConfig config;

  /// Custom upload handler.
  final UploadHandler? uploadHandler;

  /// Custom download handler.
  final DownloadHandler? downloadHandler;

  /// URL for the transfer.
  final String? url;

  /// Local file path.
  final String? filePath;

  /// File name.
  final String? fileName;

  /// File size in bytes.
  final int? fileSize;

  /// MIME type.
  final String? mimeType;

  /// Initial state of the widget.
  final TransferWidgetState? initialState;

  /// Callback for upload.
  final Stream<TransferProgress> Function(UploadPayload payload)? onUpload;

  /// Callback for download.
  final Stream<TransferProgress> Function(DownloadPayload payload)? onDownload;

  /// Callback for retry.
  final Stream<TransferProgress> Function()? onRetry;

  /// Callback for cancel.
  final Future<bool> Function()? onCancel;

  /// Callback for pause.
  final Future<bool> Function()? onPause;

  /// Callback for resume.
  final Future<bool> Function()? onResume;

  /// Callback for open (after completion).
  final Future<void> Function(String path)? onOpen;

  /// Callback for get URL.
  final Future<String> Function()? onGetUrl;

  /// Cancellation token for the transfer.
  final CancellationToken? cancellationToken;

  /// Transfer configuration.
  final TransferConfig? transferConfig;

  /// Called when transfer starts.
  final VoidCallback? onTransferStart;

  /// Called when transfer completes.
  final void Function(TransferResult result)? onTransferComplete;

  /// Called when transfer fails.
  final void Function(TransferFailure failure)? onTransferError;

  /// Called when progress updates.
  final void Function(TransferProgress progress)? onProgressUpdate;

  /// Custom theme data.
  final SocialTransferThemeData? themeData;

  const BaseMessageTransferWidget({
    super.key,
    this.config = const TransferWidgetConfig(),
    this.uploadHandler,
    this.downloadHandler,
    this.url,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.initialState,
    this.onUpload,
    this.onDownload,
    this.onRetry,
    this.onCancel,
    this.onPause,
    this.onResume,
    this.onOpen,
    this.onGetUrl,
    this.cancellationToken,
    this.transferConfig,
    this.onTransferStart,
    this.onTransferComplete,
    this.onTransferError,
    this.onProgressUpdate,
    this.themeData,
  });
}

/// Base state class for message transfer widgets.
abstract class BaseMessageTransferWidgetState<
  T extends BaseMessageTransferWidget
>
    extends State<T>
    with SingleTickerProviderStateMixin {
  /// Current state of the widget.
  TransferWidgetState _state = TransferWidgetState.idle;
  TransferWidgetState get state => _state;

  /// Current progress.
  TransferProgress _progress = TransferProgress.initial();
  TransferProgress get progress => _progress;

  /// Error message if failed.
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Result file path after completion.
  String? _resultPath;
  String? get resultPath => _resultPath;

  /// Stream subscription for progress updates.
  StreamSubscription<TransferProgress>? _progressSubscription;

  /// Internal cancellation token.
  CancellationToken? _internalToken;
  CancellationToken get _token =>
      widget.cancellationToken ?? (_internalToken ??= CancellationToken());

  /// Animation controller for state transitions.
  late AnimationController _animationController;
  AnimationController get animationController => _animationController;

  /// Gets the current theme.
  SocialTransferThemeData get theme =>
      widget.themeData ??
      Theme.of(context).extension<SocialTransferThemeData>() ??
      SocialTransferThemeData.of(context);

  /// Gets the effective action button size.
  double get actionButtonSize =>
      widget.config.actionButtonSize ?? theme.actionButtonSize;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 300,
      ), // Default, updated in didChangeDependencies
    );

    if (widget.initialState != null) {
      _state = widget.initialState!;
    }

    // If there's already a local file, consider it completed
    if (widget.filePath != null && widget.initialState == null) {
      _state = TransferWidgetState.completed;
      _resultPath = widget.filePath;
    }

    // Auto-start if configured
    if (widget.config.autoStart && _state == TransferWidgetState.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startTransfer();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update animation duration from theme (can't be done in initState)
    _animationController.duration = theme.stateAnimationDuration;
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _internalToken?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Starts the transfer.
  Future<void> startTransfer() async {
    if (_state == TransferWidgetState.transferring) return;

    setState(() {
      _state = TransferWidgetState.transferring;
      _progress = TransferProgress.initial(totalBytes: widget.fileSize ?? -1);
      _errorMessage = null;
    });

    widget.onTransferStart?.call();

    try {
      Stream<TransferProgress>? stream;

      // Try custom callbacks first
      if (isUpload && widget.onUpload != null) {
        stream = widget.onUpload!(
          UploadPayload(
            filePath: widget.filePath,
            fileName: widget.fileName ?? 'file',
            fileSize: widget.fileSize,
            mimeType: widget.mimeType,
          ),
        );
      } else if (!isUpload && widget.onDownload != null) {
        final url = await _getUrl();
        stream = widget.onDownload!(
          DownloadPayload(
            url: url,
            destinationPath: widget.filePath,
            fileName: widget.fileName,
            expectedSize: widget.fileSize,
          ),
        );
      }
      // Fall back to handlers
      else if (isUpload && widget.uploadHandler != null) {
        final url = widget.url ?? await _getUrl();
        stream = widget.uploadHandler!.upload(
          url,
          UploadPayload(
            filePath: widget.filePath,
            fileName: widget.fileName ?? 'file',
            fileSize: widget.fileSize,
            mimeType: widget.mimeType,
          ),
          config: widget.transferConfig,
          cancellationToken: _token,
        );
      } else if (!isUpload && widget.downloadHandler != null) {
        final url = widget.url ?? await _getUrl();
        stream = widget.downloadHandler!.download(
          DownloadPayload(
            url: url,
            destinationPath: widget.filePath,
            fileName: widget.fileName,
            expectedSize: widget.fileSize,
          ),
          config: widget.transferConfig,
          cancellationToken: _token,
        );
      }

      if (stream != null) {
        _progressSubscription?.cancel();
        _progressSubscription = stream.listen(
          _handleProgress,
          onError: _handleError,
          onDone: _handleDone,
        );
      } else {
        // No handler available - simulate for demo
        await _simulateTransfer();
      }
    } catch (e) {
      _handleError(e);
    }
  }

  /// Gets the URL for the transfer.
  Future<String> _getUrl() async {
    if (widget.url != null) return widget.url!;
    if (widget.onGetUrl != null) return await widget.onGetUrl!();
    throw StateError('No URL available');
  }

  /// Handles progress updates.
  void _handleProgress(TransferProgress progress) {
    if (!mounted) return;

    setState(() {
      _progress = progress;

      if (progress.isCompleted) {
        _state = TransferWidgetState.completed;
        _resultPath = widget.filePath;
      } else if (progress.isFailed) {
        _state = TransferWidgetState.failed;
        _errorMessage = progress.errorMessage;
      } else if (progress.isPaused) {
        _state = TransferWidgetState.paused;
      } else if (progress.isCancelled) {
        _state = TransferWidgetState.cancelled;
      } else {
        _state = TransferWidgetState.transferring;
      }
    });

    widget.onProgressUpdate?.call(progress);

    if (progress.isCompleted) {
      widget.onTransferComplete?.call(
        TransferSuccess(
          localPath: _resultPath ?? widget.filePath ?? '',
          remoteUrl: widget.url,
          fileSize: widget.fileSize,
        ),
      );
    }
  }

  /// Handles errors.
  void _handleError(Object error) {
    if (!mounted) return;

    final failure =
        error is TransferFailure
            ? error
            : TransferFailure(message: error.toString());

    setState(() {
      _state = TransferWidgetState.failed;
      _errorMessage = failure.message;
    });

    widget.onTransferError?.call(failure);
  }

  /// Handles stream completion.
  void _handleDone() {
    if (!mounted) return;

    if (_state == TransferWidgetState.transferring) {
      // Stream ended without explicit completion
      if (_progress.progress >= 1.0) {
        setState(() {
          _state = TransferWidgetState.completed;
          _resultPath = widget.filePath;
        });
      }
    }
  }

  /// Simulates a transfer for demo purposes.
  Future<void> _simulateTransfer() async {
    const duration = Duration(seconds: 3);
    const steps = 20;
    final stepDuration = duration ~/ steps;
    final totalBytes = widget.fileSize ?? 1024 * 1024;

    for (int i = 1; i <= steps; i++) {
      if (!mounted || _token.isCancelled) break;

      await Future.delayed(stepDuration);

      if (_state == TransferWidgetState.paused) {
        while (_state == TransferWidgetState.paused && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      final bytesTransferred = (totalBytes * i / steps).round();
      _handleProgress(
        TransferProgress(
          bytesTransferred: bytesTransferred,
          totalBytes: totalBytes,
          bytesPerSecond: totalBytes / duration.inSeconds,
          estimatedTimeRemaining: Duration(
            milliseconds: ((steps - i) * stepDuration.inMilliseconds),
          ),
          status:
              i == steps ? TransferStatus.completed : TransferStatus.running,
        ),
      );
    }
  }

  /// Pauses the transfer.
  Future<void> pauseTransfer() async {
    if (!widget.config.allowPauseResume) return;
    if (_state != TransferWidgetState.transferring) return;

    if (widget.onPause != null) {
      final success = await widget.onPause!();
      if (!success) return;
    }

    setState(() {
      _state = TransferWidgetState.paused;
    });
  }

  /// Resumes the transfer.
  Future<void> resumeTransfer() async {
    if (!widget.config.allowPauseResume) return;
    if (_state != TransferWidgetState.paused) return;

    if (widget.onResume != null) {
      final success = await widget.onResume!();
      if (!success) return;
    }

    setState(() {
      _state = TransferWidgetState.transferring;
    });
  }

  /// Cancels the transfer.
  Future<void> cancelTransfer() async {
    if (!widget.config.allowCancel) return;

    if (widget.onCancel != null) {
      await widget.onCancel!();
    }

    _token.cancel('User cancelled');
    _progressSubscription?.cancel();

    setState(() {
      _state = TransferWidgetState.cancelled;
    });
  }

  /// Retries a failed transfer.
  Future<void> retryTransfer() async {
    if (!widget.config.allowRetry) return;
    if (_state != TransferWidgetState.failed) return;

    if (widget.onRetry != null) {
      setState(() {
        _state = TransferWidgetState.transferring;
        _errorMessage = null;
      });

      _progressSubscription?.cancel();
      _progressSubscription = widget.onRetry!().listen(
        _handleProgress,
        onError: _handleError,
        onDone: _handleDone,
      );
    } else {
      await startTransfer();
    }
  }

  /// Opens the completed file.
  Future<void> openFile() async {
    if (_state != TransferWidgetState.completed) return;
    if (_resultPath == null) return;

    widget.onOpen?.call(_resultPath!);
  }

  /// Handles the main action button tap.
  void handleActionTap() {
    switch (_state) {
      case TransferWidgetState.idle:
      case TransferWidgetState.cancelled:
        startTransfer();
        break;
      case TransferWidgetState.transferring:
        if (widget.config.allowPauseResume) {
          pauseTransfer();
        } else if (widget.config.allowCancel) {
          cancelTransfer();
        }
        break;
      case TransferWidgetState.paused:
        resumeTransfer();
        break;
      case TransferWidgetState.failed:
        retryTransfer();
        break;
      case TransferWidgetState.completed:
        openFile();
        break;
      default:
        break;
    }
  }

  /// Whether this is an upload operation.
  bool get isUpload => widget.filePath != null && widget.url != null;

  /// Whether this is a download operation.
  bool get isDownload => !isUpload && widget.url != null;

  /// Gets the icon for the current state.
  IconData getStateIcon() {
    return switch (_state) {
      TransferWidgetState.idle =>
        isUpload ? theme.uploadIcon : theme.downloadIcon,
      TransferWidgetState.pending => Icons.hourglass_empty,
      TransferWidgetState.transferring =>
        widget.config.allowPauseResume ? theme.pauseIcon : theme.cancelIcon,
      TransferWidgetState.paused => theme.resumeIcon,
      TransferWidgetState.completed => theme.successIcon,
      TransferWidgetState.failed => theme.retryIcon,
      TransferWidgetState.cancelled => theme.retryIcon,
    };
  }

  /// Gets the color for the current state.
  Color getStateColor() {
    return switch (_state) {
      TransferWidgetState.idle => theme.iconColor,
      TransferWidgetState.pending => theme.iconColor,
      TransferWidgetState.transferring => theme.primaryColor,
      TransferWidgetState.paused => theme.pausedColor,
      TransferWidgetState.completed => theme.successColor,
      TransferWidgetState.failed => theme.errorColor,
      TransferWidgetState.cancelled => theme.iconColor,
    };
  }

  /// Gets the status text.
  String getStatusText() {
    return switch (_state) {
      TransferWidgetState.idle => isUpload ? 'جاهز للرفع' : 'جاهز للتحميل',
      TransferWidgetState.pending => 'في الانتظار...',
      TransferWidgetState.transferring =>
        isUpload ? 'جاري الرفع...' : 'جاري التحميل...',
      TransferWidgetState.paused => 'متوقف مؤقتاً',
      TransferWidgetState.completed => 'مكتمل',
      TransferWidgetState.failed => 'فشل - ${_errorMessage ?? "خطأ غير معروف"}',
      TransferWidgetState.cancelled => 'ملغى',
    };
  }

  /// Builds the action button.
  Widget buildActionButton() {
    if (!widget.config.showActionButton) {
      return const SizedBox.shrink();
    }

    final progressValue = _progress.progressPercent;

    return GestureDetector(
      onTap: handleActionTap,
      child: SizedBox(
        width: actionButtonSize,
        height: actionButtonSize,
        child: DashedCircularProgressBar.square(
          dimensions: actionButtonSize,
          progress: progressValue,
          maxProgress: 100,
          backgroundStrokeWidth: theme.progressStrokeWidth,
          foregroundStrokeWidth: theme.progressStrokeWidth,
          foregroundColor: getStateColor(),
          backgroundColor: theme.progressBackgroundColor,
          animation: true,
          animationDuration: theme.progressAnimationDuration,
          animationCurve: theme.progressAnimationCurve,
          child: Icon(
            getStateIcon(),
            color: getStateColor(),
            size: actionButtonSize * 0.5,
          ),
        ),
      ),
    );
  }

  /// Builds the progress info widget.
  Widget buildProgressInfo() {
    final parts = <String>[];

    if (widget.config.showProgress &&
        _state == TransferWidgetState.transferring) {
      parts.add(_progress.progressText);
    }

    if (widget.config.showSpeed && _state == TransferWidgetState.transferring) {
      parts.add(_progress.speedText);
    }

    if (widget.config.showEta && _state == TransferWidgetState.transferring) {
      parts.add(_progress.etaText);
    }

    if (widget.config.showFileSize) {
      if (_state == TransferWidgetState.transferring) {
        parts.add(
          '${_progress.bytesTransferredText} / ${_progress.totalBytesText}',
        );
      } else if (widget.fileSize != null && widget.fileSize! > 0) {
        parts.add(_formatBytes(widget.fileSize!));
      }
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Text(
      parts.join(' • '),
      style:
          theme.fileSizeStyle ??
          TextStyle(fontSize: 12, color: theme.subtitleColor),
    );
  }

  /// Builds the linear progress bar.
  Widget buildLinearProgress() {
    if (!widget.config.showLinearProgress) {
      return const SizedBox.shrink();
    }

    if (_state != TransferWidgetState.transferring &&
        _state != TransferWidgetState.paused) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: theme.progressBorderRadius,
      child: LinearProgressIndicator(
        value: _progress.progress,
        backgroundColor: theme.progressBackgroundColor,
        valueColor: AlwaysStoppedAnimation(getStateColor()),
        minHeight: theme.linearProgressHeight,
      ),
    );
  }

  /// Builds the error message widget.
  Widget buildErrorMessage() {
    if (_state != TransferWidgetState.failed || _errorMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            theme.errorIcon,
            size: theme.smallIconSize,
            color: theme.errorColor,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _errorMessage!,
              style:
                  theme.errorStyle ??
                  TextStyle(fontSize: 12, color: theme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the thumbnail overlay for media.
  Widget buildThumbnailOverlay({required Widget child}) {
    if (_state == TransferWidgetState.completed) {
      return child;
    }

    return Stack(
      children: [
        // Thumbnail
        child,

        // Blur overlay
        if (theme.useBlurOverlay)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: theme.thumbnailBorderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: theme.blurSigma,
                  sigmaY: theme.blurSigma,
                ),
                child: Container(color: theme.overlayColor),
              ),
            ),
          ),

        // Action button
        Center(child: buildActionButton()),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
