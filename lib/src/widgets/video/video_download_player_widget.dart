import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../handlers/transfer_progress.dart';
import '../../handlers/transfer_handler.dart';
import '../../theme/social_transfer_theme.dart';

/// Configuration for the video download player widget.
class VideoPlayerConfig {
  /// Whether to auto-start download.
  final bool autoStartDownload;

  /// Whether to auto-play video after download.
  final bool autoPlay;

  /// Whether to loop the video.
  final bool looping;

  /// Whether to show controls.
  final bool showControls;

  /// Aspect ratio of the video.
  final double? aspectRatio;

  /// Placeholder widget to show while video is loading.
  final Widget? placeholder;

  /// Whether to allow full screen.
  final bool allowFullScreen;

  /// Whether to allow playback speed change.
  final bool allowPlaybackSpeedChanging;

  /// Whether to allow muting.
  final bool allowMuting;

  /// Custom error widget builder.
  final Widget Function(BuildContext context, String error)? errorBuilder;

  /// Material controls color customization.
  final ChewieProgressColors? progressColors;

  const VideoPlayerConfig({
    this.autoStartDownload = false,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio,
    this.placeholder,
    this.allowFullScreen = true,
    this.allowPlaybackSpeedChanging = true,
    this.allowMuting = true,
    this.errorBuilder,
    this.progressColors,
  });
}

/// State of the video download player.
enum VideoPlayerState {
  /// Initial state - waiting to download.
  idle,

  /// Downloading the video.
  downloading,

  /// Download paused.
  paused,

  /// Download failed.
  failed,

  /// Download completed, ready to play.
  ready,

  /// Video is initializing.
  initializing,

  /// Video is playing.
  playing,

  /// Video playback error.
  playbackError,
}

/// A widget that downloads and plays videos.
///
/// This widget combines file download functionality with video playback,
/// providing a seamless experience for viewing remote videos.
///
/// Example:
/// ```dart
/// VideoDownloadPlayerWidget(
///   url: 'https://example.com/video.mp4',
///   thumbnailUrl: 'https://example.com/thumb.jpg',
///   fileName: 'video.mp4',
///   fileSize: 1024 * 1024 * 10, // 10 MB
///   duration: Duration(minutes: 2, seconds: 30),
///   onDownload: (payload) => downloadStream(payload),
///   config: VideoPlayerConfig(
///     autoPlay: true,
///     showControls: true,
///   ),
/// )
/// ```
class VideoDownloadPlayerWidget extends StatefulWidget {
  /// URL of the video to download.
  final String url;

  /// Local file path (if already downloaded).
  final String? localPath;

  /// File name for the downloaded video.
  final String? fileName;

  /// Expected file size in bytes.
  final int? fileSize;

  /// Video duration.
  final Duration? duration;

  /// URL for the thumbnail image.
  final String? thumbnailUrl;

  /// Custom thumbnail widget.
  final Widget? thumbnailWidget;

  /// Widget configuration.
  final VideoPlayerConfig config;

  /// Theme data for styling.
  final SocialTransferThemeData? themeData;

  /// Width constraint.
  final double? width;

  /// Height constraint.
  final double? height;

  /// Callback to perform download.
  final Stream<TransferProgress> Function(DownloadPayload payload)? onDownload;

  /// Callback when download completes.
  final void Function(String filePath)? onDownloadComplete;

  /// Callback when video starts playing.
  final void Function()? onPlayStart;

  /// Callback when video finishes playing.
  final void Function()? onPlayComplete;

  /// Callback when an error occurs.
  final void Function(String error)? onError;

  /// Callback when state changes.
  final void Function(VideoPlayerState state)? onStateChange;

  /// Custom action button builder.
  final Widget Function(
    BuildContext context,
    VideoPlayerState state,
    VoidCallback? onTap,
  )? actionButtonBuilder;

  /// Custom progress overlay builder.
  final Widget Function(
    BuildContext context,
    TransferProgress progress,
  )? progressBuilder;

