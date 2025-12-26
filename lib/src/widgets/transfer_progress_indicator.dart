import 'package:background_downloader/background_downloader.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:flutter/material.dart';

import '../models/transfer_item.dart';

/// A circular progress indicator for file transfers.
///
/// Shows download/upload progress with customizable appearance.
class TransferProgressIndicator extends StatelessWidget {
  /// The transfer item to display progress for.
  final TransferItem? item;

  /// Size of the indicator.
  final double size;

  /// Stroke width of the progress bar.
  final double strokeWidth;

  /// Color for the progress.
  final Color? progressColor;

  /// Color for the background.
  final Color? backgroundColor;

  /// Icon to show in the center.
  final IconData? centerIcon;

  /// Size of the center icon.
  final double? iconSize;

  /// Whether to show the progress percentage.
  final bool showPercentage;

  /// Whether to animate the progress.
  final bool animate;

  const TransferProgressIndicator({
    super.key,
    this.item,
    this.size = 40,
    this.strokeWidth = 3,
    this.progressColor,
    this.backgroundColor,
    this.centerIcon,
    this.iconSize,
    this.showPercentage = false,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (item?.progress ?? 0) * 100;
    final status = item?.status ?? TaskStatus.enqueued;

    final effectiveProgressColor = progressColor ?? _getProgressColor(theme, status);
    final effectiveBackgroundColor = backgroundColor ??
        theme.colorScheme.onSurface.withValues(alpha: item == null ? 0.0 : 0.3);

    return SizedBox(
      width: size,
      height: size,
      child: DashedCircularProgressBar.square(
        dimensions: size,
        progress: progress,
        maxProgress: 100,
        backgroundStrokeWidth: strokeWidth,
        foregroundStrokeWidth: strokeWidth,
        foregroundColor: effectiveProgressColor,
        backgroundColor: effectiveBackgroundColor,
        animation: animate,
        child: _buildCenter(context, status),
      ),
    );
  }

  Widget _buildCenter(BuildContext context, TaskStatus status) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface;
    final effectiveIconSize = iconSize ?? size * 0.5;

    if (showPercentage && item != null && status == TaskStatus.running) {
      return Text(
        item!.progressText,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final icon = centerIcon ?? _getDefaultIcon(status);
    return Icon(icon, color: iconColor, size: effectiveIconSize);
  }

  IconData _getDefaultIcon(TaskStatus status) {
    return switch (status) {
      TaskStatus.running => Icons.close,
      TaskStatus.paused => Icons.play_arrow,
      TaskStatus.failed => Icons.refresh,
      TaskStatus.complete => Icons.check,
      _ => Icons.cloud_download,
    };
  }

  Color _getProgressColor(ThemeData theme, TaskStatus status) {
    return switch (status) {
      TaskStatus.running => theme.colorScheme.primary,
      TaskStatus.paused => theme.colorScheme.secondary,
      TaskStatus.failed => theme.colorScheme.error,
      TaskStatus.complete => Colors.green,
      _ => theme.colorScheme.secondary,
    };
  }
}
