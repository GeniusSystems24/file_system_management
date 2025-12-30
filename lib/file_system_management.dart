/// A Flutter package for managing file download and upload tasks
/// with progress tracking, caching, and notifications.
///
/// Built using Clean Architecture principles for maintainability and testability.
///
/// ## Architecture:
/// - **Domain Layer**: Business entities, repositories, and use cases
/// - **Data Layer**: Repository implementations and data sources
/// - **Infrastructure Layer**: Caching, storage, and permissions
/// - **Presentation Layer**: Controllers, widgets, and themes
///
/// ## Features:
/// - Download and upload file management
/// - Clean Architecture with Result pattern for error handling
/// - Social media-inspired skins (WhatsApp, Telegram, Instagram)
/// - Mutex-based locking to prevent duplicate operations
/// - Automatic file caching with URL recognition
/// - Stream-based progress updates
/// - Customizable widgets for media and documents
/// - Pause, resume, cancel, and retry operations
/// - RTL and Dark mode support
/// - Parallel downloads for faster speeds
/// - Batch operations
/// - Shared storage support
/// - Injectable handlers for custom upload/download logic
///
/// ## Usage:
/// ```dart
/// // Initialize the controller
/// await TransferController.instance.initialize();
///
/// // Download a file
/// final result = await TransferController.instance.download(
///   url: 'https://example.com/file.pdf',
/// );
///
/// result.fold(
///   onSuccess: (stream) => stream.listen((entity) {
///     print('Progress: ${entity.progressPercent}%');
///   }),
///   onFailure: (failure) => print('Error: ${failure.message}'),
/// );
/// ```
///
/// ## Custom Handlers:
/// ```dart
/// // Use custom upload/download handlers
/// ImageMessageTransferWidget(
///   url: 'https://example.com/image.jpg',
///   onDownload: (payload) => myCustomDownloadStream(payload),
///   onUpload: (payload) => myCustomUploadStream(payload),
/// )
/// ```
///
/// ## Theming:
/// ```dart
/// // Apply WhatsApp-like theme using ThemeData.extensions
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [SocialTransferThemeData.whatsapp()],
///   ),
/// )
///
/// // Access theme in widgets:
/// final theme = context.socialTransferTheme;
/// ```
library;

// ═══════════════════════════════════════════════════════════════════════════
// CLEAN ARCHITECTURE LAYERS
// ═══════════════════════════════════════════════════════════════════════════

// Domain Layer - Business logic (pure Dart, no Flutter dependencies)
export 'src/domain/domain.dart';

// Data Layer - Repository implementations
export 'src/data/data.dart';

// Infrastructure Layer - Cross-cutting concerns
export 'src/infrastructure/infrastructure.dart';

// Presentation Layer - UI components
export 'src/presentation/presentation.dart';

// Core - Shared utilities
export 'src/core/core.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HANDLERS - Injectable upload/download abstractions
// ═══════════════════════════════════════════════════════════════════════════

export 'src/handlers/cancellation_token.dart';
export 'src/handlers/transfer_handler.dart';
export 'src/handlers/transfer_progress.dart';
export 'src/handlers/transfer_result.dart';

// ═══════════════════════════════════════════════════════════════════════════
// THEME - Social media skins and customization
// ═══════════════════════════════════════════════════════════════════════════

export 'src/theme/social_transfer_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS - Core transfer widgets
// ═══════════════════════════════════════════════════════════════════════════

export 'src/widgets/transfer_card.dart';
export 'src/widgets/transfer_progress_indicator.dart';
export 'src/widgets/media_download_card.dart';
export 'src/widgets/document_download_card.dart';

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS - Message transfer widgets
// ═══════════════════════════════════════════════════════════════════════════

export 'src/widgets/messages/messages.dart';

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS - Video download and player
// ═══════════════════════════════════════════════════════════════════════════

export 'src/widgets/video/video.dart';