  const VideoDownloadPlayerWidget({
    super.key,
    required this.url,
    this.localPath,
    this.fileName,
    this.fileSize,
    this.duration,
    this.thumbnailUrl,
    this.thumbnailWidget,
    this.config = const VideoPlayerConfig(),
    this.themeData,
    this.width,
    this.height,
    this.onDownload,
    this.onDownloadComplete,
    this.onPlayStart,
    this.onPlayComplete,
    this.onError,
    this.onStateChange,
    this.actionButtonBuilder,
    this.progressBuilder,
  });

  @override
  State<VideoDownloadPlayerWidget> createState() =>
      _VideoDownloadPlayerWidgetState();
}

class _VideoDownloadPlayerWidgetState extends State<VideoDownloadPlayerWidget> {
  VideoPlayerState _state = VideoPlayerState.idle;
  TransferProgress _progress = TransferProgress.initial();
  String? _localFilePath;
  String? _errorMessage;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  StreamSubscription<TransferProgress>? _downloadSubscription;

  SocialTransferThemeData get theme =>
      widget.themeData ?? SocialTransferThemeData.whatsApp();

  double get _width => widget.width ?? 320;
  double get _height => widget.height ?? 180;

  @override
  void initState() {
    super.initState();
    _localFilePath = widget.localPath;

    if (_localFilePath != null && File(_localFilePath!).existsSync()) {
      _state = VideoPlayerState.ready;
    } else if (widget.config.autoStartDownload) {
      _startDownload();
    }
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _setState(VideoPlayerState newState) {
    if (_state != newState) {
      setState(() => _state = newState);
      widget.onStateChange?.call(newState);
    }
  }

  Future<void> _startDownload() async {
    if (widget.onDownload == null) {
      _setState(VideoPlayerState.failed);
      _errorMessage = 'No download handler provided';
      widget.onError?.call(_errorMessage!);
      return;
    }

    _setState(VideoPlayerState.downloading);
    _progress = TransferProgress.initial(totalBytes: widget.fileSize ?? -1);

    final payload = DownloadPayload(
      url: widget.url,
      fileName: widget.fileName ?? _extractFileName(widget.url),
      expectedSize: widget.fileSize,
    );

    try {
      final stream = widget.onDownload!(payload);
      _downloadSubscription = stream.listen(
        (progress) {
          setState(() => _progress = progress);

          if (progress.isCompleted) {
            _localFilePath = payload.destinationPath ??
                '/downloaded/${payload.fileName ?? 'video.mp4'}';
            _setState(VideoPlayerState.ready);
            widget.onDownloadComplete?.call(_localFilePath!);

            if (widget.config.autoPlay) {
              _initializePlayer();
            }
          } else if (progress.isFailed) {
            _errorMessage = progress.errorMessage ?? 'Download failed';
            _setState(VideoPlayerState.failed);
            widget.onError?.call(_errorMessage!);
          } else if (progress.isPaused) {
            _setState(VideoPlayerState.paused);
          } else if (progress.isCancelled) {
            _setState(VideoPlayerState.idle);
          }
        },
        onError: (error) {
          _errorMessage = error.toString();
          _setState(VideoPlayerState.failed);
          widget.onError?.call(_errorMessage!);
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
      _setState(VideoPlayerState.failed);
      widget.onError?.call(_errorMessage!);
    }
  }

  Future<void> _initializePlayer() async {
    if (_localFilePath == null) return;

    _setState(VideoPlayerState.initializing);

    try {
      final file = File(_localFilePath!);
      if (!file.existsSync()) {
        // Try playing from URL directly
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      } else {
        _videoController = VideoPlayerController.file(file);
      }

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: widget.config.autoPlay,
        looping: widget.config.looping,
        showControls: widget.config.showControls,
        aspectRatio: widget.config.aspectRatio ?? _videoController!.value.aspectRatio,
        allowFullScreen: widget.config.allowFullScreen,
        allowPlaybackSpeedChanging: widget.config.allowPlaybackSpeedChanging,
        allowMuting: widget.config.allowMuting,
        materialProgressColors: widget.config.progressColors,
        placeholder: widget.config.placeholder,
        errorBuilder: (context, errorMessage) {
          return widget.config.errorBuilder?.call(context, errorMessage) ??
              _buildErrorWidget(errorMessage);
        },
      );

      _videoController!.addListener(_onVideoStateChanged);

      _setState(VideoPlayerState.playing);
      widget.onPlayStart?.call();
    } catch (e) {
      _errorMessage = 'Failed to initialize player: $e';
      _setState(VideoPlayerState.playbackError);
      widget.onError?.call(_errorMessage!);
    }
  }

  void _onVideoStateChanged() {
    if (_videoController == null) return;

    final value = _videoController!.value;

    if (value.hasError) {
      _errorMessage = value.errorDescription ?? 'Playback error';
      _setState(VideoPlayerState.playbackError);
      widget.onError?.call(_errorMessage!);
    } else if (value.position >= value.duration && value.duration.inMilliseconds > 0) {
      widget.onPlayComplete?.call();
    }
  }

  void _handleActionTap() {
    switch (_state) {
      case VideoPlayerState.idle:
        _startDownload();
        break;
      case VideoPlayerState.downloading:
        // Pause not implemented yet
        break;
      case VideoPlayerState.paused:
        _startDownload(); // Resume
        break;
      case VideoPlayerState.failed:
      case VideoPlayerState.playbackError:
        _startDownload(); // Retry
        break;
      case VideoPlayerState.ready:
        _initializePlayer();
        break;
      case VideoPlayerState.initializing:
        // Wait
        break;
      case VideoPlayerState.playing:
        if (_chewieController != null) {
          if (_videoController!.value.isPlaying) {
            _videoController!.pause();
          } else {
            _videoController!.play();
          }
        }
        break;
    }
  }

  String _extractFileName(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return 'video.mp4';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: theme.bubbleColor,
        borderRadius: theme.incomingBubbleBorderRadius,
        boxShadow: theme.bubbleShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case VideoPlayerState.idle:
        return _buildThumbnailWithOverlay(_buildDownloadButton());

      case VideoPlayerState.downloading:
      case VideoPlayerState.paused:
        return _buildThumbnailWithOverlay(_buildProgressOverlay());

      case VideoPlayerState.failed:
      case VideoPlayerState.playbackError:
        return _buildThumbnailWithOverlay(_buildErrorOverlay());

      case VideoPlayerState.ready:
        return _buildThumbnailWithOverlay(_buildPlayButton());

      case VideoPlayerState.initializing:
        return _buildThumbnailWithOverlay(_buildInitializingOverlay());

      case VideoPlayerState.playing:
        return _buildVideoPlayer();
    }
  }

  Widget _buildThumbnailWithOverlay(Widget overlay) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildThumbnail(),
        Container(color: Colors.black38),
        overlay,
        if (widget.duration != null) _buildDurationBadge(),
      ],
    );
  }

  Widget _buildThumbnail() {
    if (widget.thumbnailWidget != null) {
      return widget.thumbnailWidget!;
    }

    if (widget.thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: theme.bubbleColor,
      child: Center(
        child: Icon(
          theme.videoIcon,
          size: 48,
          color: theme.subtitleColor.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildDownloadButton() {
    if (widget.actionButtonBuilder != null) {
      return widget.actionButtonBuilder!(context, _state, _handleActionTap);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _handleActionTap,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          if (widget.fileSize != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatBytes(widget.fileSize!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayButton() {
    if (widget.actionButtonBuilder != null) {
      return widget.actionButtonBuilder!(context, _state, _handleActionTap);
    }

    return Center(
      child: GestureDetector(
        onTap: _handleActionTap,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: theme.primaryColor,
            size: 48,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressOverlay() {
    if (widget.progressBuilder != null) {
      return widget.progressBuilder!(context, _progress);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _progress.hasTotalBytes ? _progress.progress : null,
                  strokeWidth: 4,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                ),
                Text(
                  _progress.hasTotalBytes
                      ? '${(_progress.progress * 100).toInt()}%'
                      : '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${_progress.bytesTransferredText} / ${_progress.totalBytesText}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                if (_progress.bytesPerSecond > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    _progress.speedText,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.errorColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _handleActionTap,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializingOverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(theme.primaryColor),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Preparing video...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_chewieController == null) {
      return _buildInitializingOverlay();
    }

    return Chewie(controller: _chewieController!);
  }

  Widget _buildDurationBadge() {
    if (widget.duration == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _formatDuration(widget.duration!),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, color: theme.errorColor, size: 48),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: theme.errorColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
