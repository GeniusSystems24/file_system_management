/// Data layer barrel file.
///
/// The data layer contains implementations of domain repositories
/// and data sources for external services.
///
/// Structure:
/// - datasources/: External data source wrappers
/// - models/: Data transfer objects (DTOs)
/// - repositories/: Repository implementations
library;

export 'datasources/datasources.dart';
export 'models/models.dart';
export 'repositories/repositories.dart';
