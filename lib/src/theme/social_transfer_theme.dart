import 'dart:ui';

import 'package:flutter/material.dart';

/// Available social media skins for transfer widgets.
enum SocialSkin {
  /// WhatsApp-inspired design.
  whatsapp,

  /// Telegram-inspired design.
  telegram,

  /// Instagram-inspired design.
  instagram,

  /// Custom/default design.
  custom,
}

/// Theme data for social transfer widgets.
///
/// This class provides comprehensive theming support for transfer widgets,
/// allowing customization of colors, typography, shapes, and more.
///
/// Example:
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [SocialTransferThemeData.whatsapp()],
///   ),
/// )
///
/// // Access in widgets:
/// final theme = Theme.of(context).extension<SocialTransferThemeData>();
/// // Or use the extension:
/// final theme = context.socialTransferTheme;
/// ```
class SocialTransferThemeData extends ThemeExtension<SocialTransferThemeData> {
  /// The skin type being used.
  final SocialSkin skin;

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Primary color for progress indicators and actions.
  final Color primaryColor;

  /// Secondary color for accents.
  final Color secondaryColor;

  /// Background color for message bubbles.
  final Color bubbleColor;

  /// Background color for incoming message bubbles.
  final Color incomingBubbleColor;

  /// Background color for outgoing message bubbles.
  final Color outgoingBubbleColor;

  /// Color for progress bar background.
  final Color progressBackgroundColor;

  /// Color for progress bar foreground.
  final Color progressForegroundColor;

  /// Color for success states.
  final Color successColor;

  /// Color for error states.
  final Color errorColor;

  /// Color for warning states.
  final Color warningColor;

  /// Color for paused states.
  final Color pausedColor;

  /// Text color for primary text.
  final Color textColor;

  /// Text color for secondary/subtitle text.
  final Color subtitleColor;

  /// Icon color.
  final Color iconColor;

  /// Overlay color for media thumbnails.
  final Color overlayColor;

  // ═══════════════════════════════════════════════════════════════════════════
  // SHAPES & BORDERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Border radius for message bubbles.
  final BorderRadius bubbleBorderRadius;

  /// Border radius for incoming message bubbles.
  final BorderRadius incomingBubbleBorderRadius;

  /// Border radius for outgoing message bubbles.
  final BorderRadius outgoingBubbleBorderRadius;

  /// Border radius for progress indicators.
  final BorderRadius progressBorderRadius;

  /// Border radius for action buttons.
  final BorderRadius buttonBorderRadius;

  /// Border radius for thumbnails.
  final BorderRadius thumbnailBorderRadius;

  /// Border for message bubbles.
  final Border? bubbleBorder;

  /// Box shadow for message bubbles.
  final List<BoxShadow>? bubbleShadow;

  // ═══════════════════════════════════════════════════════════════════════════
  // SIZING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Size of the action button (download/upload/pause).
  final double actionButtonSize;

  /// Size of small icons.
  final double smallIconSize;

  /// Size of medium icons.
  final double mediumIconSize;

  /// Size of large icons.
  final double largeIconSize;

  /// Stroke width for progress indicators.
  final double progressStrokeWidth;

  /// Height of linear progress bars.
  final double linearProgressHeight;

  /// Maximum width for message bubbles.
  final double maxBubbleWidth;

  /// Minimum width for message bubbles.
  final double minBubbleWidth;

  /// Padding inside message bubbles.
  final EdgeInsets bubblePadding;

  /// Margin around message bubbles.
  final EdgeInsets bubbleMargin;

  /// Padding for content inside bubbles.
  final EdgeInsets contentPadding;

  // ═══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Text style for file names.
  final TextStyle? fileNameStyle;

  /// Text style for file size.
  final TextStyle? fileSizeStyle;

  /// Text style for progress percentage.
  final TextStyle? progressStyle;

  /// Text style for status text.
  final TextStyle? statusStyle;

  /// Text style for speed/ETA.
  final TextStyle? speedStyle;

  /// Text style for duration (audio/video).
  final TextStyle? durationStyle;

  /// Text style for error messages.
  final TextStyle? errorStyle;

  // ═══════════════════════════════════════════════════════════════════════════
  // ICONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Icon for download action.
  final IconData downloadIcon;

