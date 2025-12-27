import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:flutter/material.dart';

import '../domain/domain.dart';

/// A circular progress indicator for file transfers.
///
/// Shows download/upload progress with customizable appearance.
class TransferProgressIndicator extends StatelessWidget {
  /// The transfer entity to display progress for.
  final TransferEntity? entity;

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
    this.entity,
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
    final progress = (entity?.progress ?? 0) * 100;
    final status = entity?.status ?? TransferStatusEntity.pending;

    final effectiveProgressColor =
        progressColor ?? _getProgressColor(theme, status);
    final effectiveBackgroundColor = backgroundColor ??
        theme.colorScheme.onSurface
            .withValues(alpha: entity == null ? 0.0 : 0.3);

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

  Widget _buildCenter(BuildContext context, TransferStatusEntity status) {
    final theme = Theme.of(context);
    final iconColor = theme.colorScheme.onSurface;
    final effectiveIconSize = iconSize ?? size * 0.5;

    if (showPercentage && entity != null && status == TransferStatusEntity.running) {
      return Text(
        '${entity!.progressPercent.toStringAsFixed(0)}%',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final icon = centerIcon ?? _getDefaultIcon(status);
    return Icon(icon, color: iconColor, size: effectiveIconSize);
  }

  IconData _getDefaultIcon(TransferStatusEntity status) {
    return switch (status) {
      TransferStatusEntity.running => Icons.close,
      TransferStatusEntity.paused => Icons.play_arrow,
      TransferStatusEntity.failed => Icons.refresh,
      TransferStatusEntity.complete => Icons.check,
      _ => Icons.cloud_download,
    };
  }

  Color _getProgressColor(ThemeData theme, TransferStatusEntity status) {
    return switch (status) {
      TransferStatusEntity.running => theme.colorScheme.primary,
      TransferStatusEntity.paused => theme.colorScheme.secondary,
      TransferStatusEntity.failed => theme.colorScheme.error,
      TransferStatusEntity.complete => Colors.green,
      _ => theme.colorScheme.secondary,
    };
  }
}
