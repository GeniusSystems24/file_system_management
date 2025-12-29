import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Demonstrates uploading files via HTTPS.
///
/// This example shows how to:
/// - Upload files to HTTPS endpoints
/// - Handle various upload methods (PUT, POST, multipart)
/// - Track upload progress
/// - Resume interrupted uploads
class HttpsUploadScreen extends StatefulWidget {
  const HttpsUploadScreen({super.key});

  @override
  State<HttpsUploadScreen> createState() => _HttpsUploadScreenState();
}

class _HttpsUploadScreenState extends State<HttpsUploadScreen>
    with SingleTickerProviderStateMixin {
  final TransferController _controller = TransferController.instance;
  final TextEditingController _uploadUrlController = TextEditingController();

  late TabController _tabController;
  String? _selectedFilePath;
  String? _selectedFileName;
  int? _selectedFileSize;
  TransferEntity? _currentTransfer;
  bool _isUploading = false;
  final List<String> _logs = [];

  // Custom headers
  final Map<String, String> _customHeaders = {};
  final TextEditingController _headerKeyController = TextEditingController();
  final TextEditingController _headerValueController = TextEditingController();

  // Upload configuration
  String _uploadMethod = 'PUT';
  bool _chunkedUpload = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _uploadUrlController.dispose();
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

  Future<void> _pickFile() async {
    _showFilePickerDialog();
  }

  void _showFilePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'In a real app, you would use file_picker package.\n\n'
              'For this demo, select a sample file:',
            ),
            const SizedBox(height: 16),
            ..._sampleFiles.map((file) => ListTile(
              leading: Icon(file.icon),
              title: Text(file.name),
              subtitle: Text(file.size),
              onTap: () {
                setState(() {
                  _selectedFilePath = file.path;
                  _selectedFileName = file.name;
                  _selectedFileSize = file.sizeBytes;
                });
                _log('Selected: ${file.name}');
                Navigator.pop(context);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  final List<_SampleFile> _sampleFiles = [
    _SampleFile(
      name: 'sample_image.jpg',
      path: '/storage/emulated/0/Download/sample_image.jpg',
      size: '2.5 MB',
      sizeBytes: 2621440,
      icon: Icons.image,
    ),
    _SampleFile(
      name: 'document.pdf',
      path: '/storage/emulated/0/Download/document.pdf',
      size: '1.2 MB',
      sizeBytes: 1258291,
      icon: Icons.picture_as_pdf,
    ),
    _SampleFile(
      name: 'video.mp4',
      path: '/storage/emulated/0/Download/video.mp4',
      size: '15 MB',
      sizeBytes: 15728640,
      icon: Icons.videocam,
    ),
    _SampleFile(
      name: 'archive.zip',
      path: '/storage/emulated/0/Download/archive.zip',
      size: '50 MB',
      sizeBytes: 52428800,
      icon: Icons.folder_zip,
    ),
  ];

  Future<void> _startUpload() async {
    if (_selectedFilePath == null) {
      _showError('Please select a file first');
      return;
    }

    final uploadUrl = _uploadUrlController.text.trim();
    if (uploadUrl.isEmpty) {
      _showError('Please enter an upload URL');
      return;
    }

    setState(() {
      _isUploading = true;
      _currentTransfer = null;
    });

    _log('Starting upload: $_selectedFileName');
    _log('URL: ${uploadUrl.substring(0, 50.clamp(0, uploadUrl.length))}...');
    _log('Method: $_uploadMethod');

    try {
      final headers = Map<String, String>.from(_customHeaders);
      headers['Content-Type'] = _getContentType(_selectedFileName!);

      final result = await _controller.upload(
        url: uploadUrl,
        filePath: _selectedFilePath!,
        fileName: _selectedFileName,
        config: TransferConfigEntity(
          headers: headers,
          maxRetries: 3,
          allowResume: true,
          chunkSize: _chunkedUpload ? 1024 * 1024 : null, // 1MB chunks
        ),
      );

      final stream = result.valueOrNull;
      if (stream != null) {
        await for (final entity in stream) {
          setState(() => _currentTransfer = entity);

          if (entity.isComplete) {
            _log('Upload completed successfully!');
          } else if (entity.isFailed) {
            _log('Upload failed: ${entity.errorMessage}');
          }
        }
      } else {
        _log('Error: ${result.failureOrNull?.message}');
      }
    } catch (e) {
      _log('Error: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _cancelUpload() async {
    if (_currentTransfer != null) {
      await _controller.cancel(_currentTransfer!.id);
      _log('Upload cancelled');
      setState(() {
        _isUploading = false;
        _currentTransfer = null;
      });
    }
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
  }

  String _getContentType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mp3' => 'audio/mpeg',
      'pdf' => 'application/pdf',
      'zip' => 'application/zip',
      'json' => 'application/json',
      _ => 'application/octet-stream',
    };
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
        title: const Text('HTTPS Upload'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.upload), text: 'Upload'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
            Tab(icon: Icon(Icons.code), text: 'Examples'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUploadTab(theme),
          _buildSettingsTab(theme),
          _buildExamplesTab(theme),
        ],
      ),
    );
  }

  Widget _buildUploadTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // File Selection
        _buildFileSelectionCard(theme),
        const SizedBox(height: 16),

        // Upload URL
        _buildUploadUrlCard(theme),
        const SizedBox(height: 16),

        // Progress
        _buildProgressCard(theme),
        const SizedBox(height: 16),

        // Actions
        _buildActionButtons(theme),
        const SizedBox(height: 16),

        // Logs
        _buildLogsCard(theme),
      ],
    );
  }

  Widget _buildSettingsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Upload Method
        _buildUploadMethodCard(theme),
        const SizedBox(height: 16),

        // Custom Headers
        _buildCustomHeadersCard(theme),
        const SizedBox(height: 16),

        // Chunked Upload
        _buildChunkedUploadCard(theme),
      ],
    );
  }

  Widget _buildExamplesTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildEndpointExamplesCard(theme),
        const SizedBox(height: 16),
        _buildCodeExampleCard(theme),
      ],
    );
  }

  Widget _buildFileSelectionCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select File',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedFilePath == null)
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select a file',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFileIcon(_selectedFileName!),
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(_selectedFileName!),
                subtitle: Text(_formatBytes(_selectedFileSize ?? 0)),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _selectedFilePath = null;
                    _selectedFileName = null;
                    _selectedFileSize = null;
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadUrlCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload URL',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _uploadUrlController,
              decoration: InputDecoration(
                hintText: 'https://api.example.com/upload',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste),
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _uploadUrlController.text = data!.text!;
                    }
                  },
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme) {
    final transfer = _currentTransfer;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Progress',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (transfer == null)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to upload',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: transfer.progress,
                  minHeight: 12,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(transfer.progress * 100).toStringAsFixed(1)}%'),
                  Text(_formatSpeed(transfer.speed)),
                  Text(_formatBytes(transfer.transferredBytes)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transfer).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(transfer),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(transfer),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (transfer.isRunning)
                    Text(
                      'ETA: ${_formatDuration(transfer.timeRemaining)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _startUpload,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Start Upload'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (_isUploading) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _cancelUpload,
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadMethodCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Method',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'PUT', label: Text('PUT')),
                ButtonSegment(value: 'POST', label: Text('POST')),
              ],
              selected: {_uploadMethod},
              onSelectionChanged: (value) {
                setState(() => _uploadMethod = value.first);
              },
            ),
            const SizedBox(height: 8),
            Text(
              _uploadMethod == 'PUT'
                  ? 'PUT: Upload file directly to URL (S3, GCS, etc.)'
                  : 'POST: Upload as form data (REST APIs)',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
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
            const SizedBox(height: 12),
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
                  subtitle: Text(e.value),
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

  Widget _buildChunkedUploadCard(ThemeData theme) {
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
                  'Chunked Upload',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _chunkedUpload,
                  onChanged: (value) => setState(() => _chunkedUpload = value),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Split large files into 1MB chunks for more reliable uploads. '
              'Useful for unstable connections.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointExamplesCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Endpoint Examples',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildEndpointExample(
              'AWS S3 Pre-signed URL',
              'https://bucket.s3.amazonaws.com/key?signature=...',
              'PUT with Content-Type header',
              Icons.cloud,
            ),
            _buildEndpointExample(
              'Google Cloud Storage',
              'https://storage.googleapis.com/bucket/object',
              'PUT with Authorization header',
              Icons.cloud_queue,
            ),
            _buildEndpointExample(
              'REST API Upload',
              'https://api.example.com/files/upload',
              'POST multipart/form-data',
              Icons.api,
            ),
            _buildEndpointExample(
              'Cloudflare R2',
              'https://account.r2.cloudflarestorage.com/bucket/key',
              'PUT with S3 compatible API',
              Icons.cloud_circle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndpointExample(String title, String url, String description, IconData icon) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            url,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(description, style: const TextStyle(fontSize: 11)),
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

  Widget _buildCodeExampleCard(ThemeData theme) {
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
// Upload file via HTTPS
final controller = TransferController.instance;

// Upload to S3 pre-signed URL
final result = await controller.upload(
  url: 'https://bucket.s3.amazonaws.com/file.jpg?AWSAccessKeyId=...',
  filePath: '/path/to/local/file.jpg',
  fileName: 'file.jpg',
  config: TransferConfigEntity(
    headers: {
      'Content-Type': 'image/jpeg',
      'x-amz-acl': 'public-read',
    },
    maxRetries: 3,
    allowResume: true,
    chunkSize: 5 * 1024 * 1024, // 5MB chunks
  ),
);

// Track progress
final stream = result.valueOrNull;
if (stream != null) {
  await for (final entity in stream) {
    print('Upload progress: \${entity.progress * 100}%');
    print('Speed: \${entity.speed} bytes/sec');
    if (entity.isComplete) {
      print('Upload completed!');
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

  IconData _getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => Icons.image,
      'mp4' || 'mov' || 'avi' => Icons.videocam,
      'mp3' || 'wav' || 'aac' => Icons.audiotrack,
      'pdf' => Icons.picture_as_pdf,
      'doc' || 'docx' => Icons.description,
      'zip' || 'rar' => Icons.folder_zip,
      _ => Icons.insert_drive_file,
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
    return 'Uploading';
  }

  String _formatSpeed(double bytesPerSecond) {
    if (bytesPerSecond < 1024) return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    if (bytesPerSecond < 1024 * 1024) return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSecond / 1024 / 1024).toStringAsFixed(1)} MB/s';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}s';
  }
}

class _SampleFile {
  final String name;
  final String path;
  final String size;
  final int sizeBytes;
  final IconData icon;

  const _SampleFile({
    required this.name,
    required this.path,
    required this.size,
    required this.sizeBytes,
    required this.icon,
  });
}
