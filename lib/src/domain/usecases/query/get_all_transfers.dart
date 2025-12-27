import '../../entities/entities.dart';
import '../../repositories/repositories.dart';
import '../usecase.dart';

/// Use case for getting all transfers.
class GetAllTransfersUseCase
    implements NoParamsUseCase<List<TransferEntity>> {
  final TransferRepository _repository;

  GetAllTransfersUseCase(this._repository);

  @override
  Future<Result<List<TransferEntity>>> call() async {
    return _repository.getAll();
  }
}
