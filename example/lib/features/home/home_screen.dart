import 'package:flutter/material.dart';
import '../../shared/widgets/feature_card.dart';

/// Home screen displaying all available feature demos.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File System Management'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
            tooltip: 'About',
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildHeader(context),

          // Downloads Section
          const SectionHeader(
            title: 'DOWNLOADS',
            icon: Icons.cloud_download,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: const [
                FeatureCard(
                  title: 'Parallel Downloads',
                  description: 'Split large files into chunks for faster downloads using multiple connections',
                  icon: Icons.speed,
                  route: '/parallel-downloads',
                  color: Colors.blue,
                  tags: ['Fast', 'Chunked', 'Mirror Support'],
                ),
                SizedBox(height: 12),
                FeatureCard(
                  title: 'Batch Downloads',
                  description: 'Download multiple files efficiently with progress tracking',
                  icon: Icons.download_for_offline,
                  route: '/batch-downloads',
                  color: Colors.indigo,
                  tags: ['Multiple Files', 'Progress'],
                ),
                SizedBox(height: 12),
                FeatureCard(
                  title: 'Background Downloads',
                  description: 'Continue downloads when app is in background with foreground service',
                  icon: Icons.downloading,
                  route: '/background-downloads',
                  color: Colors.teal,
                  tags: ['Background', 'Foreground Service', 'Android'],
                ),
              ],
            ),
          ),

          // Queue Management Section
          const SectionHeader(
            title: 'QUEUE MANAGEMENT',
            icon: Icons.queue,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: const [
                FeatureCard(
                  title: 'Queue Management',
                  description: 'Control concurrent transfers with priority queuing and limits',
                  icon: Icons.format_list_numbered,
                  route: '/queue-management',
                  color: Colors.purple,
                  tags: ['Priority', 'Concurrency', 'Pause/Resume'],
                ),
              ],
            ),
          ),

          // UI Components Section
          const SectionHeader(
            title: 'UI COMPONENTS',
            icon: Icons.widgets,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: const [
                FeatureCard(
                  title: 'Message Widgets',
                  description: 'Ready-to-use widgets for chat applications with transfer progress',
                  icon: Icons.chat_bubble,
                  route: '/message-widgets',
                  color: Colors.green,
                  tags: ['Chat', 'Image', 'Video', 'Audio', 'File'],
                ),
                SizedBox(height: 12),
                FeatureCard(
                  title: 'Social Media Themes',
                  description: 'WhatsApp, Telegram, Instagram-inspired designs with customization',
                  icon: Icons.palette,
                  route: '/social-themes',
                  color: Colors.pink,
                  tags: ['WhatsApp', 'Telegram', 'Instagram', 'Custom'],
                ),
              ],
            ),
          ),

          // Advanced Features Section
          const SectionHeader(
            title: 'ADVANCED FEATURES',
            icon: Icons.settings_suggest,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: const [
                FeatureCard(
                  title: 'Custom Handlers',
                  description: 'Inject your own download/upload providers (Firebase, AWS, etc.)',
                  icon: Icons.extension,
                  route: '/custom-handlers',
                  color: Colors.orange,
                  tags: ['Firebase', 'AWS', 'Custom Backend'],
                ),
                SizedBox(height: 12),
                FeatureCard(
                  title: 'Shared Storage',
                  description: 'Move files to Downloads folder and resume failed transfers',
                  icon: Icons.folder_shared,
                  route: '/shared-storage',
                  color: Colors.brown,
                  tags: ['Resume Failed', 'Move to Downloads'],
                ),
                SizedBox(height: 12),
                FeatureCard(
                  title: 'Cache Management',
                  description: 'Automatic file caching with URL recognition and cleanup',
                  icon: Icons.cached,
                  route: '/cache-management',
                  color: Colors.cyan,
                  tags: ['Auto Cache', 'URL Recognition', 'Cleanup'],
                ),
              ],
            ),
          ),

          // System Features Section
          const SectionHeader(
            title: 'SYSTEM FEATURES',
            icon: Icons.system_security_update,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: const [
                FeatureCard(
                  title: 'Permissions',
                  description: 'Built-in permissions helper for storage and notifications',
                  icon: Icons.security,
                  route: '/permissions',
                  color: Colors.red,
                  tags: ['Storage', 'Notifications', 'Android 13+'],
                ),
                SizedBox(height: 12),
                FeatureCard(
                  title: 'RTL Support',
                  description: 'Full right-to-left language support for Arabic, Hebrew, etc.',
                  icon: Icons.format_textdirection_r_to_l,
                  route: '/rtl-support',
                  color: Colors.deepPurple,
                  tags: ['Arabic', 'Hebrew', 'Persian'],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.folder_special,
                size: 40,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'file_system_management',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Comprehensive file transfer library for Flutter',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip(context, '13+', 'Features'),
              _buildStatChip(context, '5', 'Themes'),
              _buildStatChip(context, '6', 'Widgets'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String value, String label) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'File System Management',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.folder_special, size: 48),
      children: [
        const Text(
          'A comprehensive file transfer library for Flutter applications. '
          'Supports parallel downloads, queue management, background transfers, '
          'and beautiful message widgets for chat apps.',
        ),
      ],
    );
  }
}
