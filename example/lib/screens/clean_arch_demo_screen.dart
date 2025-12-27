import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Example screen demonstrating Clean Architecture usage.
///
/// This shows how to use:
/// - TransferController (facade)
/// - Result pattern for error handling
/// - TransferEntity for domain data
class CleanArchDemoScreen extends StatefulWidget {
  const CleanArchDemoScreen({super.key});

  @override
  State<CleanArchDemoScreen> createState() => _CleanArchDemoScreenState();
}

class _CleanArchDemoScreenState extends State<CleanArchDemoScreen> {
  final List<_DownloadItem> _downloads = [];
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    // Initialize the clean architecture controller
    await TransferController.instance.initialize();
    setState(() => _isInitialized = true);
  }

  Future<void> _startDownload(String url, String name) async {
    if (!_isInitialized) return;

    // Use the clean architecture controller
    final result = await TransferController.instance.download(
      url: url,
      fileName: name,
      config: const TransferConfigEntity(
        maxRetries: 3,
        allowResume: true,
      ),
    );

    // Handle result using fold pattern
    result.fold(
      onSuccess: (stream) {
        final item = _DownloadItem(name: name, url: url);
        setState(() => _downloads.add(item));

        // Listen to stream updates
        stream.listen(
          (entity) {
            setState(() {
              item.entity = entity;
            });
          },
          onError: (error) {
            setState(() {
              item.error = error.toString();
            });
          },
        );
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _pauseDownload(String id) async {
    final result = await TransferController.instance.pause(id);
    result.fold(
      onSuccess: (success) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم الإيقاف المؤقت')),
          );
        }
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${failure.message}')),
        );
      },
    );
  }

  Future<void> _resumeDownload(String id) async {
    final result = await TransferController.instance.resume(id);
    result.fold(
      onSuccess: (success) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم الاستئناف')),
          );
        }
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${failure.message}')),
        );
      },
    );
  }

  Future<void> _cancelDownload(String id) async {
    final result = await TransferController.instance.cancel(id);
    result.fold(
      onSuccess: (success) {
        if (success) {
          setState(() {
            _downloads.removeWhere((d) => d.entity?.id == id);
          });
        }
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${failure.message}')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean Architecture Demo'),
        centerTitle: true,
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Sample downloads
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'أمثلة التحميل:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _startDownload(
                              'https://www.w3.org/WAI/WCAG21/Techniques/pdf/img/table-word.jpg',
                              'image.jpg',
                            ),
                            icon: const Icon(Icons.image),
                            label: const Text('صورة'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _startDownload(
                              'https://www.w3.org/WAI/WCAG21/Techniques/pdf/img/table-word.pdf',
                              'document.pdf',
                            ),
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('PDF'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Downloads list
                Expanded(
                  child: _downloads.isEmpty
                      ? const Center(
                          child: Text('لا توجد تحميلات'),
                        )
                      : ListView.builder(
                          itemCount: _downloads.length,
                          itemBuilder: (context, index) {
                            final item = _downloads[index];
                            return _DownloadTile(
                              item: item,
                              onPause: () => _pauseDownload(item.entity!.id),
                              onResume: () => _resumeDownload(item.entity!.id),
                              onCancel: () => _cancelDownload(item.entity!.id),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _DownloadItem {
  final String name;
  final String url;
  TransferEntity? entity;
  String? error;

  _DownloadItem({required this.name, required this.url});
}

class _DownloadTile extends StatelessWidget {
  final _DownloadItem item;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;

  const _DownloadTile({
    required this.item,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final entity = item.entity;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getIcon(entity?.status),
                  color: _getColor(entity?.status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (entity != null) ...[
                  Text(
                    '${entity.progressPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Progress bar
            if (entity != null)
              LinearProgressIndicator(
                value: entity.progress,
                backgroundColor: Colors.grey.shade200,
              ),
            const SizedBox(height: 8),
            // Status and controls
            Row(
              children: [
                Text(
                  _getStatusText(entity?.status),
                  style: TextStyle(
                    color: _getColor(entity?.status),
                    fontSize: 12,
                  ),
                ),
                if (entity?.speed != null && entity!.speed > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${(entity.speed / 1024).toStringAsFixed(1)} KB/s',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                const Spacer(),
                // Control buttons
                if (entity?.isRunning == true)
                  IconButton(
                    icon: const Icon(Icons.pause),
                    onPressed: onPause,
                    tooltip: 'إيقاف مؤقت',
                  ),
                if (entity?.isPaused == true)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: onResume,
                    tooltip: 'استئناف',
                  ),
                if (entity?.isComplete != true)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                    tooltip: 'إلغاء',
                  ),
              ],
            ),
            // Error message
            if (item.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  item.error!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(TransferStatusEntity? status) {
    return switch (status) {
      TransferStatusEntity.pending => Icons.hourglass_empty,
      TransferStatusEntity.running => Icons.downloading,
      TransferStatusEntity.paused => Icons.pause_circle,
      TransferStatusEntity.complete => Icons.check_circle,
      TransferStatusEntity.failed => Icons.error,
      TransferStatusEntity.canceled => Icons.cancel,
      _ => Icons.help,
    };
  }

  Color _getColor(TransferStatusEntity? status) {
    return switch (status) {
      TransferStatusEntity.pending => Colors.orange,
      TransferStatusEntity.running => Colors.blue,
      TransferStatusEntity.paused => Colors.amber,
      TransferStatusEntity.complete => Colors.green,
      TransferStatusEntity.failed => Colors.red,
      TransferStatusEntity.canceled => Colors.grey,
      _ => Colors.grey,
    };
  }

  String _getStatusText(TransferStatusEntity? status) {
    return switch (status) {
      TransferStatusEntity.pending => 'في الانتظار',
      TransferStatusEntity.running => 'جاري التحميل',
      TransferStatusEntity.paused => 'متوقف مؤقتاً',
      TransferStatusEntity.complete => 'مكتمل',
      TransferStatusEntity.failed => 'فشل',
      TransferStatusEntity.canceled => 'ملغى',
      _ => 'غير معروف',
    };
  }
}
