import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'base_message_widget.dart';

/// A widget for displaying document message transfers.
///
/// This widget provides a specialized UI for documents (PDF, DOCX, etc.) with:
/// - Document type icon with color coding
/// - Page count display (optional)
/// - Thumbnail preview (optional)
/// - Progress tracking during upload/download
///
/// Example:
/// ```dart
/// DocumentMessageTransferWidget(
///   url: 'https://example.com/document.pdf',
///   fileName: 'report.pdf',
///   fileSize: 1024 * 1024 * 2, // 2 MB
///   pageCount: 15,
///   onDownload: (payload) => myDownloadStream(payload),
///   onOpen: (path) => openPdfViewer(path),
/// )
/// ```
class DocumentMessageTransferWidget extends BaseMessageTransferWidget {
  /// Number of pages in the document.
  final int? pageCount;

  /// Thumbnail of the first page.
  final Uint8List? thumbnailBytes;

  /// Thumbnail provider.
  final ImageProvider? thumbnailProvider;

  /// Custom document icon.
  final IconData? customIcon;

  /// Custom icon color.
  final Color? iconColor;

  /// Whether to show the thumbnail preview.
  final bool showThumbnail;

  /// Whether to show page count.
  final bool showPageCount;

  /// Document type (auto-detected from extension if not provided).
  final DocumentType? documentType;

  /// Builder for the completed state.
  final Widget Function(BuildContext context, String filePath)?
      completedBuilder;

  const DocumentMessageTransferWidget({
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
    this.pageCount,
    this.thumbnailBytes,
    this.thumbnailProvider,
    this.customIcon,
    this.iconColor,
    this.showThumbnail = false,
    this.showPageCount = true,
    this.documentType,
    this.completedBuilder,
  });

  @override
  State<DocumentMessageTransferWidget> createState() =>
      _DocumentMessageTransferWidgetState();
}

