import 'dart:async';
import 'dart:ui';

import 'package:background_downloader/background_downloader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../controllers/file_system_controller.dart';
import '../models/transfer_item.dart';
import 'transfer_progress_indicator.dart';

/// Callback type for transfer actions.
typedef TransferCallback = void Function(TransferItem item);

/// A unified card widget for displaying file transfer (download/upload) progress.
///
/// Supports:
/// - Media files (image/video) with thumbnail preview
/// - Document files with icon
/// - Progress tracking with pause/resume/cancel
/// - Automatic state management via streams
class TransferCard extends StatefulWidget {
  /// The URL to download from or upload to.
  final String url;

  /// Optional task to use instead of creating one from URL.
  final Task? task;

  /// Whether to auto-start the transfer.
  final bool autoStart;

  /// Builder for completed state.
  final Widget Function(BuildContext context, TransferItem item, String filePath)?
      completedBuilder;

  /// Builder for loading/progress state.
  final Widget Function(BuildContext context, TransferItem? item)? loadingBuilder;

  /// Builder for error state.
  final Widget Function(BuildContext context, TransferItem? item, String? error)?
      errorBuilder;

  /// Builder for empty/initial state.
  final Widget Function(BuildContext context)? emptyBuilder;

  /// Called when transfer starts.
  final VoidCallback? onStart;

  /// Called when transfer is paused.
  final TransferCallback? onPause;

  /// Called when transfer is resumed.
  final TransferCallback? onResume;

  /// Called when transfer is cancelled.
  final TransferCallback? onCancel;

  /// Called when transfer fails and retry is requested.
  final TransferCallback? onRetry;

  /// Called when transfer completes.
  final TransferCallback? onComplete;

  /// Thumbnail URL for media preview.
  final String? thumbnailUrl;

  /// Thumbnail image provider.
  final ImageProvider? thumbnailProvider;

  /// Custom thumbnail widget.
  final Widget? thumbnailWidget;

  /// Thumbnail fit mode.
  final BoxFit thumbnailFit;

  /// Whether to show blur overlay on thumbnail.
  final bool showThumbnailOverlay;

  /// Thumbnail opacity.
  final double thumbnailOpacity;

  /// Thumbnail border radius.
  final BorderRadius? thumbnailBorderRadius;

  /// Whether to show the action button.
  final bool showActionButton;

  /// Size of the action button.
  final double actionButtonSize;

  /// Custom progress indicator color.
  final Color? progressColor;

  /// Whether this is a media card (shows thumbnail) or document card.
  final bool isMediaCard;

  const TransferCard({
    super.key,
    required this.url,
    this.task,
    this.autoStart = false,
    this.completedBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRetry,
    this.onComplete,
    this.thumbnailUrl,
    this.thumbnailProvider,
    this.thumbnailWidget,
    this.thumbnailFit = BoxFit.cover,
    this.showThumbnailOverlay = true,
    this.thumbnailOpacity = 1.0,
    this.thumbnailBorderRadius,
    this.showActionButton = true,
    this.actionButtonSize = 40,
    this.progressColor,
    this.isMediaCard = true,
  });

  @override
  State<TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<TransferCard> {
  final _controller = FileSystemController.instance;
  StreamSubscription<TransferItem>? _subscription;
  TransferItem? _item;
  String? _cachedPath;
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(TransferCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _dispose();
      _initialize();
    }
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _initialize() async {
    // Check if already cached
    _cachedPath = _controller.getCachedPath(widget.url);
    if (_cachedPath != null) {
      _item = _controller.getTransfer(widget.url);
      if (mounted) setState(() {});
      return;
    }

    // Check if already in progress
    _item = _controller.getTransfer(widget.url);
    if (_item != null) {
      _listenToStream();
      if (mounted) setState(() {});
      return;
    }

    // Auto-start if configured
    if (widget.autoStart) {
      await _startTransfer();
    }
  }

  void _listenToStream() {
    final stream = _controller.getStream(widget.url);
    if (stream == null) return;

    _subscription?.cancel();
    _subscription = stream.listen(
      (item) {
        if (!mounted) return;
        setState(() => _item = item);

        if (item.isComplete) {
          _cachedPath = item.filePath;
          widget.onComplete?.call(item);
        }
      },
      onError: (error) {
        // Handle error
      },
    );
  }

  Future<void> _startTransfer() async {
    if (_isStarted) return;
    _isStarted = true;

    widget.onStart?.call();

    final task = widget.task ?? createDownloadTask(url: widget.url);
    final result = await _controller.enqueueDownload(task, autoStart: true);

    switch (result) {
      case EnqueueCached(:final filePath):
        _cachedPath = filePath;
        if (mounted) setState(() {});
        break;
      case EnqueueStarted():
      case EnqueueInProgress():
      case EnqueuePending():
        _listenToStream();
        break;
    }
  }

  Future<void> _handleAction() async {
    if (_item == null) {
      await _startTransfer();
      return;
    }

    switch (_item!.status) {
      case TaskStatus.running:
        if (_item!.canPause) {
          await _controller.pause(_item!);
          widget.onPause?.call(_item!);
        } else {
          await _controller.cancel(_item!);
          widget.onCancel?.call(_item!);
        }
        break;
      case TaskStatus.paused:
        await _controller.resume(_item!);
        widget.onResume?.call(_item!);
        break;
      case TaskStatus.failed:
        await _controller.retry(_item!);
        widget.onRetry?.call(_item!);
        break;
      default:
        await _startTransfer();
        break;
    }
  }

  bool get _isCompleted =>
      _cachedPath != null ||
      _item?.isComplete == true ||
      _item?.status == TaskStatus.complete;

  @override
  Widget build(BuildContext context) {
    // Completed state
    if (_isCompleted && _item != null && _cachedPath != null) {
      if (widget.completedBuilder != null) {
        return widget.completedBuilder!(context, _item!, _cachedPath!);
      }
    }

    // Error state
    if (_item?.isFailed == true) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(
          context,
          _item,
          _item?.exception?.description,
        );
      }
    }

