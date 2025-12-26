import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'base_message_widget.dart';

/// A widget for displaying image message transfers.
///
/// This widget provides a specialized UI for images with:
/// - Thumbnail preview with blur overlay during transfer
/// - Smooth progress animation
/// - Full image display after completion
/// - Support for local and network thumbnails
///
/// Example:
/// ```dart
/// ImageMessageTransferWidget(
///   url: 'https://example.com/image.jpg',
///   thumbnailUrl: 'https://example.com/thumb.jpg',
///   width: 300,
///   height: 200,
///   onDownload: (payload) => myDownloadStream(payload),
///   completedBuilder: (context, path) => Image.file(File(path)),
/// )
/// ```
class ImageMessageTransferWidget extends BaseMessageTransferWidget {
  /// URL for the thumbnail.
  final String? thumbnailUrl;

  /// Thumbnail as bytes.
  final Uint8List? thumbnailBytes;

  /// Thumbnail as ImageProvider.
  final ImageProvider? thumbnailProvider;

  /// Custom thumbnail widget.
  final Widget? thumbnailWidget;

  /// Image width.
  final double? width;

  /// Image height.
  final double? height;

  /// Aspect ratio (used if width/height not specified).
  final double? aspectRatio;

  /// How to fit the thumbnail.
  final BoxFit thumbnailFit;

  /// Builder for the completed state.
  final Widget Function(BuildContext context, String filePath)?
      completedBuilder;

  /// Builder for the loading state.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for the error state.
  final Widget Function(BuildContext context, String? error)? errorBuilder;

  /// Whether to show image caption.
  final bool showCaption;

  /// Image caption text.
  final String? caption;

  /// Whether to enable full screen preview on tap.
  final bool enableFullScreen;

  /// Callback for full screen preview.
  final void Function(String filePath)? onFullScreen;

  const ImageMessageTransferWidget({
    super.key,
    super.config,
    super.uploadHandler,
    super.downloadHandler,
    super.url,
    super.filePath,
    super.fileName,
    super.fileSize,
    super.mimeType = 'image/jpeg',
    super.initialState,
    super.onUpload,
    super.onDownload,
    super.onRetry,
    super.onCancel,
    super.onPause,
    super.onResume,
    super.onOpen,
    super.onGetUrl,
    super.cancellationToken,
    super.transferConfig,
    super.onTransferStart,
    super.onTransferComplete,
    super.onTransferError,
    super.onProgressUpdate,
    super.themeData,
    this.thumbnailUrl,
    this.thumbnailBytes,
    this.thumbnailProvider,
    this.thumbnailWidget,
    this.width,
    this.height,
    this.aspectRatio,
    this.thumbnailFit = BoxFit.cover,
    this.completedBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.showCaption = false,
    this.caption,
    this.enableFullScreen = true,
    this.onFullScreen,
  });

  @override
  State<ImageMessageTransferWidget> createState() =>
      _ImageMessageTransferWidgetState();
}

class _ImageMessageTransferWidgetState
    extends BaseMessageTransferWidgetState<ImageMessageTransferWidget> {
  double get _width =>
      widget.width ?? (widget.aspectRatio != null ? 200 : 200);
  double get _height => widget.height ??
      (widget.aspectRatio != null ? 200 / widget.aspectRatio! : 200);

  bool get _hasThumbnail =>
      widget.thumbnailUrl != null ||
      widget.thumbnailBytes != null ||
      widget.thumbnailProvider != null ||
      widget.thumbnailWidget != null;

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.config.direction == BubbleDirection.outgoing
        ? theme.outgoingBubbleBorderRadius
        : theme.incomingBubbleBorderRadius;

    return Container(
      constraints: BoxConstraints(
        maxWidth: theme.maxBubbleWidth,
        maxHeight: 400,
      ),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: theme.bubbleShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // Image/Thumbnail
            _buildImage(),

            // Overlay and controls
            if (state != TransferWidgetState.completed) _buildOverlay(),

            // Caption
            if (widget.showCaption && widget.caption != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildCaption(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Completed state - show full image
    if (state == TransferWidgetState.completed && resultPath != null) {
      if (widget.completedBuilder != null) {
        return widget.completedBuilder!(context, resultPath!);
      }

      return GestureDetector(
        onTap: widget.enableFullScreen
            ? () {
                widget.onFullScreen?.call(resultPath!);
                openFile();
              }
            : null,
        child: Image.file(
          File(resultPath!),
          width: _width,
          height: _height,
          fit: widget.thumbnailFit,
          errorBuilder: (context, error, stack) => _buildPlaceholder(),
        ),
      );
    }

    // Show thumbnail or placeholder
    return SizedBox(
      width: _width,
      height: _height,
      child: _buildThumbnail(),
    );
  }

  Widget _buildThumbnail() {
    if (widget.thumbnailWidget != null) {
      return widget.thumbnailWidget!;
    }

    if (widget.thumbnailProvider != null) {
      return Image(
        image: widget.thumbnailProvider!,
        width: _width,
        height: _height,
        fit: widget.thumbnailFit,
        errorBuilder: (context, error, stack) => _buildPlaceholder(),
      );
    }

    if (widget.thumbnailBytes != null) {
      return Image.memory(
        widget.thumbnailBytes!,
        width: _width,
        height: _height,
        fit: widget.thumbnailFit,
        errorBuilder: (context, error, stack) => _buildPlaceholder(),
      );
    }

    if (widget.thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.thumbnailUrl!,
        width: _width,
        height: _height,
        fit: widget.thumbnailFit,
        placeholder: (context, url) => _buildPlaceholder(showLoading: true),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder({bool showLoading = false}) {
    return Container(
      width: _width,
      height: _height,
      color: theme.bubbleColor,
      child: Center(
        child: showLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(theme.subtitleColor),
                ),
              )
            : Icon(
                theme.imageIcon,
                size: 48,
                color: theme.subtitleColor.withOpacity(0.5),
              ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: theme.overlayColor,
        ),
        child: _hasThumbnail && theme.useBlurOverlay
            ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: theme.blurSigma,
                  sigmaY: theme.blurSigma,
                ),
                child: _buildOverlayContent(),
              )
            : _buildOverlayContent(),
      ),
    );
  }

  Widget _buildOverlayContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Action button
        buildActionButton(),

        const SizedBox(height: 8),

        // Progress info
        if (state == TransferWidgetState.transferring ||
            state == TransferWidgetState.paused)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${progress.progressText} • ${progress.speedText}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),

        // Error message
        if (state == TransferWidgetState.failed)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: theme.errorColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              errorMessage ?? 'فشل التحميل',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),

        // File size
        if (state == TransferWidgetState.idle && widget.fileSize != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatBytes(widget.fileSize!),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCaption() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Text(
        widget.caption!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
