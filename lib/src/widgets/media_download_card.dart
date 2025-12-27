import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:flutter/material.dart';

import '../domain/domain.dart';

/// Widget to display a media download item in a message bubble.
/// Media file types are image and video.
///
/// Displays the download progress.
///
/// [entity] The transfer entity to display.
/// [onStart] Callback to start the download.
/// [onPause] Callback to pause the download.
/// [onResume] Callback to resume the download.
/// [onCancel] Callback to cancel the download.
/// [onRetry] Callback to retry the download.
/// [completedBuilder] Callback to build the completed widget.
/// [emptyBuilder] Callback to build the empty widget.
/// [errorBuilder] Callback to build the error widget.
/// [thumbnailUrl] The URL of the thumbnail.
/// [thumbnailProvider] The provider of the thumbnail.
class MediaDownloadCard extends StatelessWidget {
  final TransferEntity? entity;
  final VoidCallback? onStart;
  final void Function(TransferEntity entity)? onPause;
  final void Function(TransferEntity entity)? onResume;
  final void Function(TransferEntity entity)? onCancel;
  final void Function(TransferEntity entity)? onRetry;
  final Widget Function(BuildContext context, TransferEntity entity)
      completedBuilder;
  final Widget Function(BuildContext context)? emptyBuilder;
  final Widget Function(
          BuildContext context, TransferEntity? entity, String? error)?
      errorBuilder;

  // Enhanced thumbnail support
  final String? thumbnailUrl;
  final ImageProvider? thumbnailProvider;
  final Widget? thumbnailWidget;
  final BoxFit thumbnailFit;
  final bool showThumbnailOverlay;
  final double thumbnailOpacity;
  final BorderRadius? thumbnailBorderRadius;
  final bool isVideo;
  final bool showActionButton;

  const MediaDownloadCard({
    super.key,
    required this.completedBuilder,
    this.entity,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRetry,
    this.emptyBuilder,
    this.errorBuilder,
    // Thumbnail parameters
    this.thumbnailUrl,
    this.thumbnailProvider,
    this.thumbnailWidget,
    this.thumbnailFit = BoxFit.cover,
    this.showThumbnailOverlay = true,
    this.thumbnailOpacity = 1.0,
    this.thumbnailBorderRadius,
    this.isVideo = false,
    this.showActionButton = true,
  });

  bool get isCompleted =>
      entity?.progress == 1 ||
      entity?.status == TransferStatusEntity.complete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background
        ..._buildBackground(context),

        if (isCompleted) completedBuilder(context, entity!),

        // Center action button
        if (!isCompleted) _buildCenterAction(context),
      ],
    );
  }

  List<Widget> _buildBackground(BuildContext context) {
    // Check if we have thumbnail to display
    if (_hasThumbnail()) {
      return _buildThumbnailBackground(context);
    }

    return [emptyBuilder?.call(context) ?? Container()];
  }

  Widget _buildCenterAction(BuildContext context) {
    final theme = Theme.of(context);
    final foregroundColor = theme.colorScheme.onSurface;
    final backgroundColor = theme.colorScheme.surface;

    return Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: InkWell(
          borderRadius: BorderRadius.circular(1000),
          onTap: showActionButton ? _getMainAction() : null,
          child: _playAndPauseButton(
            context,
            entity,
            foregroundColor,
            backgroundColor,
          ),
        ),
      ),
    );
  }

  Widget _playAndPauseButton(
    BuildContext context,
    TransferEntity? transferEntity,
    Color foregroundColor,
    Color backgroundColor,
  ) {
    final theme = Theme.of(context);

    final progressPercentage = (transferEntity?.progress ?? 0) * 100;

    if (transferEntity?.status != TransferStatusEntity.running) {
      return SizedBox(
        width: 40,
        height: 40,
        child: DashedCircularProgressBar.square(
          dimensions: 360,
          progress: progressPercentage,
          maxProgress: 100,
          backgroundStrokeWidth: 3,
          foregroundStrokeWidth: 3,
          foregroundColor: theme.colorScheme.secondary,
          backgroundColor: foregroundColor.withValues(
            alpha: transferEntity == null ? 0.0 : 0.3,
          ),
          animation: true,
          child: showActionButton
              ? Icon(Icons.cloud_download, color: foregroundColor, size: 20)
              : Container(),
        ),
      );
    }

    if (transferEntity?.status == TransferStatusEntity.running) {
      return SizedBox(
        width: 40,
        height: 40,
        child: DashedCircularProgressBar.square(
          dimensions: 360,
          progress: progressPercentage,
          maxProgress: 100,
          backgroundStrokeWidth: 3,
          foregroundStrokeWidth: 3,
          foregroundColor: theme.colorScheme.primary,
          backgroundColor: foregroundColor.withValues(alpha: 0.4),
          animation: true,
          child: showActionButton
              ? Icon(Icons.close, color: foregroundColor, size: 20)
              : Container(),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  bool _hasThumbnail() {
    return thumbnailUrl != null ||
        thumbnailProvider != null ||
        thumbnailWidget != null;
  }

  List<Widget> _buildThumbnailBackground(BuildContext context) {
    final theme = Theme.of(context);
    return [
      // Thumbnail layer
      Positioned.fill(
        child: Opacity(
          opacity: thumbnailOpacity,
          child: _buildThumbnailWidget(context),
        ),
      ),

      // Overlay for better content visibility
      if (showThumbnailOverlay)
        Positioned.fill(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: thumbnailBorderRadius),
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
    // Priority: Custom widget > File > URL
    if (thumbnailWidget != null) {
      return thumbnailWidget!;
    }

    if (thumbnailProvider != null) {
      return Image(
        image: thumbnailProvider!,
        fit: thumbnailFit,
        errorBuilder: (context, error, stackTrace) {
          return _buildThumbnailError(context);
        },
      );
    }

    if (thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: thumbnailUrl!,
        fit: thumbnailFit,
        progressIndicatorBuilder: (context, child, loadingProgress) =>
            _buildThumbnailLoading(context, loadingProgress),
        errorWidget: (context, url, error) => _buildThumbnailError(context),
      );
    }

    // Fallback to gradient background
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

  VoidCallback? _getMainAction() {
    switch (entity?.status) {
      case TransferStatusEntity.running:
        return (entity?.allowPause ?? false)
            ? onPause == null
                ? null
                : () => onPause?.call(entity!)
            : null;
      case TransferStatusEntity.paused:
        return onResume == null ? null : () => onResume?.call(entity!);
      case TransferStatusEntity.failed:
        return onRetry == null ? null : () => onRetry?.call(entity!);
      default:
        return onStart;
    }
  }
}
