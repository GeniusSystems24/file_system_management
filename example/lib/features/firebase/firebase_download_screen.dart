import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Demonstrates downloading files from Firebase Storage.
///
/// This example shows how to:
/// - Download files from Firebase Storage URLs
/// - Handle Firebase Storage authentication
/// - Track download progress
/// - Resume interrupted downloads
class FirebaseDownloadScreen extends StatefulWidget {
  const FirebaseDownloadScreen({super.key});

  @override
  State<FirebaseDownloadScreen> createState() => _FirebaseDownloadScreenState();
}

class _FirebaseDownloadScreenState extends State<FirebaseDownloadScreen> {
  final TransferController _controller = TransferController.instance;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  TransferEntity? _currentTransfer;
  bool _isDownloading = false;
  final List<String> _logs = [];

  // Sample Firebase Storage URLs (replace with your own)
  final List<_FirebaseSample> _samples = [
    _FirebaseSample(
      name: 'Sample Image',
      description: 'Download a sample image from Firebase Storage',
      url:
          'https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o/images%2Fsample.jpg?alt=media',
      icon: Icons.image,
    ),
    _FirebaseSample(
      name: 'Sample Document',
      description: 'Download a PDF document from Firebase Storage',
      url:
          'https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o/documents%2Fsample.pdf?alt=media',
      icon: Icons.picture_as_pdf,
    ),
    _FirebaseSample(
      name: 'Sample Video',
      description: 'Download a video file from Firebase Storage',
      url:
          'https://firebasestorage.googleapis.com/v0/b/YOUR_PROJECT.appspot.com/o/videos%2Fsample.mp4?alt=media',
      icon: Icons.videocam,
    ),
  ];

  void _log(String message) {
    setState(() {
      _logs.insert(
        0,
        '${DateTime.now().toString().substring(11, 19)}: $message',
      );
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  Future<void> _startDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      _showError('Please enter a Firebase Storage URL');
      return;
    }

    if (!url.contains('firebasestorage.googleapis.com')) {
      _showError('Please enter a valid Firebase Storage URL');
      return;
    }

    setState(() {
      _isDownloading = true;
      _currentTransfer = null;
    });

    _log('Starting Firebase download...');
    _log('URL: ${url.substring(0, 50)}...');

    try {
      // Build headers with optional auth token
      Map<String, String>? headers;
      final token = _tokenController.text.trim();
      if (token.isNotEmpty) {
        headers = {'Authorization': 'Bearer $token'};
        _log('Using authentication token');
      }

      final result = await _controller.download(
        url: url,
        config: TransferConfigEntity(
          headers: headers,
          maxRetries: 3,
          allowResume: true,
        ),
      );

      final stream = result.valueOrNull;
      if (stream != null) {
        await for (final entity in stream) {
          setState(() => _currentTransfer = entity);

          if (entity.isComplete) {
            _log('Download completed!');
            _log('Saved to: ${entity.filePath}');
          } else if (entity.isFailed) {
            _log('Download failed: ${entity.errorMessage}');
          }
        }
      } else {
        _log('Failed: ${result.failureOrNull?.message}');
      }
    } catch (e) {
      _log('Error: $e');
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _cancelDownload() async {
    if (_currentTransfer != null) {
      await _controller.cancel(_currentTransfer!.id);
      _log('Download cancelled');
      setState(() {
        _isDownloading = false;
        _currentTransfer = null;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _selectSample(_FirebaseSample sample) {
    _urlController.text = sample.url;
    _log('Selected: ${sample.name}');
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Download')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          _buildInfoCard(theme),
          const SizedBox(height: 16),

          // URL Input
          _buildUrlInput(theme),
          const SizedBox(height: 16),

          // Auth Token Input
          _buildTokenInput(theme),
          const SizedBox(height: 16),

          // Sample URLs
          _buildSamplesCard(theme),
          const SizedBox(height: 16),

          // Progress Card
          _buildProgressCard(theme),
          const SizedBox(height: 16),

          // Action Buttons
          _buildActionButtons(theme),
          const SizedBox(height: 16),

          // Logs Card
          _buildLogsCard(theme),
          const SizedBox(height: 16),

          // Code Example
          _buildCodeExample(theme),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.cloud_download, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Firebase Storage Download',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Download files from Firebase Storage',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'This example demonstrates downloading files from Firebase Storage '
              'with support for authentication, progress tracking, and resume capability.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureChip('Auth Support', Icons.lock),
                _buildFeatureChip('Resume', Icons.replay),
                _buildFeatureChip('Progress', Icons.trending_up),
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
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildUrlInput(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase Storage URL',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://firebasestorage.googleapis.com/v0/b/...',
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
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenInput(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Auth Token (Optional)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text('Firebase Auth Token'),
                            content: const Text(
                              'If your Firebase Storage rules require authentication, '
                              'you need to provide a valid Firebase ID token.\n\n'
                              'You can get the token from:\n'
                              '• FirebaseAuth.instance.currentUser?.getIdToken()\n'
                              '• Your backend authentication service',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                    );
                  },
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Help'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                hintText: 'Firebase ID Token (if required)',
                prefixIcon: Icon(Icons.vpn_key),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSamplesCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sample URLs',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Replace these with your own Firebase Storage URLs',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            ..._samples.map(
              (sample) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(sample.icon, color: theme.colorScheme.primary),
                ),
                title: Text(sample.name),
                subtitle: Text(sample.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _selectSample(sample),
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
          children: [
            Text(
              'Progress',
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
                      Icons.cloud_download_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ready to download',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
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
            onPressed: _isDownloading ? null : _startDownload,
            icon: const Icon(Icons.cloud_download),
            label: const Text('Start Download'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (_isDownloading) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _cancelDownload,
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
              height: 120,
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
// Download from Firebase Storage
final controller = TransferController.instance;

// Get the download URL from Firebase Storage
final ref = FirebaseStorage.instance.ref('images/photo.jpg');
final url = await ref.getDownloadURL();

// Optional: Get auth token for protected files
final token = await FirebaseAuth.instance.currentUser?.getIdToken();

// Start download
final result = await controller.download(
  url: url,
  config: TransferConfigEntity(
    headers: token != null ? {'Authorization': 'Bearer \$token'} : null,
    maxRetries: 3,
    allowResume: true,
  ),
);

// Track progress
final stream = result.valueOrNull;
if (stream != null) {
  await for (final entity in stream) {
    print('Progress: \${entity.progress * 100}%');
    if (entity.isComplete) {
      print('Downloaded to: \${entity.filePath}');
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
    if (bytesPerSecond < 1024)
      return '${bytesPerSecond.toStringAsFixed(0)} B/s';
    if (bytesPerSecond < 1024 * 1024)
      return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSecond / 1024 / 1024).toStringAsFixed(1)} MB/s';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

class _FirebaseSample {
  final String name;
  final String description;
  final String url;
  final IconData icon;

  const _FirebaseSample({
    required this.name,
    required this.description,
    required this.url,
    required this.icon,
  });
}
