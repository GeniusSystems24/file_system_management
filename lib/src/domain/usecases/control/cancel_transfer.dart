import '../../repositories/repositories.dart';
import '../usecase.dart';

/// Use case for cancelling a transfer.
class CancelTransferUseCase implements UseCase<bool, String> {
  final TransferRepository _repository;

  CancelTransferUseCase(this._repository);

  @override
  Future<Result<bool>> call(String transferId) async {
    return _repository.cancel(transferId);
  }
}
