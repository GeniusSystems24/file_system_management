import 'package:flutter/material.dart';

import 'base_message_widget.dart';

/// A widget for displaying generic file message transfers.
///
/// This widget provides a specialized UI for general files with:
/// - File icon with extension indicator
/// - File name and size
/// - Download/upload progress
/// - Support for various file types
///
/// Example:
/// ```dart
/// FileMessageTransferWidget(
///   url: 'https://example.com/file.zip',
///   fileName: 'archive.zip',
///   fileSize: 1024 * 1024 * 50, // 50 MB
///   onDownload: (payload) => myDownloadStream(payload),
///   onOpen: (path) => openFile(path),
/// )
/// ```
class FileMessageTransferWidget extends BaseMessageTransferWidget {
  /// Custom icon for the file type.
  final IconData? customIcon;

  /// Custom icon color.
  final Color? iconColor;

  /// Custom icon background color.
  final Color? iconBackgroundColor;

  /// File extension (extracted from fileName if not provided).
  final String? extension;

  /// Builder for the completed state.
  final Widget Function(BuildContext context, String filePath)?
      completedBuilder;

  /// Whether to show the file extension badge.
  final bool showExtension;

  /// Whether to show the linear progress bar.
  final bool showLinearProgress;

  const FileMessageTransferWidget({
    super.key,
    super.config,
    super.uploadHandler,
    super.downloadHandler,
    super.url,
    super.filePath,
    super.fileName,
    super.fileSize,
    super.mimeType,
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
    this.customIcon,
    this.iconColor,
    this.iconBackgroundColor,
    this.extension,
    this.completedBuilder,
    this.showExtension = true,
    this.showLinearProgress = true,
  });

  @override
  State<FileMessageTransferWidget> createState() =>
      _FileMessageTransferWidgetState();
}

