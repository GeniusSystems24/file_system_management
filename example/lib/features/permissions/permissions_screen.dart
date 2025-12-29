import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demonstrates permissions helper functionality.
///
/// Built-in permissions helper for storage and notifications.
class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _storageGranted = false;
  bool _notificationGranted = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isChecking = true);

    // In a real app, you would check actual permissions
    // For demo purposes, we simulate the check
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isChecking = false;
      // Simulated permission states
    });
  }

  Future<void> _requestStoragePermission() async {
    // In a real app, use PermissionsHelper.requestStoragePermission()
    setState(() => _storageGranted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Storage permission granted')),
    );
  }

  Future<void> _requestNotificationPermission() async {
    // In a real app, use PermissionsHelper.requestNotificationPermission()
    setState(() => _notificationGranted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification permission granted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPermissions,
          ),
        ],
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Card
                _buildInfoCard(theme),
                const SizedBox(height: 16),

                // Storage Permission
                _buildPermissionCard(
                  theme,
                  title: 'Storage Permission',
                  description: 'Required to save downloaded files to the device.',
                  icon: Icons.folder,
                  color: Colors.blue,
                  isGranted: _storageGranted,
                  onRequest: _requestStoragePermission,
                  androidInfo: 'Android 10+: Uses scoped storage\nAndroid 13+: Granular media permissions',
                ),
                const SizedBox(height: 12),

                // Notification Permission
                _buildPermissionCard(
                  theme,
                  title: 'Notification Permission',
                  description: 'Required for download progress notifications.',
                  icon: Icons.notifications,
                  color: Colors.orange,
                  isGranted: _notificationGranted,
                  onRequest: _requestNotificationPermission,
                  androidInfo: 'Android 13+: POST_NOTIFICATIONS permission required',
                ),
                const SizedBox(height: 24),

                // Android Versions
                _buildAndroidVersionsCard(theme),
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
                Icon(Icons.security, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Permissions Helper',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'The library includes a permissions helper that handles the complexity '
              'of Android permission changes across different versions.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(
    ThemeData theme, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isGranted,
    required VoidCallback onRequest,
    required String androidInfo,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(isGranted),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.android, size: 20, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      androidInfo,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isGranted ? null : onRequest,
                icon: Icon(isGranted ? Icons.check : Icons.lock_open),
                label: Text(isGranted ? 'Granted' : 'Request Permission'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isGranted ? Colors.green : null,
                  foregroundColor: isGranted ? Colors.white : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isGranted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isGranted ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isGranted ? 'Granted' : 'Not Granted',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isGranted ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _buildAndroidVersionsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.android, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  'Android Version Compatibility',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVersionRow('Android 6-9', 'READ/WRITE_EXTERNAL_STORAGE'),
            const Divider(),
            _buildVersionRow('Android 10', 'Scoped Storage with legacy flag'),
            const Divider(),
            _buildVersionRow('Android 11-12', 'MANAGE_EXTERNAL_STORAGE or SAF'),
            const Divider(),
            _buildVersionRow('Android 13+', 'READ_MEDIA_* granular permissions'),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionRow(String version, String permission) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              version,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              permission,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
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
                  'Usage Example',
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
// Check and request storage permission
final hasStorage = await PermissionsHelper.hasStoragePermission();
if (!hasStorage) {
  await PermissionsHelper.requestStoragePermission();
}

// Check and request notification permission (Android 13+)
final hasNotification = await PermissionsHelper.hasNotificationPermission();
if (!hasNotification) {
  await PermissionsHelper.requestNotificationPermission();
}

// Or request all required permissions at once
await PermissionsHelper.requestAllPermissions();
''',
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
}