    return widget.isMediaCard
        ? _buildMediaCard(context)
        : _buildDocumentCard(context);
  }

  Widget _buildMediaCard(BuildContext context) {
    return Stack(
      children: [
        // Background
        ..._buildBackground(context),

        // Completed content
        if (_isCompleted && widget.completedBuilder != null && _item != null)
          widget.completedBuilder!(context, _item!, _cachedPath ?? _item!.filePath),

        // Center action button
        if (!_isCompleted) _buildCenterAction(context),
      ],
    );
  }

  Widget _buildDocumentCard(BuildContext context) {
    // Completed state
    if (_isCompleted && widget.completedBuilder != null && _item != null) {
      return widget.completedBuilder!(context, _item!, _cachedPath ?? _item!.filePath);
    }

    // Error state
    if (_item?.isFailed == true) {
      return _buildErrorCard(context);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Action button
          if (widget.showActionButton)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(1000),
                onTap: _handleAction,
                child: TransferProgressIndicator(
                  item: _item,
                  size: widget.actionButtonSize,
                  progressColor: widget.progressColor,
                ),
              ),
            ),

          const SizedBox(width: 12),

          // Loading content
          Expanded(
            child: widget.loadingBuilder?.call(context, _item) ??
                _buildDefaultLoadingContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Retry button
          if (widget.showActionButton)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(1000),
                onTap: _handleAction,
                child: TransferProgressIndicator(
                  item: _item,
                  size: widget.actionButtonSize,
                  centerIcon: Icons.refresh,
                ),
              ),
            ),

          const SizedBox(width: 12),

          // Error message
          Expanded(
            child: widget.errorBuilder?.call(
                  context,
                  _item,
                  _item?.exception?.description,
                ) ??
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _item?.exception?.description ?? 'فشل في التحميل',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLoadingContent(BuildContext context) {
    final theme = Theme.of(context);

    if (_item == null) {
      return Text(
        'جاهز للتحميل',
        style: theme.textTheme.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _item!.statusText,
          style: theme.textTheme.bodyMedium,
        ),
        if (_item!.isRunning) ...[
          const SizedBox(height: 4),
          Text(
            '${_item!.progressText} • ${_item!.networkSpeedText}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
        if (_item!.isPaused) ...[
          const SizedBox(height: 4),
          Text(
            _item!.pausedProgressText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _buildBackground(BuildContext context) {
    // Check if we have thumbnail to display
    if (_hasThumbnail()) {
      return _buildThumbnailBackground(context);
    }

    return [widget.emptyBuilder?.call(context) ?? Container()];
  }

  Widget _buildCenterAction(BuildContext context) {
    return Center(
      child: SizedBox(
        width: widget.actionButtonSize,
        height: widget.actionButtonSize,
        child: InkWell(
          borderRadius: BorderRadius.circular(1000),
          onTap: widget.showActionButton ? _handleAction : null,
          child: TransferProgressIndicator(
            item: _item,
            size: widget.actionButtonSize,
            progressColor: widget.progressColor,
          ),
        ),
      ),
    );
  }

  bool _hasThumbnail() {
    return widget.thumbnailUrl != null ||
        widget.thumbnailProvider != null ||
        widget.thumbnailWidget != null;
  }

  List<Widget> _buildThumbnailBackground(BuildContext context) {
    final theme = Theme.of(context);
    return [
      // Thumbnail layer
      Positioned.fill(
        child: Opacity(
          opacity: widget.thumbnailOpacity,
          child: _buildThumbnailWidget(context),
        ),
      ),

      // Overlay for better content visibility
      if (widget.showThumbnailOverlay)
        Positioned.fill(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: widget.thumbnailBorderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
    ];
  }

  Widget _buildThumbnailWidget(BuildContext context) {
    // Priority: Custom widget > Provider > URL
    if (widget.thumbnailWidget != null) {
      return widget.thumbnailWidget!;
    }

    if (widget.thumbnailProvider != null) {
      return Image(
        image: widget.thumbnailProvider!,
        fit: widget.thumbnailFit,
        errorBuilder: (context, error, stackTrace) {
          return _buildThumbnailError(context);
        },
      );
    }

    if (widget.thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.thumbnailUrl!,
        fit: widget.thumbnailFit,
        progressIndicatorBuilder: (context, child, loadingProgress) =>
            _buildThumbnailLoading(context, loadingProgress),
        errorWidget: (context, url, error) => _buildThumbnailError(context),
      );
    }

    return Container();
  }

  Widget _buildThumbnailLoading(
    BuildContext context,
    DownloadProgress loadingProgress,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: loadingProgress.progress,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
            strokeWidth: 2,
          ),
          const SizedBox(height: 8),
          Text(
            'تحميل المعاينة...',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailError(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 32,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'خطأ في المعاينة',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
