import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../handlers/transfer_progress.dart';
import '../../handlers/transfer_handler.dart';
import '../../theme/social_transfer_theme.dart';

/// Display mode for video playback.
enum VideoDisplayMode {
  /// Play video inline within the card widget.
  inline,

  /// Open fullscreen player when tapped (like Telegram).
  fullscreen,
}

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

  /// Display mode for video playback.
  final VideoDisplayMode displayMode;

  /// Whether to show close button in fullscreen mode.
  final bool showCloseButton;

  /// Whether to hide status bar in fullscreen mode.
  final bool hideStatusBarInFullscreen;

  /// Background color for fullscreen mode.
  final Color fullscreenBackgroundColor;

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
    this.displayMode = VideoDisplayMode.inline,
    this.showCloseButton = true,
    this.hideStatusBarInFullscreen = true,
    this.fullscreenBackgroundColor = Colors.black,
  });

  /// Create a copy with some fields replaced.
  VideoPlayerConfig copyWith({
    bool? autoStartDownload,
    bool? autoPlay,
    bool? looping,
    bool? showControls,
    double? aspectRatio,
    Widget? placeholder,
    bool? allowFullScreen,
    bool? allowPlaybackSpeedChanging,
    bool? allowMuting,
    Widget Function(BuildContext context, String error)? errorBuilder,
    ChewieProgressColors? progressColors,
    VideoDisplayMode? displayMode,
    bool? showCloseButton,
    bool? hideStatusBarInFullscreen,
    Color? fullscreenBackgroundColor,
  }) {
    return VideoPlayerConfig(
      autoStartDownload: autoStartDownload ?? this.autoStartDownload,
      autoPlay: autoPlay ?? this.autoPlay,
      looping: looping ?? this.looping,
      showControls: showControls ?? this.showControls,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      placeholder: placeholder ?? this.placeholder,
      allowFullScreen: allowFullScreen ?? this.allowFullScreen,
      allowPlaybackSpeedChanging: allowPlaybackSpeedChanging ?? this.allowPlaybackSpeedChanging,
      allowMuting: allowMuting ?? this.allowMuting,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      progressColors: progressColors ?? this.progressColors,
      displayMode: displayMode ?? this.displayMode,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      hideStatusBarInFullscreen: hideStatusBarInFullscreen ?? this.hideStatusBarInFullscreen,
      fullscreenBackgroundColor: fullscreenBackgroundColor ?? this.fullscreenBackgroundColor,
    );
  }
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
/// Supports two display modes:
/// - [VideoDisplayMode.inline]: Plays video within the card widget
/// - [VideoDisplayMode.fullscreen]: Opens a fullscreen player like Telegram
///
/// Example:
/// ```dart
/// // Inline mode (default)
/// VideoDownloadPlayerWidget(
///   url: 'https://example.com/video.mp4',
///   thumbnailUrl: 'https://example.com/thumb.jpg',
///   onDownload: (payload) => downloadStream(payload),
/// )
///
/// // Fullscreen mode (like Telegram)
/// VideoDownloadPlayerWidget(
///   url: 'https://example.com/video.mp4',
///   thumbnailUrl: 'https://example.com/thumb.jpg',
///   config: VideoPlayerConfig(
///     displayMode: VideoDisplayMode.fullscreen,
///     autoPlay: true,
///   ),
///   onDownload: (payload) => downloadStream(payload),
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

  /// Title to show in fullscreen mode.
  final String? title;

  /// Subtitle to show in fullscreen mode.
  final String? subtitle;

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
    this.title,
    this.subtitle,
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

  bool get _isFullscreenMode =>
      widget.config.displayMode == VideoDisplayMode.fullscreen;

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
              _handlePlay();
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
    if (_localFilePath == null && widget.url.isEmpty) return;

    _setState(VideoPlayerState.initializing);

    try {
      if (_localFilePath != null && File(_localFilePath!).existsSync()) {
        _videoController = VideoPlayerController.file(File(_localFilePath!));
      } else {
        // Try playing from URL directly
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
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

  void _handlePlay() {
    if (_isFullscreenMode) {
      _openFullscreenPlayer();
    } else {
      _initializePlayer();
    }
  }

  void _openFullscreenPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullscreenVideoPlayer(
            url: widget.url,
            localPath: _localFilePath,
            title: widget.title ?? widget.fileName ?? _extractFileName(widget.url),
            subtitle: widget.subtitle,
            duration: widget.duration,
            config: widget.config,
            themeData: widget.themeData,
            onPlayStart: widget.onPlayStart,
            onPlayComplete: widget.onPlayComplete,
            onError: widget.onError,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
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
        _handlePlay();
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
        // For fullscreen mode, always show thumbnail with play button
        if (_isFullscreenMode) {
          return _buildThumbnailWithOverlay(_buildPlayButton());
        }
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
        // Display mode indicator
        if (_isFullscreenMode)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                Icons.fullscreen,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
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

/// Fullscreen video player screen (like Telegram).
class _FullscreenVideoPlayer extends StatefulWidget {
  final String url;
  final String? localPath;
  final String? title;
  final String? subtitle;
  final Duration? duration;
  final VideoPlayerConfig config;
  final SocialTransferThemeData? themeData;
  final void Function()? onPlayStart;
  final void Function()? onPlayComplete;
  final void Function(String error)? onError;

  const _FullscreenVideoPlayer({
    required this.url,
    this.localPath,
    this.title,
    this.subtitle,
    this.duration,
    required this.config,
    this.themeData,
    this.onPlayStart,
    this.onPlayComplete,
    this.onError,
  });

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _showControls = true;

  SocialTransferThemeData get theme =>
      widget.themeData ?? SocialTransferThemeData.whatsApp();

  @override
  void initState() {
    super.initState();
    if (widget.config.hideStatusBarInFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _initializePlayer();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      if (widget.localPath != null && File(widget.localPath!).existsSync()) {
        _videoController = VideoPlayerController.file(File(widget.localPath!));
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      }

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: widget.config.looping,
        showControls: false, // We use custom controls
        aspectRatio: widget.config.aspectRatio ?? _videoController!.value.aspectRatio,
        allowFullScreen: false, // Already fullscreen
        allowPlaybackSpeedChanging: widget.config.allowPlaybackSpeedChanging,
        allowMuting: widget.config.allowMuting,
        materialProgressColors: widget.config.progressColors ?? ChewieProgressColors(
          playedColor: theme.primaryColor,
          handleColor: theme.primaryColor,
          bufferedColor: theme.primaryColor.withOpacity(0.3),
          backgroundColor: Colors.white24,
        ),
      );

      _videoController!.addListener(_onVideoStateChanged);

      setState(() => _isInitializing = false);
      widget.onPlayStart?.call();
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Failed to initialize player: $e';
      });
      widget.onError?.call(_errorMessage!);
    }
  }

  void _onVideoStateChanged() {
    if (_videoController == null) return;

    final value = _videoController!.value;

    if (value.hasError) {
      setState(() => _errorMessage = value.errorDescription ?? 'Playback error');
      widget.onError?.call(_errorMessage!);
    } else if (value.position >= value.duration && value.duration.inMilliseconds > 0) {
      widget.onPlayComplete?.call();
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _togglePlayPause() {
    if (_videoController == null) return;

    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
    } else {
      _videoController!.play();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.config.fullscreenBackgroundColor,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video player
            _buildVideoContent(),

            // Controls overlay
            if (_showControls) ...[
              // Top bar
              _buildTopBar(),

              // Center play/pause button
              if (!_isInitializing && _errorMessage == null)
                _buildCenterControls(),

              // Bottom progress bar
              if (!_isInitializing && _errorMessage == null)
                _buildBottomControls(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_isInitializing) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(theme.primaryColor),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: theme.errorColor, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isInitializing = true;
                  _errorMessage = null;
                });
                _initializePlayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    if (_chewieController == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                // Close button
                if (widget.config.showCloseButton)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    iconSize: 28,
                  ),
                const SizedBox(width: 8),
                // Title and subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // More options
                IconButton(
                  onPressed: () {
                    // Show options menu
                  },
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    final isPlaying = _videoController?.value.isPlaying ?? false;

    return Center(
      child: GestureDetector(
        onTap: _togglePlayPause,
        child: AnimatedOpacity(
          opacity: _showControls ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    if (_videoController == null) return const SizedBox.shrink();

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: _videoController!,
                  builder: (context, value, child) {
                    final duration = value.duration;
                    final position = value.position;

                    return Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                            activeTrackColor: theme.primaryColor,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: theme.primaryColor,
                            overlayColor: theme.primaryColor.withOpacity(0.2),
                          ),
                          child: Slider(
                            value: duration.inMilliseconds > 0
                                ? position.inMilliseconds / duration.inMilliseconds
                                : 0,
                            onChanged: (value) {
                              final newPosition = Duration(
                                milliseconds: (value * duration.inMilliseconds).round(),
                              );
                              _videoController!.seekTo(newPosition);
                            },
                          ),
                        ),
                        // Time labels
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

/// Fullscreen video player that can be used independently.
///
/// This is a public class that can be used to open a fullscreen video player
/// without using the VideoDownloadPlayerWidget.
class FullscreenVideoPlayer extends StatelessWidget {
  /// URL of the video to play.
  final String url;

  /// Local file path (if already downloaded).
  final String? localPath;

  /// Title to show in the top bar.
  final String? title;

  /// Subtitle to show in the top bar.
  final String? subtitle;

  /// Video duration.
  final Duration? duration;

  /// Player configuration.
  final VideoPlayerConfig config;

  /// Theme data for styling.
  final SocialTransferThemeData? themeData;

  /// Callback when video starts playing.
  final void Function()? onPlayStart;

  /// Callback when video finishes playing.
  final void Function()? onPlayComplete;

  /// Callback when an error occurs.
  final void Function(String error)? onError;

  const FullscreenVideoPlayer({
    super.key,
    required this.url,
    this.localPath,
    this.title,
    this.subtitle,
    this.duration,
    this.config = const VideoPlayerConfig(),
    this.themeData,
    this.onPlayStart,
    this.onPlayComplete,
    this.onError,
  });

  /// Opens the fullscreen video player.
  static Future<void> open(
    BuildContext context, {
    required String url,
    String? localPath,
    String? title,
    String? subtitle,
    Duration? duration,
    VideoPlayerConfig config = const VideoPlayerConfig(),
    SocialTransferThemeData? themeData,
    void Function()? onPlayStart,
    void Function()? onPlayComplete,
    void Function(String error)? onError,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullscreenVideoPlayer(
            url: url,
            localPath: localPath,
            title: title,
            subtitle: subtitle,
            duration: duration,
            config: config,
            themeData: themeData,
            onPlayStart: onPlayStart,
            onPlayComplete: onPlayComplete,
            onError: onError,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _FullscreenVideoPlayer(
      url: url,
      localPath: localPath,
      title: title,
      subtitle: subtitle,
      duration: duration,
      config: config,
      themeData: themeData,
      onPlayStart: onPlayStart,
      onPlayComplete: onPlayComplete,
      onError: onError,
    );
  }
}