class _DocumentMessageTransferWidgetState
    extends BaseMessageTransferWidgetState<DocumentMessageTransferWidget> {
  DocumentType get _documentType {
    if (widget.documentType != null) return widget.documentType!;

    final fileName = widget.fileName ?? '';
    final extension = fileName.split('.').last.toLowerCase();

    return switch (extension) {
      'pdf' => DocumentType.pdf,
      'doc' || 'docx' => DocumentType.word,
      'xls' || 'xlsx' => DocumentType.excel,
      'ppt' || 'pptx' => DocumentType.powerpoint,
      'txt' || 'rtf' => DocumentType.text,
      'csv' => DocumentType.csv,
      _ => DocumentType.other,
    };
  }

  IconData get _documentIcon {
    if (widget.customIcon != null) return widget.customIcon!;

    return switch (_documentType) {
      DocumentType.pdf => Icons.picture_as_pdf,
      DocumentType.word => Icons.description,
      DocumentType.excel => Icons.table_chart,
      DocumentType.powerpoint => Icons.slideshow,
      DocumentType.text => Icons.article,
      DocumentType.csv => Icons.grid_on,
      DocumentType.other => theme.documentIcon,
    };
  }

  Color get _documentColor {
    if (widget.iconColor != null) return widget.iconColor!;

    return switch (_documentType) {
      DocumentType.pdf => const Color(0xFFE53935),
      DocumentType.word => const Color(0xFF2196F3),
      DocumentType.excel => const Color(0xFF4CAF50),
      DocumentType.powerpoint => const Color(0xFFFF9800),
      DocumentType.text => const Color(0xFF607D8B),
      DocumentType.csv => const Color(0xFF009688),
      DocumentType.other => theme.primaryColor,
    };
  }

  String get _documentTypeLabel {
    return switch (_documentType) {
      DocumentType.pdf => 'PDF',
      DocumentType.word => 'Word',
      DocumentType.excel => 'Excel',
      DocumentType.powerpoint => 'PowerPoint',
      DocumentType.text => 'نص',
      DocumentType.csv => 'CSV',
      DocumentType.other => 'مستند',
    };
  }

  String get _fileName => widget.fileName ?? 'Document';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thumbnail (if available)
              if (widget.showThumbnail && _hasThumbnail) _buildThumbnail(),

              // Document info
              Padding(
                padding: theme.bubblePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Document icon
                        _buildDocumentIcon(),

                        const SizedBox(width: 12),

                        // Document details
                        Expanded(child: _buildDocumentDetails()),

                        // Action button
                        if (state != TransferWidgetState.completed)
                          buildActionButton(),
                      ],
                    ),

                    // Progress bar
                    if (state == TransferWidgetState.transferring ||
                        state == TransferWidgetState.paused)
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
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasThumbnail =>
      widget.thumbnailBytes != null || widget.thumbnailProvider != null;

  Widget _buildThumbnail() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _documentColor.withOpacity(0.1),
        borderRadius: BorderRadius.only(
          topLeft: theme.bubbleBorderRadius.topLeft,
          topRight: theme.bubbleBorderRadius.topRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: theme.bubbleBorderRadius.topLeft,
          topRight: theme.bubbleBorderRadius.topRight,
        ),
        child: _buildThumbnailContent(),
      ),
    );
  }

  Widget _buildThumbnailContent() {
    if (widget.thumbnailProvider != null) {
      return Image(
        image: widget.thumbnailProvider!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _buildThumbnailPlaceholder(),
      );
    }

    if (widget.thumbnailBytes != null) {
      return Image.memory(
        widget.thumbnailBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => _buildThumbnailPlaceholder(),
      );
    }

    return _buildThumbnailPlaceholder();
  }

  Widget _buildThumbnailPlaceholder() {
    return Center(
      child: Icon(
        _documentIcon,
        size: 48,
        color: _documentColor.withOpacity(0.5),
      ),
    );
  }

  Widget _buildDocumentIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _documentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _documentIcon,
            color: _documentColor,
            size: 28,
          ),

          // Type badge
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
              decoration: BoxDecoration(
                color: _documentColor,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                _documentTypeLabel.length > 4
                    ? _documentTypeLabel.substring(0, 4)
                    : _documentTypeLabel,
                style: const TextStyle(
                  fontSize: 6,
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

  Widget _buildDocumentDetails() {
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 2),

        // Info row
        _buildInfoRow(),
      ],
    );
  }

  Widget _buildInfoRow() {
    final parts = <Widget>[];

    // Document type
    parts.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: _documentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Text(
          _documentTypeLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _documentColor,
          ),
        ),
      ),
    );

    // Page count
    if (widget.showPageCount && widget.pageCount != null) {
      parts.add(const SizedBox(width: 8));
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 12,
              color: theme.subtitleColor,
            ),
            const SizedBox(width: 2),
            Text(
              '${widget.pageCount} صفحة',
              style: TextStyle(
                fontSize: 11,
                color: theme.subtitleColor,
              ),
            ),
          ],
        ),
      );
    }

    // File size or status
    parts.add(const SizedBox(width: 8));
    parts.add(_buildStatusText());

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: parts,
    );
  }

  Widget _buildStatusText() {
    switch (state) {
      case TransferWidgetState.transferring:
        return Text(
          '${progress.progressText} • ${progress.speedText}',
          style: TextStyle(
            fontSize: 11,
            color: theme.primaryColor,
          ),
        );

      case TransferWidgetState.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause, size: 10, color: theme.pausedColor),
            const SizedBox(width: 2),
            Text(
              progress.progressText,
              style: TextStyle(
                fontSize: 11,
                color: theme.pausedColor,
              ),
            ),
          ],
        );

      case TransferWidgetState.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 10, color: theme.errorColor),
            const SizedBox(width: 2),
            Text(
              'فشل',
              style: TextStyle(
                fontSize: 11,
                color: theme.errorColor,
              ),
            ),
          ],
        );

      case TransferWidgetState.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, size: 10, color: theme.successColor),
            const SizedBox(width: 2),
            if (widget.fileSize != null)
              Text(
                _formatBytes(widget.fileSize!),
                style: TextStyle(
                  fontSize: 11,
                  color: theme.subtitleColor,
                ),
              ),
          ],
        );

      default:
        if (widget.fileSize != null) {
          return Text(
            _formatBytes(widget.fileSize!),
            style: TextStyle(
              fontSize: 11,
              color: theme.subtitleColor,
            ),
          );
        }
        return const SizedBox.shrink();
    }
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

/// Type of document.
enum DocumentType {
  /// PDF document.
  pdf,

  /// Microsoft Word document.
  word,

  /// Microsoft Excel spreadsheet.
  excel,

  /// Microsoft PowerPoint presentation.
  powerpoint,

  /// Plain text file.
  text,

  /// CSV file.
  csv,

  /// Other document type.
  other,
}
