import '../../entities/entities.dart';
import '../../repositories/repositories.dart';
import '../usecase.dart';

/// Parameters for enqueueing a download.
class EnqueueDownloadParams {
  final String url;
  final String? fileName;
  final String? directory;
  final TransferConfigEntity? config;

  const EnqueueDownloadParams({
    required this.url,
    this.fileName,
    this.directory,
    this.config,
  });
}

/// Use case for enqueueing a download.
class EnqueueDownloadUseCase
    implements StreamUseCase<TransferEntity, EnqueueDownloadParams> {
  final TransferRepository _repository;

  EnqueueDownloadUseCase(this._repository);

  @override
  Future<Result<Stream<TransferEntity>>> call(
      EnqueueDownloadParams params) async {
    return _repository.enqueueDownload(
      url: params.url,
      fileName: params.fileName,
      directory: params.directory,
      config: params.config,
    );
  }
}
