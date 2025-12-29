import 'dart:io';

import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demonstrates uploading files to Firebase Storage.
///
/// This example shows how to:
/// - Upload files to Firebase Storage using signed URLs
/// - Handle authentication with Firebase tokens
/// - Track upload progress
/// - Resume interrupted uploads
class FirebaseUploadScreen extends StatefulWidget {
  const FirebaseUploadScreen({super.key});

  @override
  State<FirebaseUploadScreen> createState() => _FirebaseUploadScreenState();
}

class _FirebaseUploadScreenState extends State<FirebaseUploadScreen> {
  final TransferController _controller = TransferController.instance;
  final TextEditingController _uploadUrlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  String? _selectedFilePath;
  String? _selectedFileName;
  int? _selectedFileSize;
  TransferEntity? _currentTransfer;
  bool _isUploading = false;
  final List<String> _logs = [];

  void _log(String message) {
    setState(() {
      _logs.insert(0, '${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logs.length > 50) _logs.removeLast();
    });
  }

  Future<void> _pickFile() async {
    // In a real app, use file_picker package
    // For demo, we'll use a placeholder
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
              'For this demo, enter a file path manually:',
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: '/path/to/file.jpg',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  setState(() {
                    _selectedFilePath = value;
                    _selectedFileName = value.split('/').last;
                    _selectedFileSize = null; // Would get from file
                  });
                  _log('Selected: $_selectedFileName');
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Demo file selection
              setState(() {
                _selectedFilePath = '/storage/emulated/0/Download/sample.jpg';
                _selectedFileName = 'sample.jpg';
                _selectedFileSize = 1024 * 1024 * 2; // 2MB
              });
              _log('Selected demo file: $_selectedFileName');
              Navigator.pop(context);
            },
            child: const Text('Use Demo File'),
          ),
        ],
      ),
    );
  }

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

    _log('Starting Firebase upload...');
    _log('File: $_selectedFileName');

    try {
      // Build headers with optional auth token
      Map<String, String>? headers;
      final token = _tokenController.text.trim();
      if (token.isNotEmpty) {
        headers = {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/octet-stream',
        };
        _log('Using authentication token');
      }

      final result = await _controller.upload(
        url: uploadUrl,
        filePath: _selectedFilePath!,
        fileName: _selectedFileName,
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
            _log('Upload completed!');
            _log('File uploaded successfully');
          } else if (entity.isFailed) {
            _log('Upload failed: ${entity.errorMessage}');
          }
        }
      } else {
        _log('Failed: ${result.failureOrNull?.message}');
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _uploadUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Upload'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info Card
          _buildInfoCard(theme),
          const SizedBox(height: 16),

          // File Selection
          _buildFileSelectionCard(theme),
          const SizedBox(height: 16),

          // Upload URL Input
          _buildUploadUrlInput(theme),
          const SizedBox(height: 16),

          // Auth Token Input
          _buildTokenInput(theme),
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
                  child: const Icon(Icons.cloud_upload, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Firebase Storage Upload',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Upload files to Firebase Storage',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Upload files to Firebase Storage using signed upload URLs. '
              'This approach is recommended for large files and supports '
              'resumable uploads.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You need to generate a signed upload URL from your backend '
                      'or Firebase Cloud Functions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                    border: Border.all(
                      color: theme.colorScheme.outline,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select a file',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
                subtitle: Text(
                  _selectedFileSize != null
                      ? _formatBytes(_selectedFileSize!)
                      : 'Size unknown',
                ),
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

  Widget _buildUploadUrlInput(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Signed Upload URL',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Signed Upload URL'),
                        content: const Text(
                          'Firebase Storage requires a signed URL for uploads.\n\n'
                          'Generate this URL using:\n'
                          '• Firebase Admin SDK in your backend\n'
                          '• Cloud Functions for Firebase\n\n'
                          'Example Cloud Function:\n\n'
                          'const bucket = admin.storage().bucket();\n'
                          'const [url] = await bucket.file(path)\n'
                          '  .getSignedUrl({ action: "write", expires: "..." });',
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
              controller: _uploadUrlController,
              decoration: const InputDecoration(
                hintText: 'Paste your signed upload URL here',
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
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
            Text(
              'Auth Token (Optional)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
            onPressed: _isUploading ? null : _startUpload,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Start Upload'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
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
// Upload to Firebase Storage
final controller = TransferController.instance;

// Get signed upload URL from your backend
final uploadUrl = await getSignedUploadUrl('images/photo.jpg');

// Optional: Get auth token
final token = await FirebaseAuth.instance.currentUser?.getIdToken();

// Start upload
final result = await controller.upload(
  url: uploadUrl,
  filePath: '/path/to/local/file.jpg',
  fileName: 'photo.jpg',
  config: TransferConfigEntity(
    headers: {
      'Authorization': 'Bearer \$token',
      'Content-Type': 'application/octet-stream',
    },
    maxRetries: 3,
    allowResume: true,
  ),
);

// Track progress
final stream = result.valueOrNull;
if (stream != null) {
  await for (final entity in stream) {
    print('Upload progress: \${entity.progress * 100}%');
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
}
