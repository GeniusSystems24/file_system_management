import 'package:dashed_circular_progress_bar/dashed_circular_progress_bar.dart';
import 'package:flutter/material.dart';

import '../domain/domain.dart';

/// Widget to display a document download item in a WhatsApp-style message bubble.
/// Document file types are pdf, doc, docx, xls, xlsx, ppt, pptx, txt, csv, etc.
/// Displays the file name, size, progress with modern WhatsApp-inspired design.
///
/// [entity] The transfer entity to display.
/// [onPause] Callback to pause the download.
/// [onResume] Callback to resume the download.
/// [onCancel] Callback to cancel the download.
/// [onRetry] Callback to retry the download.
/// [onOpen] Callback to open the completed file.
/// [onRemove] Callback to remove the task from list.
class DocumentDownloadCard extends StatelessWidget {
  final TransferEntity? entity;
  final String? fileName;
  final int? fileSize;
  final VoidCallback? onStart;
  final void Function(TransferEntity entity)? onPause;
  final void Function(TransferEntity entity)? onResume;
  final void Function(TransferEntity entity)? onCancel;
  final void Function(TransferEntity entity)? onRetry;
  final void Function(TransferEntity entity)? onOpen;
  final void Function(TransferEntity entity)? onRemove;
  final Widget Function(BuildContext context, TransferEntity entity)
      completedBuilder;
  final Widget Function(BuildContext context, TransferEntity? entity)
      loadingBuilder;
  final Widget Function(
          BuildContext context, TransferEntity? entity, String? error)?
      errorBuilder;

  /// Icon color for the download button
  final Color? iconColor;

  const DocumentDownloadCard({
    super.key,
    required this.completedBuilder,
    required this.loadingBuilder,
    this.entity,
    this.fileName,
    this.fileSize,
    this.onStart,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRetry,
    this.onOpen,
    this.onRemove,
    this.errorBuilder,
    this.iconColor,
  });

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
      case TransferStatusEntity.complete:
        return onOpen == null ? null : () => onOpen?.call(entity!);
      default:
        return onStart;
    }
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
      return DashedCircularProgressBar.square(
        dimensions: 40,
        progress: progressPercentage,
        maxProgress: 100,
        backgroundStrokeWidth: 3,
        foregroundStrokeWidth: 3,
        foregroundColor: theme.colorScheme.secondary,
        backgroundColor: foregroundColor.withValues(
          alpha: transferEntity == null ? 0.0 : 0.3,
        ),
        child: Icon(Icons.cloud_download, color: foregroundColor, size: 25),
      );
    }

    return DashedCircularProgressBar.square(
      dimensions: 40,
      progress: progressPercentage,
      maxProgress: 100,
      backgroundStrokeWidth: 3,
      foregroundStrokeWidth: 3,
      foregroundColor: theme.colorScheme.primary,
      backgroundColor: foregroundColor.withValues(alpha: 0.4),
      child: Icon(Icons.close, color: foregroundColor, size: 25),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (entity?.status == TransferStatusEntity.complete) {
      return completedBuilder(context, entity!);
    }

    final effectiveIconColor = iconColor ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Action button
          if (entity?.status != TransferStatusEntity.complete)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(1000),
                onTap: _getMainAction(),
                child: _playAndPauseButton(
                  context,
                  entity,
                  effectiveIconColor,
                  Colors.white,
                ),
              ),
            ),

          const SizedBox(width: 12),

          // Error message
          if (entity?.status == TransferStatusEntity.failed ||
              entity?.errorMessage != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entity?.errorMessage ?? 'فشل في التحميل',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(child: loadingBuilder(context, entity)),
        ],
      ),
    );
  }
}
