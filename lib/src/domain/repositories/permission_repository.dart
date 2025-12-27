import '../failures/failures.dart';
import 'transfer_repository.dart';

/// Repository interface for permission operations.
abstract class PermissionRepository {
  /// Checks permission status.
  Future<Result<PermissionStatusEntity>> status(PermissionTypeEntity type);

  /// Requests a permission.
  Future<Result<PermissionStatusEntity>> request(PermissionTypeEntity type);

  /// Checks if permission is granted.
  Future<Result<bool>> isGranted(PermissionTypeEntity type);

  /// Checks if permission should show rationale.
  Future<Result<bool>> shouldShowRationale(PermissionTypeEntity type);
}

/// Permission types.
enum PermissionTypeEntity {
  notifications,
  storage,
  camera,
  photos,
}

/// Permission status.
enum PermissionStatusEntity {
  granted,
  denied,
  restricted,
  permanentlyDenied,
  undetermined,
}
