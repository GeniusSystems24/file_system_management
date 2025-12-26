/// A Flutter package for managing file download and upload tasks
/// with progress tracking, caching, and notifications.
///
/// ## Features:
/// - Download and upload file management
/// - Mutex-based locking to prevent duplicate operations
/// - Automatic file caching with URL recognition
/// - Stream-based progress updates
/// - Customizable widgets for media and documents
/// - Pause, resume, cancel, and retry operations
///
/// ## Basic Usage:
/// ```dart
/// // Initialize the controller
/// await FileSystemController.instance.initialize();
///
/// // Download a file
/// final task = createDownloadTask(url: 'https://example.com/file.pdf');
/// final result = await FileSystemController.instance.enqueueDownload(task);
///
/// switch (result) {
///   case EnqueueCached(:final filePath):
///     print('File already cached at: $filePath');
///   case EnqueueStarted(:final controller):
///     controller.stream.listen((item) {
///       print('Progress: ${item.progressText}');
///     });
///   // ...
/// }
/// ```
library file_system_management;

// Core exports
export 'src/core/app_directory.dart';
export 'src/core/extensions/file_path_extension.dart';
export 'src/core/extensions/string_extension.dart';
export 'src/core/file_cache_manager.dart';
export 'src/core/task_mutex.dart';

// Controllers
export 'src/controllers/file_system_controller.dart';

// Models
export 'src/models/transfer_item.dart';
export 'src/models/file_model.dart';
export 'src/models/file_type_enum.dart';
export 'src/models/notifier.dart';

// Legacy compatibility - TaskItem is now TransferItem
export 'src/models/task_item.dart';

// Widgets
export 'src/widgets/transfer_card.dart';
export 'src/widgets/transfer_progress_indicator.dart';
export 'src/widgets/media_download_card.dart';
export 'src/widgets/document_download_card.dart';
