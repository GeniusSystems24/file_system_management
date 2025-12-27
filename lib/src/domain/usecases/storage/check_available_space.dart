import '../../repositories/repositories.dart';
import '../usecase.dart';

/// Parameters for checking available space.
class CheckAvailableSpaceParams {
  final String? directory;

  const CheckAvailableSpaceParams({this.directory});
}

/// Use case for checking available storage space.
class CheckAvailableSpaceUseCase
    implements UseCase<int?, CheckAvailableSpaceParams> {
  final StorageRepository _repository;

  CheckAvailableSpaceUseCase(this._repository);

  @override
  Future<Result<int?>> call(CheckAvailableSpaceParams params) async {
    return _repository.getAvailableSpace(directory: params.directory);
  }
}
