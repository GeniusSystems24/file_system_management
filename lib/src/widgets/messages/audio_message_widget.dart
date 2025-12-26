import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../theme/social_transfer_theme.dart';
import 'base_message_widget.dart';

/// A widget for displaying audio message transfers.
///
/// This widget provides a specialized UI for audio files with:
/// - Waveform visualization
/// - Duration display
/// - Play/pause controls (after completion)
/// - Progress tracking during upload/download
///
/// Example:
/// ```dart
/// AudioMessageTransferWidget(
///   url: 'https://example.com/audio.mp3',
///   fileName: 'voice_message.mp3',
///   duration: Duration(seconds: 30),
///   waveform: waveformData,
///   onDownload: (payload) => myDownloadStream(payload),
///   onComplete: (result) => print('Audio ready: ${result.localPath}'),
/// )
/// ```
class AudioMessageTransferWidget extends BaseMessageTransferWidget {
  /// Duration of the audio.
  final Duration? duration;

  /// Waveform data (normalized values 0.0-1.0).
  final List<double>? waveform;

  /// Raw waveform bytes (will be converted to normalized values).
  final Uint8List? waveformBytes;

  /// Number of waveform bars to display.
  final int waveformBarCount;

  /// Whether to animate the waveform during playback.
  final bool animateWaveform;

  /// Builder for the play button (shown after completion).
  final Widget Function(BuildContext context, VoidCallback onPlay)?
      playButtonBuilder;

  /// Callback when play is pressed (after completion).
  final VoidCallback? onPlay;

  /// Whether the audio is currently playing.
  final bool isPlaying;

  /// Current playback position.
  final Duration? playbackPosition;

  /// Custom background color for the widget.
  final Color? backgroundColor;

  const AudioMessageTransferWidget({
    super.key,
    super.config,
    super.uploadHandler,
    super.downloadHandler,
    super.url,
    super.filePath,
    super.fileName,
    super.fileSize,
    super.mimeType = 'audio/mpeg',
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
    this.duration,
    this.waveform,
    this.waveformBytes,
    this.waveformBarCount = 30,
    this.animateWaveform = true,
    this.playButtonBuilder,
    this.onPlay,
    this.isPlaying = false,
    this.playbackPosition,
    this.backgroundColor,
  });

  @override
  State<AudioMessageTransferWidget> createState() =>
      _AudioMessageTransferWidgetState();
}