  /// Icon for upload action.
  final IconData uploadIcon;

  /// Icon for pause action.
  final IconData pauseIcon;

  /// Icon for resume action.
  final IconData resumeIcon;

  /// Icon for cancel action.
  final IconData cancelIcon;

  /// Icon for retry action.
  final IconData retryIcon;

  /// Icon for play action (audio/video).
  final IconData playIcon;

  /// Icon for file type.
  final IconData fileIcon;

  /// Icon for document type.
  final IconData documentIcon;

  /// Icon for image type.
  final IconData imageIcon;

  /// Icon for video type.
  final IconData videoIcon;

  /// Icon for audio type.
  final IconData audioIcon;

  /// Icon for success state.
  final IconData successIcon;

  /// Icon for error state.
  final IconData errorIcon;

  // ═══════════════════════════════════════════════════════════════════════════
  // ANIMATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Duration for progress animations.
  final Duration progressAnimationDuration;

  /// Curve for progress animations.
  final Curve progressAnimationCurve;

  /// Duration for state transition animations.
  final Duration stateAnimationDuration;

  /// Curve for state transition animations.
  final Curve stateAnimationCurve;

  // ═══════════════════════════════════════════════════════════════════════════
  // BEHAVIOR
  // ═══════════════════════════════════════════════════════════════════════════

  /// Whether to show file size.
  final bool showFileSize;

  /// Whether to show transfer speed.
  final bool showSpeed;

  /// Whether to show estimated time remaining.
  final bool showEta;

  /// Whether to show progress percentage.
  final bool showProgressPercent;

  /// Whether to show linear progress bar.
  final bool showLinearProgress;

  /// Whether to show circular progress indicator.
  final bool showCircularProgress;

  /// Whether to use blur overlay on thumbnails.
  final bool useBlurOverlay;

  /// Sigma for blur effect.
  final double blurSigma;

  const SocialTransferThemeData({
    this.skin = SocialSkin.custom,
    // Colors
    required this.primaryColor,
    required this.secondaryColor,
    required this.bubbleColor,
    Color? incomingBubbleColor,
    Color? outgoingBubbleColor,
    required this.progressBackgroundColor,
    required this.progressForegroundColor,
    required this.successColor,
    required this.errorColor,
    required this.warningColor,
    required this.pausedColor,
    required this.textColor,
    required this.subtitleColor,
    required this.iconColor,
    required this.overlayColor,
    // Shapes
    required this.bubbleBorderRadius,
    BorderRadius? incomingBubbleBorderRadius,
    BorderRadius? outgoingBubbleBorderRadius,
    required this.progressBorderRadius,
    required this.buttonBorderRadius,
    required this.thumbnailBorderRadius,
    this.bubbleBorder,
    this.bubbleShadow,
    // Sizing
    this.actionButtonSize = 48,
    this.smallIconSize = 16,
    this.mediumIconSize = 24,
    this.largeIconSize = 32,
    this.progressStrokeWidth = 3,
    this.linearProgressHeight = 4,
    this.maxBubbleWidth = 280,
    this.minBubbleWidth = 100,
    this.bubblePadding = const EdgeInsets.all(8),
    this.bubbleMargin = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.contentPadding = const EdgeInsets.all(12),
    // Typography
    this.fileNameStyle,
    this.fileSizeStyle,
    this.progressStyle,
    this.statusStyle,
    this.speedStyle,
    this.durationStyle,
    this.errorStyle,
    // Icons
    this.downloadIcon = Icons.cloud_download_outlined,
    this.uploadIcon = Icons.cloud_upload_outlined,
    this.pauseIcon = Icons.pause,
    this.resumeIcon = Icons.play_arrow,
    this.cancelIcon = Icons.close,
    this.retryIcon = Icons.refresh,
    this.playIcon = Icons.play_arrow,
    this.fileIcon = Icons.insert_drive_file_outlined,
    this.documentIcon = Icons.description_outlined,
    this.imageIcon = Icons.image_outlined,
    this.videoIcon = Icons.videocam_outlined,
    this.audioIcon = Icons.audiotrack_outlined,
    this.successIcon = Icons.check_circle,
    this.errorIcon = Icons.error_outline,
    // Animation
    this.progressAnimationDuration = const Duration(milliseconds: 200),
    this.progressAnimationCurve = Curves.easeInOut,
    this.stateAnimationDuration = const Duration(milliseconds: 300),
    this.stateAnimationCurve = Curves.easeInOut,
    // Behavior
    this.showFileSize = true,
    this.showSpeed = true,
    this.showEta = false,
    this.showProgressPercent = true,
    this.showLinearProgress = true,
    this.showCircularProgress = true,
    this.useBlurOverlay = true,
    this.blurSigma = 8.0,
  }) : incomingBubbleColor = incomingBubbleColor ?? bubbleColor,
       outgoingBubbleColor = outgoingBubbleColor ?? bubbleColor,
       incomingBubbleBorderRadius =
           incomingBubbleBorderRadius ?? bubbleBorderRadius,
       outgoingBubbleBorderRadius =
           outgoingBubbleBorderRadius ?? bubbleBorderRadius;

