import 'dart:async';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demo screen showing custom handler implementations.
class HandlersDemoScreen extends StatefulWidget {
  const HandlersDemoScreen({super.key});

  @override
  State<HandlersDemoScreen> createState() => _HandlersDemoScreenState();
}

class _HandlersDemoScreenState extends State<HandlersDemoScreen> {
  TransferProgress? _progress;
  TransferResult? _result;
  bool _isDownloading = false;
  bool _isUploading = false;
  String _log = '';
  CancellationToken? _cancellationToken;

  final _downloadHandler = _MockDownloadHandler();
  final _uploadHandler = _MockUploadHandler();

  void _addLog(String message) {
    setState(() {
      _log = '${DateTime.now().toString().substring(11, 19)}: $message\n$_log';
    });
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _progress = null;
      _result = null;
    });

    _cancellationToken = CancellationToken();
    _addLog('بدء التحميل...');

    try {
      final stream = _downloadHandler.download(
        const DownloadPayload(
          url: 'https://example.com/sample-file.zip',
          fileName: 'sample-file.zip',
          expectedSize: 10 * 1024 * 1024, // 10 MB
        ),
        cancellationToken: _cancellationToken,
      );

      await for (final progress in stream) {
        setState(() => _progress = progress);
        _addLog('التقدم: ${(progress.progressPercent * 100).toStringAsFixed(1)}%');

        if (progress.isCompleted) {
          setState(() {
            _result = TransferSuccess(
              localPath: '/path/to/file.zip',
              fileSize: progress.totalBytes,
            );
          });
          _addLog('تم التحميل بنجاح!');
        } else if (progress.isFailed) {
          setState(() {
            _result = TransferError(message: progress.errorMessage ?? 'فشل التحميل');
          });
          _addLog('فشل: ${progress.errorMessage}');
        } else if (progress.isCancelled) {
          setState(() {
            _result = const TransferCancelled(reason: 'تم الإلغاء');
          });
          _addLog('تم الإلغاء');
        }
      }
    } catch (e) {
      _addLog('خطأ: $e');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _startUpload() async {
    setState(() {
      _isUploading = true;
      _progress = null;
      _result = null;
    });

    _cancellationToken = CancellationToken();
    _addLog('بدء الرفع...');

    try {
      final stream = _uploadHandler.upload(
        'https://example.com/upload',
        UploadPayload.fromPath(
          filePath: '/path/to/local/file.jpg',
          fileName: 'my-photo.jpg',
          fileSize: 5 * 1024 * 1024, // 5 MB
          mimeType: 'image/jpeg',
        ),
        cancellationToken: _cancellationToken,
      );

      await for (final progress in stream) {
        setState(() => _progress = progress);
        _addLog('التقدم: ${(progress.progressPercent * 100).toStringAsFixed(1)}%');

        if (progress.isCompleted) {
          setState(() {
            _result = const TransferSuccess(
              localPath: '/path/to/file.jpg',
              remoteUrl: 'https://example.com/files/my-photo.jpg',
            );
          });
          _addLog('تم الرفع بنجاح!');
        } else if (progress.isFailed) {
          setState(() {
            _result = TransferError(message: progress.errorMessage ?? 'فشل الرفع');
          });
          _addLog('فشل: ${progress.errorMessage}');
        }
      }
    } catch (e) {
      _addLog('خطأ: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _cancel() {
    _cancellationToken?.cancel('تم الإلغاء بواسطة المستخدم');
    _addLog('تم طلب الإلغاء');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Handlers المخصصة'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildControlCard(),
          const SizedBox(height: 16),
          _buildProgressCard(),
          const SizedBox(height: 16),
          _buildResultCard(),
          const SizedBox(height: 16),
          _buildLogCard(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'ما هي Handlers؟',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Handlers هي واجهات تسمح لك بتخصيص طريقة التحميل والرفع. '
              'يمكنك استخدام Firebase, AWS, أو أي خدمة أخرى من خلال تنفيذ هذه الواجهات.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildFeatureChip('DownloadHandler', Icons.download),
                _buildFeatureChip('UploadHandler', Icons.upload),
                _buildFeatureChip('TransferHandler', Icons.swap_vert),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildControlCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التحكم',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading || _isUploading ? null : _startDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('تحميل تجريبي'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading || _isUploading ? null : _startUpload,
                    icon: const Icon(Icons.upload),
                    label: const Text('رفع تجريبي'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isDownloading || _isUploading)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancel,
                  icon: const Icon(Icons.cancel),
                  label: const Text('إلغاء'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final progress = _progress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التقدم',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (progress == null)
              const Center(
                child: Text(
                  'لم يبدأ بعد',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress.progressPercent,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress.progressPercent * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildProgressInfo('المنقول', progress.bytesTransferredFormatted),
                  _buildProgressInfo('الإجمالي', progress.totalBytesFormatted),
                  _buildProgressInfo('السرعة', progress.speedFormatted),
                  _buildProgressInfo('المتبقي', progress.etaFormatted),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatusBadge(progress.status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressInfo(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(TransferStatus status) {
    final (color, icon, label) = switch (status) {
      TransferStatus.pending => (Colors.grey, Icons.hourglass_empty, 'انتظار'),
      TransferStatus.running => (Colors.blue, Icons.download, 'جاري'),
      TransferStatus.paused => (Colors.amber, Icons.pause, 'متوقف'),
      TransferStatus.completed => (Colors.green, Icons.check_circle, 'مكتمل'),
      TransferStatus.failed => (Colors.red, Icons.error, 'فشل'),
      TransferStatus.cancelled => (Colors.grey, Icons.cancel, 'ملغي'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'النتيجة',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_result == null)
              const Center(
                child: Text(
                  'لا توجد نتيجة بعد',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              _result!.when(
                success: (success) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'تم بنجاح',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('المسار: ${success.localPath}'),
                      if (success.remoteUrl != null)
                        Text('الرابط: ${success.remoteUrl}'),
                    ],
                  ),
                ),
                error: (error) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'فشل',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('الخطأ: ${error.message}'),
                      if (error.code != null) Text('الكود: ${error.code}'),
                    ],
                  ),
                ),
                cancelled: (cancelled) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text('ملغي: ${cancelled.reason ?? "بدون سبب"}'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'السجل',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _log = ''),
                  child: const Text('مسح'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _log.isEmpty ? 'لا توجد سجلات' : _log,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mock download handler for demonstration.
class _MockDownloadHandler implements DownloadHandler {
  @override
  Stream<TransferProgress> download(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async* {
    final totalBytes = payload.expectedSize ?? 10 * 1024 * 1024;
    const steps = 20;
    const stepDuration = Duration(milliseconds: 200);

    for (var i = 1; i <= steps; i++) {
      if (cancellationToken?.isCancelled == true) {
        yield TransferProgress(
          bytesTransferred: (totalBytes * (i - 1) / steps).round(),
          totalBytes: totalBytes,
          status: TransferStatus.cancelled,
        );
        return;
      }

      await Future.delayed(stepDuration);

      final bytesTransferred = (totalBytes * i / steps).round();
      yield TransferProgress(
        bytesTransferred: bytesTransferred,
        totalBytes: totalBytes,
        bytesPerSecond: totalBytes / (steps * stepDuration.inMilliseconds / 1000),
        estimatedTimeRemaining: Duration(
          milliseconds: ((steps - i) * stepDuration.inMilliseconds),
        ),
        status: i == steps ? TransferStatus.completed : TransferStatus.running,
      );
    }
  }

  @override
  Future<TransferResult> downloadAndComplete(
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async {
    TransferResult? result;
    await for (final progress in download(payload, config: config, cancellationToken: cancellationToken)) {
      if (progress.isCompleted) {
        result = TransferSuccess(
          localPath: payload.destinationPath ?? '/path/to/file',
          remoteUrl: payload.url,
          fileSize: progress.totalBytes,
        );
      }
    }
    return result ?? const TransferError(message: 'Download failed');
  }

  @override
  Future<String> getDownloadUrl(String fileId) async => fileId;

  @override
  Future<bool> pause(String downloadId) async => false;

  @override
  Future<bool> resume(String downloadId) async => false;

  @override
  Future<bool> cancel(String downloadId) async => false;

  @override
  Stream<TransferProgress> retryDownload(
    String downloadId,
    DownloadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) {
    return download(payload, config: config, cancellationToken: cancellationToken);
  }
}

/// Mock upload handler for demonstration.
class _MockUploadHandler implements UploadHandler {
  @override
  Stream<TransferProgress> upload(
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async* {
    final totalBytes = payload.fileSize ?? 5 * 1024 * 1024;
    const steps = 15;
    const stepDuration = Duration(milliseconds: 250);

    for (var i = 1; i <= steps; i++) {
      if (cancellationToken?.isCancelled == true) {
        yield TransferProgress(
          bytesTransferred: (totalBytes * (i - 1) / steps).round(),
          totalBytes: totalBytes,
          status: TransferStatus.cancelled,
        );
        return;
      }

      await Future.delayed(stepDuration);

      final bytesTransferred = (totalBytes * i / steps).round();
      yield TransferProgress(
        bytesTransferred: bytesTransferred,
        totalBytes: totalBytes,
        bytesPerSecond: totalBytes / (steps * stepDuration.inMilliseconds / 1000),
        estimatedTimeRemaining: Duration(
          milliseconds: ((steps - i) * stepDuration.inMilliseconds),
        ),
        status: i == steps ? TransferStatus.completed : TransferStatus.running,
      );
    }
  }

  @override
  Future<TransferResult> uploadAndComplete(
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) async {
    TransferResult? result;
    await for (final progress in upload(uploadUrl, payload, config: config, cancellationToken: cancellationToken)) {
      if (progress.isCompleted) {
        result = TransferSuccess(
          localPath: payload.filePath ?? '',
          remoteUrl: '$uploadUrl/${payload.fileName}',
          fileSize: progress.totalBytes,
        );
      }
    }
    return result ?? const TransferError(message: 'Upload failed');
  }

  @override
  Future<bool> pause(String uploadId) async => false;

  @override
  Future<bool> resume(String uploadId) async => false;

  @override
  Future<bool> cancel(String uploadId) async => false;

  @override
  Stream<TransferProgress> retryUpload(
    String uploadId,
    String uploadUrl,
    UploadPayload payload, {
    TransferConfig? config,
    CancellationToken? cancellationToken,
  }) {
    return upload(uploadUrl, payload, config: config, cancellationToken: cancellationToken);
  }
}
