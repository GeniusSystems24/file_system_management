/// Infrastructure layer barrel file.
///
/// The infrastructure layer contains cross-cutting concerns
/// like caching, storage, network, and permissions.
///
/// Structure:
/// - cache/: File caching management
/// - storage/: File storage and directories
/// - network/: Network utilities
/// - permissions/: Permission handling
library;

export 'cache/file_cache_manager.dart';
export 'storage/app_directory.dart';