  /// Creates a WhatsApp-inspired theme.
  factory SocialTransferThemeData.whatsapp({bool isDark = false}) {
    if (isDark) {
      return SocialTransferThemeData(
        skin: SocialSkin.whatsapp,
        primaryColor: const Color(0xFF00A884),
        secondaryColor: const Color(0xFF25D366),
        bubbleColor: const Color(0xFF1F2C34),
        incomingBubbleColor: const Color(0xFF1F2C34),
        outgoingBubbleColor: const Color(0xFF005C4B),
        progressBackgroundColor: Colors.white24,
        progressForegroundColor: const Color(0xFF00A884),
        successColor: const Color(0xFF00A884),
        errorColor: const Color(0xFFEF5350),
        warningColor: const Color(0xFFFFB300),
        pausedColor: const Color(0xFFFFB300),
        textColor: const Color(0xFFE9EDEF),
        subtitleColor: const Color(0xFF8696A0),
        iconColor: const Color(0xFF8696A0),
        overlayColor: Colors.black45,
        bubbleBorderRadius: BorderRadius.circular(12),
        incomingBubbleBorderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        outgoingBubbleBorderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        progressBorderRadius: BorderRadius.circular(2),
        buttonBorderRadius: BorderRadius.circular(24),
        thumbnailBorderRadius: BorderRadius.circular(8),
        fileNameStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE9EDEF),
        ),
        fileSizeStyle: const TextStyle(fontSize: 12, color: Color(0xFF8696A0)),
        showEta: false,
      );
    }

    return SocialTransferThemeData(
      skin: SocialSkin.whatsapp,
      primaryColor: const Color(0xFF00A884),
      secondaryColor: const Color(0xFF25D366),
      bubbleColor: Colors.white,
      incomingBubbleColor: Colors.white,
      outgoingBubbleColor: const Color(0xFFD9FDD3),
      progressBackgroundColor: Colors.black12,
      progressForegroundColor: const Color(0xFF00A884),
      successColor: const Color(0xFF00A884),
      errorColor: const Color(0xFFEF5350),
      warningColor: const Color(0xFFFFB300),
      pausedColor: const Color(0xFFFFB300),
      textColor: const Color(0xFF111B21),
      subtitleColor: const Color(0xFF667781),
      iconColor: const Color(0xFF667781),
      overlayColor: Colors.black38,
      bubbleBorderRadius: BorderRadius.circular(12),
      incomingBubbleBorderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(12),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      outgoingBubbleBorderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(4),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      progressBorderRadius: BorderRadius.circular(2),
      buttonBorderRadius: BorderRadius.circular(24),
      thumbnailBorderRadius: BorderRadius.circular(8),
      fileNameStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF111B21),
      ),
      fileSizeStyle: const TextStyle(fontSize: 12, color: Color(0xFF667781)),
      showEta: false,
    );
  }

  /// Creates a Telegram-inspired theme.
  factory SocialTransferThemeData.telegram({bool isDark = false}) {
    if (isDark) {
      return SocialTransferThemeData(
        skin: SocialSkin.telegram,
        primaryColor: const Color(0xFF5EBBFF),
        secondaryColor: const Color(0xFF5EBBFF),
        bubbleColor: const Color(0xFF212121),
        incomingBubbleColor: const Color(0xFF212121),
        outgoingBubbleColor: const Color(0xFF2B5278),
        progressBackgroundColor: Colors.white24,
        progressForegroundColor: const Color(0xFF5EBBFF),
        successColor: const Color(0xFF5EBBFF),
        errorColor: const Color(0xFFFF6B6B),
        warningColor: const Color(0xFFFFD93D),
        pausedColor: const Color(0xFFFFD93D),
        textColor: Colors.white,
        subtitleColor: const Color(0xFF8A8A8A),
        iconColor: const Color(0xFF5EBBFF),
        overlayColor: Colors.black54,
        bubbleBorderRadius: BorderRadius.circular(16),
        incomingBubbleBorderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        outgoingBubbleBorderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(4),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        progressBorderRadius: BorderRadius.circular(4),
        buttonBorderRadius: BorderRadius.circular(20),
        thumbnailBorderRadius: BorderRadius.circular(12),
        actionButtonSize: 44,
        progressStrokeWidth: 2.5,
        downloadIcon: Icons.arrow_downward,
        uploadIcon: Icons.arrow_upward,
        cancelIcon: Icons.stop,
        fileNameStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        fileSizeStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
        showSpeed: true,
        showEta: true,
      );
    }

    return SocialTransferThemeData(
      skin: SocialSkin.telegram,
      primaryColor: const Color(0xFF3390EC),
      secondaryColor: const Color(0xFF3390EC),
      bubbleColor: Colors.white,
      incomingBubbleColor: Colors.white,
      outgoingBubbleColor: const Color(0xFFEEFFDE),
      progressBackgroundColor: Colors.black12,
      progressForegroundColor: const Color(0xFF3390EC),
      successColor: const Color(0xFF3390EC),
      errorColor: const Color(0xFFE53935),
      warningColor: const Color(0xFFFF9800),
      pausedColor: const Color(0xFFFF9800),
      textColor: Colors.black87,
      subtitleColor: const Color(0xFF8A8A8A),
      iconColor: const Color(0xFF3390EC),
      overlayColor: Colors.black38,
      bubbleBorderRadius: BorderRadius.circular(16),
      incomingBubbleBorderRadius: const BorderRadius.only(
        topLeft: Radius.circular(4),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      outgoingBubbleBorderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(4),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      progressBorderRadius: BorderRadius.circular(4),
      buttonBorderRadius: BorderRadius.circular(20),
      thumbnailBorderRadius: BorderRadius.circular(12),
      actionButtonSize: 44,
      progressStrokeWidth: 2.5,
      downloadIcon: Icons.arrow_downward,
      uploadIcon: Icons.arrow_upward,
      cancelIcon: Icons.stop,
      bubbleShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
      fileNameStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
      fileSizeStyle: const TextStyle(fontSize: 13, color: Color(0xFF8A8A8A)),
      showSpeed: true,
      showEta: true,
    );
  }

  /// Creates an Instagram-inspired theme.
  factory SocialTransferThemeData.instagram({bool isDark = false}) {
    if (isDark) {
      return SocialTransferThemeData(
        skin: SocialSkin.instagram,
        primaryColor: const Color(0xFFE1306C),
        secondaryColor: const Color(0xFFF77737),
        bubbleColor: const Color(0xFF262626),
        incomingBubbleColor: const Color(0xFF262626),
        outgoingBubbleColor: const Color(0xFF3797F0),
        progressBackgroundColor: Colors.white24,
        progressForegroundColor: const Color(0xFFE1306C),
        successColor: const Color(0xFF4BB543),
        errorColor: const Color(0xFFED4956),
        warningColor: const Color(0xFFFFC107),
        pausedColor: const Color(0xFFFFC107),
        textColor: const Color(0xFFFAFAFA),
        subtitleColor: const Color(0xFFA8A8A8),
        iconColor: const Color(0xFFFAFAFA),
        overlayColor: Colors.black54,
        bubbleBorderRadius: BorderRadius.circular(22),
        progressBorderRadius: BorderRadius.circular(2),
        buttonBorderRadius: BorderRadius.circular(22),
        thumbnailBorderRadius: BorderRadius.circular(8),
        actionButtonSize: 40,
        progressStrokeWidth: 2,
        maxBubbleWidth: 260,
        downloadIcon: Icons.download_rounded,
        uploadIcon: Icons.upload_rounded,
        cancelIcon: Icons.close_rounded,
        retryIcon: Icons.refresh_rounded,
        bubblePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        fileNameStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFAFAFA),
        ),
        fileSizeStyle: const TextStyle(fontSize: 12, color: Color(0xFFA8A8A8)),
        showLinearProgress: false,
        showCircularProgress: true,
        blurSigma: 10.0,
      );
    }

    return SocialTransferThemeData(
      skin: SocialSkin.instagram,
      primaryColor: const Color(0xFFE1306C),
      secondaryColor: const Color(0xFFF77737),
      bubbleColor: const Color(0xFFEFEFEF),
      incomingBubbleColor: const Color(0xFFEFEFEF),
      outgoingBubbleColor: const Color(0xFF3797F0),
      progressBackgroundColor: Colors.black12,
      progressForegroundColor: const Color(0xFFE1306C),
      successColor: const Color(0xFF4BB543),
      errorColor: const Color(0xFFED4956),
      warningColor: const Color(0xFFFFC107),
      pausedColor: const Color(0xFFFFC107),
      textColor: const Color(0xFF262626),
      subtitleColor: const Color(0xFF8E8E8E),
      iconColor: const Color(0xFF262626),
      overlayColor: Colors.black38,
      bubbleBorderRadius: BorderRadius.circular(22),
      progressBorderRadius: BorderRadius.circular(2),
      buttonBorderRadius: BorderRadius.circular(22),
      thumbnailBorderRadius: BorderRadius.circular(8),
      actionButtonSize: 40,
      progressStrokeWidth: 2,
      maxBubbleWidth: 260,
      downloadIcon: Icons.download_rounded,
      uploadIcon: Icons.upload_rounded,
      cancelIcon: Icons.close_rounded,
      retryIcon: Icons.refresh_rounded,
      bubblePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      fileNameStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF262626),
      ),
      fileSizeStyle: const TextStyle(fontSize: 12, color: Color(0xFF8E8E8E)),
      showLinearProgress: false,
      showCircularProgress: true,
      blurSigma: 10.0,
    );
  }

  /// Creates a theme from the current [BuildContext].
  factory SocialTransferThemeData.of(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SocialTransferThemeData(
      primaryColor: colorScheme.primary,
      secondaryColor: colorScheme.secondary,
      bubbleColor:
          isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface,
      progressBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
      progressForegroundColor: colorScheme.primary,
      successColor: Colors.green,
      errorColor: colorScheme.error,
      warningColor: Colors.orange,
      pausedColor: Colors.orange,
      textColor: colorScheme.onSurface,
      subtitleColor: colorScheme.onSurfaceVariant,
      iconColor: colorScheme.onSurfaceVariant,
      overlayColor: Colors.black38,
      bubbleBorderRadius: BorderRadius.circular(12),
      progressBorderRadius: BorderRadius.circular(4),
      buttonBorderRadius: BorderRadius.circular(20),
      thumbnailBorderRadius: BorderRadius.circular(8),
    );
  }

  /// Creates a copy with updated values.
  @override
  SocialTransferThemeData copyWith({
    SocialSkin? skin,
    Color? primaryColor,
    Color? secondaryColor,
    Color? bubbleColor,
    Color? incomingBubbleColor,
    Color? outgoingBubbleColor,
    Color? progressBackgroundColor,
    Color? progressForegroundColor,
    Color? successColor,
    Color? errorColor,
    Color? warningColor,
    Color? pausedColor,
    Color? textColor,
    Color? subtitleColor,
    Color? iconColor,
    Color? overlayColor,
    BorderRadius? bubbleBorderRadius,
    BorderRadius? incomingBubbleBorderRadius,
    BorderRadius? outgoingBubbleBorderRadius,
    BorderRadius? progressBorderRadius,
    BorderRadius? buttonBorderRadius,
    BorderRadius? thumbnailBorderRadius,
    Border? bubbleBorder,
    List<BoxShadow>? bubbleShadow,
    double? actionButtonSize,
    double? smallIconSize,
    double? mediumIconSize,
    double? largeIconSize,
    double? progressStrokeWidth,
    double? linearProgressHeight,
    double? maxBubbleWidth,
    double? minBubbleWidth,
    EdgeInsets? bubblePadding,
    EdgeInsets? bubbleMargin,
    EdgeInsets? contentPadding,
    TextStyle? fileNameStyle,
    TextStyle? fileSizeStyle,
    TextStyle? progressStyle,
    TextStyle? statusStyle,
    TextStyle? speedStyle,
    TextStyle? durationStyle,
    TextStyle? errorStyle,
    IconData? downloadIcon,
    IconData? uploadIcon,
    IconData? pauseIcon,
    IconData? resumeIcon,
    IconData? cancelIcon,
    IconData? retryIcon,
    IconData? playIcon,
    IconData? fileIcon,
    IconData? documentIcon,
    IconData? imageIcon,
    IconData? videoIcon,
    IconData? audioIcon,
    IconData? successIcon,
    IconData? errorIcon,
    Duration? progressAnimationDuration,
    Curve? progressAnimationCurve,
    Duration? stateAnimationDuration,
    Curve? stateAnimationCurve,
    bool? showFileSize,
    bool? showSpeed,
    bool? showEta,
    bool? showProgressPercent,
    bool? showLinearProgress,
    bool? showCircularProgress,
    bool? useBlurOverlay,
    double? blurSigma,
  }) {
    return SocialTransferThemeData(
      skin: skin ?? this.skin,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      bubbleColor: bubbleColor ?? this.bubbleColor,
      incomingBubbleColor: incomingBubbleColor ?? this.incomingBubbleColor,
      outgoingBubbleColor: outgoingBubbleColor ?? this.outgoingBubbleColor,
      progressBackgroundColor:
          progressBackgroundColor ?? this.progressBackgroundColor,
      progressForegroundColor:
          progressForegroundColor ?? this.progressForegroundColor,
      successColor: successColor ?? this.successColor,
      errorColor: errorColor ?? this.errorColor,
      warningColor: warningColor ?? this.warningColor,
      pausedColor: pausedColor ?? this.pausedColor,
      textColor: textColor ?? this.textColor,
      subtitleColor: subtitleColor ?? this.subtitleColor,
      iconColor: iconColor ?? this.iconColor,
      overlayColor: overlayColor ?? this.overlayColor,
      bubbleBorderRadius: bubbleBorderRadius ?? this.bubbleBorderRadius,
      incomingBubbleBorderRadius:
          incomingBubbleBorderRadius ?? this.incomingBubbleBorderRadius,
      outgoingBubbleBorderRadius:
          outgoingBubbleBorderRadius ?? this.outgoingBubbleBorderRadius,
      progressBorderRadius: progressBorderRadius ?? this.progressBorderRadius,
      buttonBorderRadius: buttonBorderRadius ?? this.buttonBorderRadius,
      thumbnailBorderRadius:
          thumbnailBorderRadius ?? this.thumbnailBorderRadius,
      bubbleBorder: bubbleBorder ?? this.bubbleBorder,
      bubbleShadow: bubbleShadow ?? this.bubbleShadow,
      actionButtonSize: actionButtonSize ?? this.actionButtonSize,
      smallIconSize: smallIconSize ?? this.smallIconSize,
      mediumIconSize: mediumIconSize ?? this.mediumIconSize,
      largeIconSize: largeIconSize ?? this.largeIconSize,
      progressStrokeWidth: progressStrokeWidth ?? this.progressStrokeWidth,
      linearProgressHeight: linearProgressHeight ?? this.linearProgressHeight,
      maxBubbleWidth: maxBubbleWidth ?? this.maxBubbleWidth,
      minBubbleWidth: minBubbleWidth ?? this.minBubbleWidth,
      bubblePadding: bubblePadding ?? this.bubblePadding,
      bubbleMargin: bubbleMargin ?? this.bubbleMargin,
      contentPadding: contentPadding ?? this.contentPadding,
      fileNameStyle: fileNameStyle ?? this.fileNameStyle,
      fileSizeStyle: fileSizeStyle ?? this.fileSizeStyle,
      progressStyle: progressStyle ?? this.progressStyle,
      statusStyle: statusStyle ?? this.statusStyle,
      speedStyle: speedStyle ?? this.speedStyle,
      durationStyle: durationStyle ?? this.durationStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      downloadIcon: downloadIcon ?? this.downloadIcon,
      uploadIcon: uploadIcon ?? this.uploadIcon,
      pauseIcon: pauseIcon ?? this.pauseIcon,
      resumeIcon: resumeIcon ?? this.resumeIcon,
      cancelIcon: cancelIcon ?? this.cancelIcon,
      retryIcon: retryIcon ?? this.retryIcon,
      playIcon: playIcon ?? this.playIcon,
      fileIcon: fileIcon ?? this.fileIcon,
      documentIcon: documentIcon ?? this.documentIcon,
      imageIcon: imageIcon ?? this.imageIcon,
      videoIcon: videoIcon ?? this.videoIcon,
      audioIcon: audioIcon ?? this.audioIcon,
      successIcon: successIcon ?? this.successIcon,
      errorIcon: errorIcon ?? this.errorIcon,
      progressAnimationDuration:
          progressAnimationDuration ?? this.progressAnimationDuration,
      progressAnimationCurve:
          progressAnimationCurve ?? this.progressAnimationCurve,
      stateAnimationDuration:
          stateAnimationDuration ?? this.stateAnimationDuration,
      stateAnimationCurve: stateAnimationCurve ?? this.stateAnimationCurve,
      showFileSize: showFileSize ?? this.showFileSize,
      showSpeed: showSpeed ?? this.showSpeed,
      showEta: showEta ?? this.showEta,
      showProgressPercent: showProgressPercent ?? this.showProgressPercent,
      showLinearProgress: showLinearProgress ?? this.showLinearProgress,
      showCircularProgress: showCircularProgress ?? this.showCircularProgress,
      useBlurOverlay: useBlurOverlay ?? this.useBlurOverlay,
      blurSigma: blurSigma ?? this.blurSigma,
    );
  }

  /// Linearly interpolate between two themes.
  @override
  SocialTransferThemeData lerp(
    covariant SocialTransferThemeData? other,
    double t,
  ) {
    if (other == null) return this;
    return SocialTransferThemeData(
      skin: t < 0.5 ? skin : other.skin,
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      bubbleColor: Color.lerp(bubbleColor, other.bubbleColor, t)!,
      incomingBubbleColor:
          Color.lerp(incomingBubbleColor, other.incomingBubbleColor, t)!,
      outgoingBubbleColor:
          Color.lerp(outgoingBubbleColor, other.outgoingBubbleColor, t)!,
      progressBackgroundColor:
          Color.lerp(
            progressBackgroundColor,
            other.progressBackgroundColor,
            t,
          )!,
      progressForegroundColor:
          Color.lerp(
            progressForegroundColor,
            other.progressForegroundColor,
            t,
          )!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      pausedColor: Color.lerp(pausedColor, other.pausedColor, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      subtitleColor: Color.lerp(subtitleColor, other.subtitleColor, t)!,
      iconColor: Color.lerp(iconColor, other.iconColor, t)!,
      overlayColor: Color.lerp(overlayColor, other.overlayColor, t)!,
      bubbleBorderRadius:
          BorderRadius.lerp(bubbleBorderRadius, other.bubbleBorderRadius, t)!,
      incomingBubbleBorderRadius:
          BorderRadius.lerp(
            incomingBubbleBorderRadius,
            other.incomingBubbleBorderRadius,
            t,
          )!,
      outgoingBubbleBorderRadius:
          BorderRadius.lerp(
            outgoingBubbleBorderRadius,
            other.outgoingBubbleBorderRadius,
            t,
          )!,
      progressBorderRadius:
          BorderRadius.lerp(
            progressBorderRadius,
            other.progressBorderRadius,
            t,
          )!,
      buttonBorderRadius:
          BorderRadius.lerp(buttonBorderRadius, other.buttonBorderRadius, t)!,
      thumbnailBorderRadius:
          BorderRadius.lerp(
            thumbnailBorderRadius,
            other.thumbnailBorderRadius,
            t,
          )!,
      bubbleBorder: t < 0.5 ? bubbleBorder : other.bubbleBorder,
      bubbleShadow: t < 0.5 ? bubbleShadow : other.bubbleShadow,
      actionButtonSize:
          lerpDouble(actionButtonSize, other.actionButtonSize, t)!,
      smallIconSize: lerpDouble(smallIconSize, other.smallIconSize, t)!,
      mediumIconSize: lerpDouble(mediumIconSize, other.mediumIconSize, t)!,
      largeIconSize: lerpDouble(largeIconSize, other.largeIconSize, t)!,
      progressStrokeWidth:
          lerpDouble(progressStrokeWidth, other.progressStrokeWidth, t)!,
      linearProgressHeight:
          lerpDouble(linearProgressHeight, other.linearProgressHeight, t)!,
      maxBubbleWidth: lerpDouble(maxBubbleWidth, other.maxBubbleWidth, t)!,
      minBubbleWidth: lerpDouble(minBubbleWidth, other.minBubbleWidth, t)!,
      bubblePadding: EdgeInsets.lerp(bubblePadding, other.bubblePadding, t)!,
      bubbleMargin: EdgeInsets.lerp(bubbleMargin, other.bubbleMargin, t)!,
      contentPadding: EdgeInsets.lerp(contentPadding, other.contentPadding, t)!,
      fileNameStyle: TextStyle.lerp(fileNameStyle, other.fileNameStyle, t),
      fileSizeStyle: TextStyle.lerp(fileSizeStyle, other.fileSizeStyle, t),
      progressStyle: TextStyle.lerp(progressStyle, other.progressStyle, t),
      statusStyle: TextStyle.lerp(statusStyle, other.statusStyle, t),
      speedStyle: TextStyle.lerp(speedStyle, other.speedStyle, t),
      durationStyle: TextStyle.lerp(durationStyle, other.durationStyle, t),
      errorStyle: TextStyle.lerp(errorStyle, other.errorStyle, t),
      downloadIcon: t < 0.5 ? downloadIcon : other.downloadIcon,
      uploadIcon: t < 0.5 ? uploadIcon : other.uploadIcon,
      pauseIcon: t < 0.5 ? pauseIcon : other.pauseIcon,
      resumeIcon: t < 0.5 ? resumeIcon : other.resumeIcon,
      cancelIcon: t < 0.5 ? cancelIcon : other.cancelIcon,
      retryIcon: t < 0.5 ? retryIcon : other.retryIcon,
      playIcon: t < 0.5 ? playIcon : other.playIcon,
      fileIcon: t < 0.5 ? fileIcon : other.fileIcon,
      documentIcon: t < 0.5 ? documentIcon : other.documentIcon,
      imageIcon: t < 0.5 ? imageIcon : other.imageIcon,
      videoIcon: t < 0.5 ? videoIcon : other.videoIcon,
      audioIcon: t < 0.5 ? audioIcon : other.audioIcon,
      successIcon: t < 0.5 ? successIcon : other.successIcon,
      errorIcon: t < 0.5 ? errorIcon : other.errorIcon,
      progressAnimationDuration:
          t < 0.5 ? progressAnimationDuration : other.progressAnimationDuration,
      progressAnimationCurve:
          t < 0.5 ? progressAnimationCurve : other.progressAnimationCurve,
      stateAnimationDuration:
          t < 0.5 ? stateAnimationDuration : other.stateAnimationDuration,
      stateAnimationCurve:
          t < 0.5 ? stateAnimationCurve : other.stateAnimationCurve,
      showFileSize: t < 0.5 ? showFileSize : other.showFileSize,
      showSpeed: t < 0.5 ? showSpeed : other.showSpeed,
      showEta: t < 0.5 ? showEta : other.showEta,
      showProgressPercent:
          t < 0.5 ? showProgressPercent : other.showProgressPercent,
      showLinearProgress:
          t < 0.5 ? showLinearProgress : other.showLinearProgress,
      showCircularProgress:
          t < 0.5 ? showCircularProgress : other.showCircularProgress,
      useBlurOverlay: t < 0.5 ? useBlurOverlay : other.useBlurOverlay,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
    );
  }
}

/// Extension to easily access theme from context.
extension SocialTransferThemeContext on BuildContext {
  /// Gets the social transfer theme.
  SocialTransferThemeData get socialTransferTheme =>
      Theme.of(this).extension<SocialTransferThemeData>() ??
      SocialTransferThemeData.of(this);
}
