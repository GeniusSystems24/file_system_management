/// Domain layer barrel file.
///
/// The domain layer contains the core business logic of the application.
/// It is independent of any external frameworks or packages.
///
/// Structure:
/// - entities/: Business entities (pure data classes)
/// - repositories/: Abstract repository interfaces
/// - usecases/: Business logic operations
/// - failures/: Domain-specific error types
library;

export 'entities/entities.dart';
export 'repositories/repositories.dart';
export 'usecases/usecases.dart';
export 'failures/failures.dart';
