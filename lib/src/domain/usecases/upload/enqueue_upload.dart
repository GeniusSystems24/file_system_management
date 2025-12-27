import '../../entities/entities.dart';
import '../../repositories/repositories.dart';
import '../usecase.dart';

/// Parameters for enqueueing an upload.
class EnqueueUploadParams {
  final String url;
  final String filePath;
  final String? fileName;
  final Map<String, String>? fields;
  final TransferConfigEntity? config;

  const EnqueueUploadParams({
    required this.url,
    required this.filePath,
    this.fileName,
    this.fields,
    this.config,
  });
}

/// Use case for enqueueing an upload.
class EnqueueUploadUseCase
    implements StreamUseCase<TransferEntity, EnqueueUploadParams> {
  final TransferRepository _repository;

  EnqueueUploadUseCase(this._repository);

  @override
  Future<Result<Stream<TransferEntity>>> call(
      EnqueueUploadParams params) async {
    return _repository.enqueueUpload(
      url: params.url,
      filePath: params.filePath,
      fileName: params.fileName,
      fields: params.fields,
      config: params.config,
    );
  }
}
