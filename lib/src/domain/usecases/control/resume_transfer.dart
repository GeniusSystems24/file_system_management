import '../../repositories/repositories.dart';
import '../usecase.dart';

/// Use case for resuming a transfer.
class ResumeTransferUseCase implements UseCase<bool, String> {
  final TransferRepository _repository;

  ResumeTransferUseCase(this._repository);

  @override
  Future<Result<bool>> call(String transferId) async {
    return _repository.resume(transferId);
  }
}
