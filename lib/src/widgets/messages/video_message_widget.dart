import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../theme/social_transfer_theme.dart';
import 'base_message_widget.dart';

/// A widget for displaying video message transfers.
///
/// This widget provides a specialized UI for videos with:
/// - Thumbnail preview with play icon overlay
/// - Duration badge
/// - Progress tracking during upload/download
/// - Video player integration after completion
///
/// Example:
/// ```dart
/// VideoMessageTransferWidget(
///   url: 'https://example.com/video.mp4',
///   thumbnailUrl: 'https://example.com/thumb.jpg',
///   duration: Duration(minutes: 2, seconds: 30),
///   width: 300,
///   height: 200,
///   onDownload: (payload) => myDownloadStream(payload),
///   onPlay: (path) => openVideoPlayer(path),
/// )
/// ```
class VideoMessageTransferWidget extends BaseMessageTransferWidget {
  /// URL for the thumbnail.
  final String? thumbnailUrl;

  /// Thumbnail as bytes.
  final Uint8List? thumbnailBytes;

  /// Thumbnail as ImageProvider.
  final ImageProvider? thumbnailProvider;

  /// Custom thumbnail widget.
  final Widget? thumbnailWidget;

  /// Video duration.
  final Duration? duration;

  /// Video width.
  final double? width;

  /// Video height.
  final double? height;

  /// Aspect ratio (used if width/height not specified).
  final double? aspectRatio;

  /// How to fit the thumbnail.
  final BoxFit thumbnailFit;

  /// Builder for the completed state.
  final Widget Function(BuildContext context, String filePath)?
      completedBuilder;

  /// Callback when play is pressed.
  final void Function(String filePath)? onPlay;

  /// Whether the video is currently playing.
  final bool isPlaying;

  /// Whether to show duration badge.
  final bool showDuration;

  /// Whether video has audio.
  final bool hasAudio;

  /// Custom play button builder.
  final Widget Function(BuildContext context, VoidCallback onTap)?
      playButtonBuilder;

  const VideoMessageTransferWidget({
    super.key,
    super.config,
    super.uploadHandler,
    super.downloadHandler,
    super.url,
    super.filePath,
    super.fileName,
    super.fileSize,
    super.mimeType = 'video/mp4',
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
    this.duration,
    this.width,
    this.height,
    this.aspectRatio,
    this.thumbnailFit = BoxFit.cover,
    this.completedBuilder,
    this.onPlay,
    this.isPlaying = false,
    this.showDuration = true,
    this.hasAudio = true,
    this.playButtonBuilder,
  });

  @override
  State<VideoMessageTransferWidget> createState() =>
      _VideoMessageTransferWidgetState();
}

class _VideoMessageTransferWidgetState
    extends BaseMessageTransferWidgetState<VideoMessageTransferWidget> {
  double get _width =>
      widget.width ?? (widget.aspectRatio != null ? 250 : 250);
  double get _height => widget.height ??
      (widget.aspectRatio != null ? 250 / widget.aspectRatio! : 180);

  bool get _hasThumbnail =>
      widget.thumbnailUrl != null ||
      widget.thumbnailBytes != null ||
      widget.thumbnailProvider != null ||
      widget.thumbnailWidget != null;

  String get _durationText {
    final duration = widget.duration;
    if (duration == null) return '';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

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
            // Thumbnail
            _buildThumbnail(),

            // Overlay
            if (state != TransferWidgetState.completed || !widget.isPlaying)
              _buildOverlay(),

            // Duration badge
            if (widget.showDuration && widget.duration != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: _buildDurationBadge(),
              ),

            // Mute indicator
            if (!widget.hasAudio)
              Positioned(
                bottom: 8,
                left: 8,
                child: _buildMuteIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    // Completed state with custom builder
    if (state == TransferWidgetState.completed &&
        resultPath != null &&
        widget.completedBuilder != null) {
      return widget.completedBuilder!(context, resultPath!);
    }

    return SizedBox(
      width: _width,
      height: _height,
      child: _buildThumbnailContent(),
    );
  }

  Widget _buildThumbnailContent() {
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

    // Check for local file thumbnail
    if (state == TransferWidgetState.completed && resultPath != null) {
      // You could generate a thumbnail from the video here
      return _buildPlaceholder();
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder({bool showLoading = false}) {
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: theme.bubbleColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.bubbleColor,
            theme.bubbleColor.withOpacity(0.8),
          ],
        ),
      ),
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
                theme.videoIcon,
                size: 48,
                color: theme.subtitleColor.withOpacity(0.5),
              ),
      ),
    );
  }

  Widget _buildOverlay() {
    final isCompleted = state == TransferWidgetState.completed;

    return Positioned.fill(
      child: GestureDetector(
        onTap: isCompleted ? _handlePlayTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: isCompleted ? Colors.black26 : theme.overlayColor,
          ),
          child: _hasThumbnail && theme.useBlurOverlay && !isCompleted
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: theme.blurSigma,
                    sigmaY: theme.blurSigma,
                  ),
                  child: _buildOverlayContent(),
                )
              : _buildOverlayContent(),
        ),
      ),
    );
  }

  Widget _buildOverlayContent() {
    if (state == TransferWidgetState.completed) {
      // Show play button for completed state
      if (widget.playButtonBuilder != null) {
        return Center(
          child: widget.playButtonBuilder!(context, _handlePlayTap),
        );
      }

      return Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 40,
          ),
        ),
      );
    }

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
            child: Column(
              children: [
                Text(
                  progress.progressText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (widget.config.showSpeed)
                  Text(
                    progress.speedText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
              ],
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

        // File size for idle state
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

  Widget _buildDurationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _durationText,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMuteIndicator() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(
        Icons.volume_off,
        color: Colors.white,
        size: 14,
      ),
    );
  }

  void _handlePlayTap() {
    if (resultPath != null) {
      widget.onPlay?.call(resultPath!);
      openFile();
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