class _FileMessageTransferWidgetState
    extends BaseMessageTransferWidgetState<FileMessageTransferWidget> {
  String get _extension {
    if (widget.extension != null) return widget.extension!;
    final fileName = widget.fileName ?? '';
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1).toUpperCase();
    }
    return '';
  }

  String get _fileName => widget.fileName ?? 'File';

  IconData get _fileIcon {
    if (widget.customIcon != null) return widget.customIcon!;

    return switch (_extension.toLowerCase()) {
      'pdf' => Icons.picture_as_pdf,
      'doc' || 'docx' => Icons.description,
      'xls' || 'xlsx' => Icons.table_chart,
      'ppt' || 'pptx' => Icons.slideshow,
      'zip' || 'rar' || '7z' || 'tar' || 'gz' => Icons.folder_zip,
      'txt' || 'rtf' => Icons.article,
      'html' || 'htm' || 'css' || 'js' || 'json' || 'xml' => Icons.code,
      'apk' => Icons.android,
      'exe' || 'msi' || 'dmg' => Icons.apps,
      'mp3' || 'wav' || 'aac' || 'flac' || 'ogg' => Icons.audiotrack,
      'mp4' || 'avi' || 'mkv' || 'mov' || 'wmv' => Icons.videocam,
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' || 'bmp' => Icons.image,
      'svg' => Icons.brush,
      'psd' || 'ai' => Icons.palette,
      'ttf' || 'otf' || 'woff' => Icons.font_download,
      _ => theme.fileIcon,
    };
  }

  Color get _iconColor {
    if (widget.iconColor != null) return widget.iconColor!;

    return switch (_extension.toLowerCase()) {
      'pdf' => const Color(0xFFE53935),
      'doc' || 'docx' => const Color(0xFF2196F3),
      'xls' || 'xlsx' => const Color(0xFF4CAF50),
      'ppt' || 'pptx' => const Color(0xFFFF9800),
      'zip' || 'rar' || '7z' => const Color(0xFF795548),
      'txt' || 'rtf' => const Color(0xFF607D8B),
      'html' || 'css' || 'js' || 'json' => const Color(0xFF9C27B0),
      'apk' => const Color(0xFF3DDC84),
      _ => theme.primaryColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Custom completed builder
    if (state == TransferWidgetState.completed &&
        resultPath != null &&
        widget.completedBuilder != null) {
      return widget.completedBuilder!(context, resultPath!);
    }

    final bgColor = widget.config.direction == BubbleDirection.outgoing
        ? theme.outgoingBubbleColor
        : theme.incomingBubbleColor;

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: state == TransferWidgetState.completed ? openFile : null,
          borderRadius: borderRadius,
          child: Padding(
            padding: theme.bubblePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // File info row
                Row(
                  children: [
                    // File icon with action
                    _buildFileIcon(),

                    const SizedBox(width: 12),

                    // File details
                    Expanded(child: _buildFileDetails()),

                    // Action button (for non-completed states)
                    if (state != TransferWidgetState.completed)
                      buildActionButton(),
                  ],
                ),

                // Linear progress
                if (widget.showLinearProgress &&
                    (state == TransferWidgetState.transferring ||
                        state == TransferWidgetState.paused))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: buildLinearProgress(),
                  ),

                // Error message
                if (state == TransferWidgetState.failed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: buildErrorMessage(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon() {
    final iconBgColor = widget.iconBackgroundColor ?? _iconColor.withOpacity(0.15);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: iconBgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _fileIcon,
            color: _iconColor,
            size: 28,
          ),

          // Extension badge
          if (widget.showExtension && _extension.isNotEmpty)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: _iconColor,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  _extension.length > 4
                      ? _extension.substring(0, 4)
                      : _extension,
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Completed checkmark
          if (state == TransferWidgetState.completed)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.successColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.bubbleColor,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // File name
        Text(
          _fileName,
          style: theme.fileNameStyle ??
              TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: theme.textColor,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 2),

        // Status or file info
        _buildStatusInfo(),
      ],
    );
  }

  Widget _buildStatusInfo() {
    switch (state) {
      case TransferWidgetState.idle:
        return _buildFileSizeText();

      case TransferWidgetState.pending:
        return Text(
          'في الانتظار...',
          style: theme.statusStyle ??
              TextStyle(fontSize: 12, color: theme.subtitleColor),
        );

      case TransferWidgetState.transferring:
        final parts = <String>[progress.progressText];
        if (widget.config.showSpeed) parts.add(progress.speedText);
        if (widget.config.showFileSize) {
          parts.add('${progress.bytesTransferredText}/${progress.totalBytesText}');
        }
        return Text(
          parts.join(' • '),
          style: theme.statusStyle ??
              TextStyle(fontSize: 12, color: theme.primaryColor),
        );

      case TransferWidgetState.paused:
        return Row(
          children: [
            Icon(Icons.pause, size: 12, color: theme.pausedColor),
            const SizedBox(width: 4),
            Text(
              'متوقف - ${progress.progressText}',
              style: TextStyle(fontSize: 12, color: theme.pausedColor),
            ),
          ],
        );

      case TransferWidgetState.completed:
        return Row(
          children: [
            Icon(Icons.check, size: 12, color: theme.successColor),
            const SizedBox(width: 4),
            _buildFileSizeText(),
          ],
        );

      case TransferWidgetState.failed:
        return Row(
          children: [
            Icon(Icons.error_outline, size: 12, color: theme.errorColor),
            const SizedBox(width: 4),
            Text(
              'فشل - انقر للإعادة',
              style: TextStyle(fontSize: 12, color: theme.errorColor),
            ),
          ],
        );

      case TransferWidgetState.cancelled:
        return Text(
          'ملغى',
          style: TextStyle(fontSize: 12, color: theme.subtitleColor),
        );
    }
  }

  Widget _buildFileSizeText() {
    if (widget.fileSize == null || widget.fileSize! <= 0) {
      return Text(
        _extension.isNotEmpty ? _extension : 'ملف',
        style: theme.fileSizeStyle ??
            TextStyle(fontSize: 12, color: theme.subtitleColor),
      );
    }

    return Text(
      _formatBytes(widget.fileSize!),
      style: theme.fileSizeStyle ??
          TextStyle(fontSize: 12, color: theme.subtitleColor),
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
}
