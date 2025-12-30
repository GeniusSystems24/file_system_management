import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demo screen showing theme customization capabilities.
class ThemeDemoScreen extends StatefulWidget {
  const ThemeDemoScreen({super.key});

  @override
  State<ThemeDemoScreen> createState() => _ThemeDemoScreenState();
}

class _ThemeDemoScreenState extends State<ThemeDemoScreen> {
  SocialSkin _selectedSkin = SocialSkin.whatsapp;
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final theme = _getThemeData();

    return Theme(
      data: Theme.of(context).copyWith(extensions: [theme]),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تخصيص الثيمات'),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
              tooltip: _isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSkinSelector(),
            const SizedBox(height: 24),
            _buildThemePreview(theme),
            const SizedBox(height: 24),
            _buildColorPalette(theme),
            const SizedBox(height: 24),
            _buildWidgetSamples(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر الستايل',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  SocialSkin.values.map((skin) {
                    final isSelected = skin == _selectedSkin;
                    return ChoiceChip(
                      label: Text(_getSkinName(skin)),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedSkin = skin),
                      avatar: Icon(
                        _getSkinIcon(skin),
                        size: 18,
                        color: isSelected ? Colors.white : _getSkinColor(skin),
                      ),
                      selectedColor: _getSkinColor(skin),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePreview(SocialTransferThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'معاينة الثيم',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Sample outgoing message bubble
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.outgoingBubbleColor,
                  borderRadius: theme.outgoingBubbleBorderRadius,
                ),
                child: Text(
                  'رسالة صادرة',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Sample incoming message bubble
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.incomingBubbleColor,
                  borderRadius: theme.incomingBubbleBorderRadius,
                ),
                child: Text(
                  'رسالة واردة',
                  style: TextStyle(color: theme.textColor),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Progress indicator sample
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: 0.65,
                    backgroundColor: theme.progressBackgroundColor,
                    valueColor: AlwaysStoppedAnimation(
                      theme.progressForegroundColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('65%'),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('تحميل'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check),
                  label: const Text('نجاح'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.successColor,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.error),
                  label: const Text('خطأ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.errorColor,
                  ),
                ),
              ],
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
              'لوحة الألوان',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildColorChip('الرئيسي', theme.primaryColor),
                _buildColorChip('الثانوي', theme.secondaryColor),
                _buildColorChip('التقدم', theme.progressForegroundColor),
                _buildColorChip('النجاح', theme.successColor),
                _buildColorChip('الخطأ', theme.errorColor),
                _buildColorChip('التحذير', theme.warningColor),
                _buildColorChip('الإيقاف', theme.pausedColor),
                _buildColorChip('فقاعة صادرة', theme.outgoingBubbleColor),
                _buildColorChip('فقاعة واردة', theme.incomingBubbleColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
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
              'عينات الويدجت',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Transfer progress indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProgressSample(theme, 0.0, 'انتظار'),
                _buildProgressSample(theme, 0.45, 'جاري'),
                _buildProgressSample(theme, 1.0, 'مكتمل'),
              ],
            ),
            const SizedBox(height: 24),

            // Status badges
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusBadge(
                  'جاري',
                  theme.progressForegroundColor,
                  Icons.downloading,
                ),
                _buildStatusBadge(
                  'متوقف',
                  theme.pausedColor,
                  Icons.pause_circle,
                ),
                _buildStatusBadge(
                  'مكتمل',
                  theme.successColor,
                  Icons.check_circle,
                ),
                _buildStatusBadge('فشل', theme.errorColor, Icons.error),
                _buildStatusBadge('ملغي', Colors.grey, Icons.cancel),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSample(
    SocialTransferThemeData theme,
    double value,
    String label,
  ) {
    final color =
        value >= 1.0 ? theme.successColor : theme.progressForegroundColor;

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
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  SocialTransferThemeData _getThemeData() {
    return switch (_selectedSkin) {
      SocialSkin.whatsapp => SocialTransferThemeData.whatsapp(
        isDark: _isDarkMode,
      ),
      SocialSkin.telegram => SocialTransferThemeData.telegram(
        isDark: _isDarkMode,
      ),
      SocialSkin.instagram => SocialTransferThemeData.instagram(
        isDark: _isDarkMode,
      ),
      SocialSkin.custom => SocialTransferThemeData(
        skin: SocialSkin.custom,
        primaryColor: Colors.purple,
        secondaryColor: Colors.purpleAccent,
        bubbleColor: _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        outgoingBubbleColor:
            _isDarkMode ? Colors.purple.shade800 : Colors.purple.shade100,
        incomingBubbleColor:
            _isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        progressBackgroundColor: Colors.purple.shade100,
        progressForegroundColor: Colors.purple,
        successColor: Colors.green,
        errorColor: Colors.red,
        warningColor: Colors.orange,
        pausedColor: Colors.amber,
        textColor: _isDarkMode ? Colors.white : Colors.black87,
        subtitleColor: _isDarkMode ? Colors.white70 : Colors.black54,
        iconColor: Colors.purple,
        overlayColor: Colors.black38,
        bubbleBorderRadius: BorderRadius.circular(12),
        progressBorderRadius: BorderRadius.circular(4),
        buttonBorderRadius: BorderRadius.circular(20),
        thumbnailBorderRadius: BorderRadius.circular(8),
      ),
    };
  }

  String _getSkinName(SocialSkin skin) {
    return switch (skin) {
      SocialSkin.whatsapp => 'واتساب',
      SocialSkin.telegram => 'تيليجرام',
      SocialSkin.instagram => 'انستجرام',
      SocialSkin.custom => 'مخصص',
    };
  }

  IconData _getSkinIcon(SocialSkin skin) {
    return switch (skin) {
      SocialSkin.whatsapp => Icons.chat,
      SocialSkin.telegram => Icons.send,
      SocialSkin.instagram => Icons.camera_alt,
      SocialSkin.custom => Icons.palette,
    };
  }

  Color _getSkinColor(SocialSkin skin) {
    return switch (skin) {
      SocialSkin.whatsapp => const Color(0xFF00A884),
      SocialSkin.telegram => const Color(0xFF3390EC),
      SocialSkin.instagram => const Color(0xFFE1306C),
      SocialSkin.custom => Colors.purple,
    };
  }
}
