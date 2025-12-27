import '../../entities/entities.dart';
import '../../repositories/repositories.dart';
import '../usecase.dart';

/// Use case for getting a transfer by ID.
class GetTransferUseCase implements UseCase<TransferEntity?, String> {
  final TransferRepository _repository;

  GetTransferUseCase(this._repository);

  @override
  Future<Result<TransferEntity?>> call(String transferId) async {
    return _repository.getById(transferId);
  }
}
