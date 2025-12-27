import '../../entities/entities.dart';
import '../../repositories/repositories.dart';
import '../usecase.dart';

/// Parameters for enqueueing a parallel download.
class EnqueueParallelDownloadParams {
  final String url;
  final List<String>? mirrorUrls;
  final int chunks;
  final String? fileName;
  final String? directory;
  final TransferConfigEntity? config;

  const EnqueueParallelDownloadParams({
    required this.url,
    this.mirrorUrls,
    this.chunks = 4,
    this.fileName,
    this.directory,
    this.config,
  });
}

/// Use case for enqueueing a parallel download.
class EnqueueParallelDownloadUseCase
    implements StreamUseCase<TransferEntity, EnqueueParallelDownloadParams> {
  final TransferRepository _repository;

  EnqueueParallelDownloadUseCase(this._repository);

  @override
  Future<Result<Stream<TransferEntity>>> call(
      EnqueueParallelDownloadParams params) async {
    return _repository.enqueueParallelDownload(
      url: params.url,
      mirrorUrls: params.mirrorUrls,
      chunks: params.chunks,
      fileName: params.fileName,
      directory: params.directory,
      config: params.config,
    );
  }
}
