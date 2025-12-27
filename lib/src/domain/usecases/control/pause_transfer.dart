import '../../repositories/repositories.dart';
import '../usecase.dart';

/// Use case for pausing a transfer.
class PauseTransferUseCase implements UseCase<bool, String> {
  final TransferRepository _repository;

  PauseTransferUseCase(this._repository);

  @override
  Future<Result<bool>> call(String transferId) async {
    return _repository.pause(transferId);
  }
}
