import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demonstrates social media theme customization.
///
/// WhatsApp, Telegram, Instagram-inspired designs with full customization.
class SocialThemesScreen extends StatefulWidget {
  const SocialThemesScreen({super.key});

  @override
  State<SocialThemesScreen> createState() => _SocialThemesScreenState();
}

class _SocialThemesScreenState extends State<SocialThemesScreen> {
  SocialSkin _selectedSkin = SocialSkin.whatsapp;
  bool _isDarkMode = false;

  SocialTransferThemeData get _currentTheme {
    return switch (_selectedSkin) {
      SocialSkin.whatsapp => SocialTransferThemeData.whatsapp(isDark: _isDarkMode),
      SocialSkin.telegram => SocialTransferThemeData.telegram(isDark: _isDarkMode),
      SocialSkin.instagram => SocialTransferThemeData.instagram(isDark: _isDarkMode),
      SocialSkin.custom => _buildCustomTheme(),
    };
  }

  SocialTransferThemeData _buildCustomTheme() {
    return SocialTransferThemeData(
      skin: SocialSkin.custom,
      primaryColor: Colors.deepPurple,
      secondaryColor: Colors.deepPurpleAccent,
      bubbleColor: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
      outgoingBubbleColor: _isDarkMode ? Colors.deepPurple.shade800 : Colors.deepPurple.shade50,
      incomingBubbleColor: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
      progressBackgroundColor: Colors.deepPurple.shade100,
      progressForegroundColor: Colors.deepPurple,
      successColor: Colors.green,
      errorColor: Colors.red,
      warningColor: Colors.orange,
      pausedColor: Colors.amber,
      textColor: _isDarkMode ? Colors.white : Colors.black87,
      subtitleColor: _isDarkMode ? Colors.white70 : Colors.black54,
      iconColor: Colors.deepPurple,
      overlayColor: Colors.black38,
      bubbleBorderRadius: BorderRadius.circular(20),
      progressBorderRadius: BorderRadius.circular(4),
      buttonBorderRadius: BorderRadius.circular(20),
      thumbnailBorderRadius: BorderRadius.circular(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentTheme;

    return Theme(
      data: Theme.of(context).copyWith(
        extensions: [theme],
      ),
      child: Scaffold(
        backgroundColor: _isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Social Media Themes'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              tooltip: 'Toggle Dark Mode',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Theme Selector
            _buildThemeSelector(),
            const SizedBox(height: 16),

            // Theme Info
            _buildThemeInfo(theme),
            const SizedBox(height: 16),

            // Preview Section
            _buildPreviewSection(theme),
            const SizedBox(height: 16),

            // Color Palette
            _buildColorPalette(theme),
            const SizedBox(height: 16),

            // Widget Samples
            _buildWidgetSamples(theme),
            const SizedBox(height: 16),

            // Code Example
            _buildCodeExample(),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Theme',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildThemeChip(SocialSkin.whatsapp, 'WhatsApp', const Color(0xFF25D366)),
                _buildThemeChip(SocialSkin.telegram, 'Telegram', const Color(0xFF0088CC)),
                _buildThemeChip(SocialSkin.instagram, 'Instagram', const Color(0xFFE1306C)),
                _buildThemeChip(SocialSkin.custom, 'Custom', Colors.deepPurple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip(SocialSkin skin, String label, Color color) {
    final isSelected = _selectedSkin == skin;

    return FilterChip(
      selected: isSelected,
      label: Text(label),
      avatar: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      onSelected: (_) => setState(() => _selectedSkin = skin),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
    );
  }

  Widget _buildThemeInfo(SocialTransferThemeData theme) {
    final skinName = switch (_selectedSkin) {
      SocialSkin.whatsapp => 'WhatsApp',
      SocialSkin.telegram => 'Telegram',
      SocialSkin.instagram => 'Instagram',
      SocialSkin.custom => 'Custom',
    };

    final skinDescription = switch (_selectedSkin) {
      SocialSkin.whatsapp => 'Clean, minimalist design with green accents. Rounded bubbles with subtle shadows.',
      SocialSkin.telegram => 'Blue-themed design with rounded corners. Includes speed and ETA display.',
      SocialSkin.instagram => 'Modern gradient-inspired design. Circular progress indicators.',
      SocialSkin.custom => 'Fully customizable theme. Define your own colors, shapes, and behavior.',
    };

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
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.palette, color: theme.primaryColor),
                ),
                const SizedBox(width: 12),
                Text(
                  skinName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(skinDescription),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(SocialTransferThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Message Bubbles Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Outgoing bubble
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: theme.bubblePadding,
                constraints: BoxConstraints(maxWidth: theme.maxBubbleWidth),
                decoration: BoxDecoration(
                  color: theme.outgoingBubbleColor,
                  borderRadius: theme.outgoingBubbleBorderRadius,
                  boxShadow: theme.bubbleShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Outgoing message with file',
                      style: TextStyle(color: theme.textColor),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: theme.progressBorderRadius,
                      child: LinearProgressIndicator(
                        value: 0.65,
                        backgroundColor: theme.progressBackgroundColor,
                        valueColor: AlwaysStoppedAnimation(theme.progressForegroundColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Incoming bubble
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: theme.bubblePadding,
                constraints: BoxConstraints(maxWidth: theme.maxBubbleWidth),
                decoration: BoxDecoration(
                  color: theme.incomingBubbleColor,
                  borderRadius: theme.incomingBubbleBorderRadius,
                  boxShadow: theme.bubbleShadow,
                ),
                child: Text(
                  'Incoming message',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPalette(SocialTransferThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Color Palette',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildColorChip('Primary', theme.primaryColor),
                _buildColorChip('Secondary', theme.secondaryColor),
                _buildColorChip('Progress', theme.progressForegroundColor),
                _buildColorChip('Success', theme.successColor),
                _buildColorChip('Error', theme.errorColor),
                _buildColorChip('Warning', theme.warningColor),
                _buildColorChip('Paused', theme.pausedColor),
                _buildColorChip('Outgoing', theme.outgoingBubbleColor),
                _buildColorChip('Incoming', theme.incomingBubbleColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.computeLuminance() > 0.5 ? Colors.black : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWidgetSamples(SocialTransferThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Indicators',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Progress samples
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressSample(theme, 0.0, 'Pending'),
                _buildProgressSample(theme, 0.45, 'Running'),
                _buildProgressSample(theme, 1.0, 'Complete'),
              ],
            ),
            const SizedBox(height: 24),

            // Status badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusBadge('Running', theme.progressForegroundColor, Icons.downloading),
                _buildStatusBadge('Paused', theme.pausedColor, Icons.pause_circle),
                _buildStatusBadge('Complete', theme.successColor, Icons.check_circle),
                _buildStatusBadge('Failed', theme.errorColor, Icons.error),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSample(SocialTransferThemeData theme, double value, String label) {
    final color = value >= 1.0 ? theme.successColor : theme.progressForegroundColor;

    return Column(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                backgroundColor: theme.progressBackgroundColor,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              if (value >= 1.0)
                Icon(Icons.check, color: color)
              else
                Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeExample() {
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
MaterialApp(
  theme: ThemeData(
    extensions: [
      SocialTransferThemeData.whatsapp(),
      // or: SocialTransferThemeData.telegram(),
      // or: SocialTransferThemeData.instagram(),
    ],
  ),
)

// Access theme in widgets:
final theme = context.socialTransferTheme;
// or: Theme.of(context).extension<SocialTransferThemeData>();
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