class _AudioMessageTransferWidgetState
    extends BaseMessageTransferWidgetState<AudioMessageTransferWidget> {
  List<double> get _waveform {
    if (widget.waveform != null) return widget.waveform!;
    if (widget.waveformBytes != null) {
      return widget.waveformBytes!
          .map((b) => b / 255.0)
          .toList();
    }
    // Generate placeholder waveform
    return List.generate(widget.waveformBarCount, (i) {
      final t = i / widget.waveformBarCount;
      return 0.3 + 0.4 * (0.5 + 0.5 * (t * 3.14159).sin()).abs();
    });
  }

  String get _durationText {
    final duration = widget.duration;
    if (duration == null) return '--:--';

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get _playbackText {
    final position = widget.playbackPosition ?? Duration.zero;
    final minutes = position.inMinutes;
    final seconds = position.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _playbackProgress {
    if (widget.duration == null || widget.playbackPosition == null) return 0.0;
    if (widget.duration!.inMilliseconds == 0) return 0.0;
    return widget.playbackPosition!.inMilliseconds /
        widget.duration!.inMilliseconds;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ??
        (widget.config.direction == BubbleDirection.outgoing
            ? theme.outgoingBubbleColor
            : theme.incomingBubbleColor);

    final borderRadius = widget.config.direction == BubbleDirection.outgoing
        ? theme.outgoingBubbleBorderRadius
        : theme.incomingBubbleBorderRadius;

    return Container(
      constraints: BoxConstraints(
        maxWidth: theme.maxBubbleWidth,
        minWidth: theme.minBubbleWidth,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        boxShadow: theme.bubbleShadow,
      ),
      padding: theme.bubblePadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Action/Play button
          _buildButton(),

          const SizedBox(width: 12),

          // Waveform and info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Waveform
                _buildWaveform(),

                const SizedBox(height: 4),

                // Duration and progress info
                _buildInfo(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    if (state == TransferWidgetState.completed) {
      // Show play button
      if (widget.playButtonBuilder != null) {
        return widget.playButtonBuilder!(context, () {
          widget.onPlay?.call();
        });
      }

      return GestureDetector(
        onTap: widget.onPlay ?? openFile,
        child: Container(
          width: actionButtonSize,
          height: actionButtonSize,
          decoration: BoxDecoration(
            color: theme.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            widget.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: actionButtonSize * 0.6,
          ),
        ),
      );
    }

    return buildActionButton();
  }

  Widget _buildWaveform() {
    final waveform = _waveform;
    final barCount = widget.waveformBarCount.clamp(10, waveform.length);
    final barWidth = 3.0;
    final barSpacing = 2.0;
    final maxHeight = 24.0;

    // Sample waveform to match bar count
    final sampledWaveform = List.generate(barCount, (i) {
      final index = (i * waveform.length / barCount).floor();
      return waveform[index.clamp(0, waveform.length - 1)];
    });

    return SizedBox(
      height: maxHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(barCount, (i) {
          final value = sampledWaveform[i].clamp(0.1, 1.0);
          final height = value * maxHeight;

          Color barColor;
          if (state == TransferWidgetState.completed && widget.isPlaying) {
            // Show playback progress
            final progress = _playbackProgress;
            barColor = i / barCount < progress
                ? theme.primaryColor
                : theme.subtitleColor.withOpacity(0.5);
          } else if (state == TransferWidgetState.transferring) {
            // Show download/upload progress
            barColor = i / barCount < progress.progress
                ? theme.primaryColor
                : theme.subtitleColor.withOpacity(0.3);
          } else {
            barColor = theme.subtitleColor.withOpacity(0.5);
          }

          return Container(
            width: barWidth,
            height: height,
            margin: EdgeInsets.only(right: i < barCount - 1 ? barSpacing : 0),
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(barWidth / 2),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInfo() {
    if (state == TransferWidgetState.transferring ||
        state == TransferWidgetState.paused) {
      return Row(
        children: [
          Text(
            progress.progressText,
            style: theme.durationStyle ??
                TextStyle(
                  fontSize: 11,
                  color: theme.subtitleColor,
                ),
          ),
          const Spacer(),
          if (widget.config.showSpeed)
            Text(
              progress.speedText,
              style: theme.speedStyle ??
                  TextStyle(
                    fontSize: 11,
                    color: theme.subtitleColor,
                  ),
            ),
        ],
      );
    }

    if (state == TransferWidgetState.failed) {
      return Row(
        children: [
          Icon(
            theme.errorIcon,
            size: 12,
            color: theme.errorColor,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              errorMessage ?? 'فشل التحميل',
              style: TextStyle(
                fontSize: 11,
                color: theme.errorColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          state == TransferWidgetState.completed && widget.isPlaying
              ? _playbackText
              : _durationText,
          style: theme.durationStyle ??
              TextStyle(
                fontSize: 11,
                color: theme.subtitleColor,
              ),
        ),
        const Spacer(),
        if (widget.config.showFileSize && widget.fileSize != null)
          Text(
            _formatBytes(widget.fileSize!),
            style: TextStyle(
              fontSize: 11,
              color: theme.subtitleColor,
            ),
          ),
      ],
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

/// Extension for sin function on double.
extension _DoubleExt on double {
  double sin() => _sin(this);
}

double _sin(double x) {
  // Simple sine approximation
  x = x % (2 * 3.14159);
  if (x < 0) x += 2 * 3.14159;

  double result = x;
  double term = x;

  for (int i = 1; i < 10; i++) {
    term *= -x * x / ((2 * i) * (2 * i + 1));
    result += term;
  }

  return result;
}
