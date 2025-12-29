import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/constants/sample_files.dart';

/// Demonstrates downloading files via HTTPS.
///
/// This example shows how to:
/// - Download files from HTTPS URLs
/// - Handle custom headers and authentication
/// - Track download progress
/// - Resume interrupted downloads
/// - Download multiple files concurrently
class HttpsDownloadScreen extends StatefulWidget {
  const HttpsDownloadScreen({super.key});

  @override
  State<HttpsDownloadScreen> createState() => _HttpsDownloadScreenState();
}

class _HttpsDownloadScreenState extends State<HttpsDownloadScreen>
    with SingleTickerProviderStateMixin {
  final TransferController _controller = TransferController.instance;
  final TextEditingController _urlController = TextEditingController();

  late TabController _tabController;
  final Map<String, TransferEntity> _transfers = {};
  final List<String> _logs = [];

  // Custom headers
  final Map<String, String> _customHeaders = {};
  final TextEditingController _headerKeyController = TextEditingController();
  final TextEditingController _headerValueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadExistingTransfers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _headerKeyController.dispose();
    _headerValueController.dispose();
    super.dispose();
  }

  void _log(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logs.length > 100) _logs.removeLast();
    });
  }

  Future<void> _loadExistingTransfers() async {
    final result = await _controller.getAllTransfers();
    final transfers = result.valueOrNull ?? [];
    setState(() {
      for (final t in transfers) {
        _transfers[t.url] = t;
      }
    });
  }

  Future<void> _downloadUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('Please enter a URL');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _showError('Please enter a valid HTTP/HTTPS URL');
      return;
    }

    await _startDownload(url);
  }

  Future<void> _startDownload(String url, {String? fileName}) async {
    _log('Starting download: ${url.substring(0, 50.clamp(0, url.length))}...');

    try {
      final result = await _controller.download(
        url: url,
        fileName: fileName,
        config: TransferConfigEntity(
          headers: _customHeaders.isNotEmpty ? _customHeaders : null,
          maxRetries: 3,
          allowResume: true,
        ),
      );

      final stream = result.valueOrNull;
      if (stream != null) {
        stream.listen((entity) {
          setState(() => _transfers[url] = entity);
          if (entity.isComplete) {
            _log('Completed: ${entity.fileName}');
          } else if (entity.isFailed) {
            _log('Failed: ${entity.errorMessage}');
          }
        });
      } else {
        _log('Error: ${result.failureOrNull?.message}');
      }
    } catch (e) {
      _log('Error: $e');
    }
  }

  Future<void> _pauseDownload(String id) async {
    await _controller.pause(id);
    await _loadExistingTransfers();
    _log('Paused download');
  }

  Future<void> _resumeDownload(String id) async {
    await _controller.resume(id);
    await _loadExistingTransfers();
    _log('Resumed download');
  }

  Future<void> _cancelDownload(String id) async {
    await _controller.cancel(id);
    await _loadExistingTransfers();
    _log('Cancelled download');
  }

  Future<void> _retryDownload(String id) async {
    final result = await _controller.retry(id);
    if (result.valueOrNull != null) {
      result.valueOrNull!.listen((entity) {
        setState(() => _transfers[entity.url] = entity);
      });
    }
    _log('Retrying download');
  }

  void _addHeader() {
    final key = _headerKeyController.text.trim();
    final value = _headerValueController.text.trim();
    if (key.isNotEmpty && value.isNotEmpty) {
      setState(() {
        _customHeaders[key] = value;
      });
      _headerKeyController.clear();
      _headerValueController.clear();
      _log('Added header: $key');
    }
  }

  void _removeHeader(String key) {
    setState(() {
      _customHeaders.remove(key);
    });
    _log('Removed header: $key');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTPS Download'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.download), text: 'Download'),
            Tab(icon: Icon(Icons.list), text: 'Samples'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDownloadTab(theme),
          _buildSamplesTab(theme),
          _buildSettingsTab(theme),
        ],
      ),
    );
  }

  Widget _buildDownloadTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // URL Input Card
        _buildUrlInputCard(theme),
        const SizedBox(height: 16),

        // Active Transfers
        _buildActiveTransfersCard(theme),
        const SizedBox(height: 16),

        // Logs
        _buildLogsCard(theme),
        const SizedBox(height: 16),

        // Code Example
        _buildCodeExample(theme),
      ],
    );
  }

  Widget _buildSamplesTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sample Files',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Real files available for download testing',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...SampleFiles.all.map((file) => _buildSampleFileItem(file, theme)),
      ],
    );
  }

  Widget _buildSettingsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Custom Headers
        _buildCustomHeadersCard(theme),
        const SizedBox(height: 16),

        // Authentication Examples
        _buildAuthExamplesCard(theme),
        const SizedBox(height: 16),

        // Configuration Options
        _buildConfigOptionsCard(theme),
      ],
    );
  }

  Widget _buildUrlInputCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Download URL',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://example.com/file.zip',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _urlController.text = data!.text!;
                    }
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloadUrl,
                icon: const Icon(Icons.download),
                label: const Text('Start Download'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTransfersCard(ThemeData theme) {
    final activeTransfers = _transfers.values.where((t) => !t.isComplete).toList();

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
                  'Active Downloads',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _loadExistingTransfers,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (activeTransfers.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.download_done,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No active downloads',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...activeTransfers.map((t) => _buildTransferItem(t, theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferItem(TransferEntity transfer, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  transfer.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              _buildTransferActions(transfer),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: transfer.progress,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(transfer.progress * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                _formatSpeed(transfer.speed),
                style: const TextStyle(fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(transfer).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(transfer),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getStatusColor(transfer),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransferActions(TransferEntity transfer) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (transfer.isRunning)
          IconButton(
            icon: const Icon(Icons.pause, size: 20),
            onPressed: () => _pauseDownload(transfer.id),
            visualDensity: VisualDensity.compact,
          ),
        if (transfer.isPaused)
          IconButton(
            icon: const Icon(Icons.play_arrow, size: 20),
            onPressed: () => _resumeDownload(transfer.id),
            visualDensity: VisualDensity.compact,
          ),
        if (transfer.isFailed)
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => _retryDownload(transfer.id),
            visualDensity: VisualDensity.compact,
          ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => _cancelDownload(transfer.id),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildSampleFileItem(SampleFile file, ThemeData theme) {
    final transfer = _transfers[file.url];

    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getSampleTypeColor(file.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getSampleTypeIcon(file.type),
            color: _getSampleTypeColor(file.type),
          ),
        ),
        title: Text(file.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${file.extension.toUpperCase()} • ${file.formattedSize}'),
            if (transfer != null && transfer.isRunning) ...[
              const SizedBox(height: 4),
              LinearProgressIndicator(value: transfer.progress),
            ],
          ],
        ),
        trailing: _buildSampleFileAction(file, transfer),
        onTap: transfer == null || transfer.isFailed
            ? () => _startDownload(file.url, fileName: file.fileName)
            : null,
      ),
    );
  }

  Widget _buildSampleFileAction(SampleFile file, TransferEntity? transfer) {
    if (transfer == null || transfer.isFailed) {
      return IconButton(
        icon: const Icon(Icons.download),
        onPressed: () => _startDownload(file.url, fileName: file.fileName),
      );
    }
    if (transfer.isComplete) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (transfer.isRunning) {
      return SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          value: transfer.progress,
          strokeWidth: 3,
        ),
      );
    }
    return const Icon(Icons.hourglass_empty);
  }

  Widget _buildCustomHeadersCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Headers',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add custom HTTP headers for authenticated requests',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _headerKeyController,
                    decoration: const InputDecoration(
                      hintText: 'Header name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _headerValueController,
                    decoration: const InputDecoration(
                      hintText: 'Value',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addHeader,
                  icon: const Icon(Icons.add_circle),
                ),
              ],
            ),
            if (_customHeaders.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._customHeaders.entries.map(
                (e) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.key),
                  subtitle: Text(
                    e.value.length > 30 ? '${e.value.substring(0, 30)}...' : e.value,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _removeHeader(e.key),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthExamplesCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authentication Examples',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildAuthExample(
              'Bearer Token',
              'Authorization: Bearer <token>',
              () {
                _headerKeyController.text = 'Authorization';
                _headerValueController.text = 'Bearer YOUR_TOKEN_HERE';
              },
            ),
            _buildAuthExample(
              'Basic Auth',
              'Authorization: Basic <base64>',
              () {
                _headerKeyController.text = 'Authorization';
                _headerValueController.text = 'Basic dXNlcjpwYXNz';
              },
            ),
            _buildAuthExample(
              'API Key',
              'X-API-Key: <key>',
              () {
                _headerKeyController.text = 'X-API-Key';
                _headerValueController.text = 'your-api-key';
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthExample(String title, String description, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(description, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
      trailing: const Icon(Icons.add, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildConfigOptionsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration Options',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'TransferConfigEntity options:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildConfigOption('maxRetries', '3', 'Max retry attempts on failure'),
            _buildConfigOption('allowResume', 'true', 'Enable resumable downloads'),
            _buildConfigOption('timeout', '30s', 'Request timeout'),
            _buildConfigOption('parallelChunks', '1', 'Parallel download chunks'),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigOption(String name, String defaultValue, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              name,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Text('= $defaultValue', style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogsCard(ThemeData theme) {
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
                  'Logs',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _logs.clear()),
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 100,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _logs.isEmpty ? 'No logs yet' : _logs.join('\n'),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
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

  Widget _buildCodeExample(ThemeData theme) {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.code, size: 16, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text(
                  'Code Example',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                '''
// Download file via HTTPS
final controller = TransferController.instance;

final result = await controller.download(
  url: 'https://example.com/large-file.zip',
  fileName: 'large-file.zip',
  config: TransferConfigEntity(
    headers: {
      'Authorization': 'Bearer your-token',
      'X-Custom-Header': 'value',
    },
    maxRetries: 3,
    allowResume: true,
  ),
);

// Track progress
final stream = result.valueOrNull;
if (stream != null) {
  await for (final entity in stream) {
    print('Progress: \${entity.progress * 100}%');
    print('Speed: \${entity.speed} bytes/sec');
    if (entity.isComplete) {
      print('Saved to: \${entity.filePath}');
    }
  }
}''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSampleTypeIcon(SampleFileType type) {
    return switch (type) {
      SampleFileType.image => Icons.image,
      SampleFileType.video => Icons.videocam,
      SampleFileType.audio => Icons.audiotrack,
      SampleFileType.document => Icons.description,
      SampleFileType.archive => Icons.folder_zip,
      SampleFileType.other => Icons.insert_drive_file,
    };
  }

  Color _getSampleTypeColor(SampleFileType type) {
    return switch (type) {
      SampleFileType.image => Colors.blue,
      SampleFileType.video => Colors.purple,
      SampleFileType.audio => Colors.orange,
      SampleFileType.document => Colors.red,
      SampleFileType.archive => Colors.brown,
      SampleFileType.other => Colors.grey,
    };
  }

  Color _getStatusColor(TransferEntity transfer) {
    if (transfer.isComplete) return Colors.green;
    if (transfer.isFailed) return Colors.red;
    if (transfer.isPaused) return Colors.amber;
    return Colors.blue;
  }

  String _getStatusLabel(TransferEntity transfer) {
    if (transfer.isComplete) return 'Completed';
    if (transfer.isFailed) return 'Failed';
    if (transfer.isPaused) return 'Paused';
    return 'Downloading';
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    if (bytesPerSecond < 1024 * 1024) return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSecond / 1024 / 1024).toStringAsFixed(1)} MB/s';
  }
}
