import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Settings screen for configuring app appearance.
class SettingsScreen extends StatelessWidget {
  final SocialSkin currentSkin;
  final ThemeMode themeMode;
  final bool isRtl;
  final ValueChanged<SocialSkin> onSkinChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<bool> onRtlChanged;

  const SettingsScreen({
    super.key,
    required this.currentSkin,
    required this.themeMode,
    required this.isRtl,
    required this.onSkinChanged,
    required this.onThemeModeChanged,
    required this.onRtlChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        children: [
          // Skin selection
          _buildSectionHeader(context, 'المظهر'),
          _buildSkinSelector(context),

          const Divider(height: 32),

          // Theme mode
          _buildSectionHeader(context, 'الوضع'),
          _buildThemeSelector(context),

          const Divider(height: 32),

          // RTL toggle
          _buildSectionHeader(context, 'اللغة'),
          _buildRtlToggle(context),

          const Divider(height: 32),

          // Preview section
          _buildSectionHeader(context, 'معاينة'),
          _buildPreview(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSkinSelector(BuildContext context) {
    return Column(
      children: [
        _buildSkinTile(
          context,
          skin: SocialSkin.whatsapp,
          title: 'واتساب',
          subtitle: 'تصميم مستوحى من واتساب',
          color: const Color(0xFF00A884),
          icon: Icons.chat_bubble,
        ),
        _buildSkinTile(
          context,
          skin: SocialSkin.telegram,
          title: 'تيليجرام',
          subtitle: 'تصميم مستوحى من تيليجرام',
          color: const Color(0xFF3390EC),
          icon: Icons.send,
        ),
        _buildSkinTile(
          context,
          skin: SocialSkin.instagram,
          title: 'انستجرام',
          subtitle: 'تصميم مستوحى من انستجرام',
          color: const Color(0xFFE1306C),
          icon: Icons.camera_alt,
        ),
      ],
    );
  }

  Widget _buildSkinTile(
    BuildContext context, {
    required SocialSkin skin,
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = currentSkin == skin;

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(isSelected ? 1.0 : 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isSelected ? Colors.white : color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(subtitle),
      trailing:
          isSelected
              ? Icon(Icons.check_circle, color: color)
              : const Icon(Icons.circle_outlined),
      onTap: () => onSkinChanged(skin),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            label: Text('فاتح'),
            icon: Icon(Icons.light_mode),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            label: Text('داكن'),
            icon: Icon(Icons.dark_mode),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            label: Text('النظام'),
            icon: Icon(Icons.settings_suggest),
          ),
        ],
        selected: {themeMode},
        onSelectionChanged: (selected) {
          onThemeModeChanged(selected.first);
        },
      ),
    );
  }

  Widget _buildRtlToggle(BuildContext context) {
    return SwitchListTile(
      title: const Text('اتجاه من اليمين لليسار (RTL)'),
      subtitle: Text(isRtl ? 'العربية' : 'English'),
      value: isRtl,
      onChanged: onRtlChanged,
      secondary: Icon(
        isRtl
            ? Icons.format_textdirection_r_to_l
            : Icons.format_textdirection_l_to_r,
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final theme = context.socialTransferTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color preview
          Row(
            children: [
              _buildColorBox('Primary', theme.primaryColor),
              const SizedBox(width: 8),
              _buildColorBox('Secondary', theme.secondaryColor),
              const SizedBox(width: 8),
              _buildColorBox('Success', theme.successColor),
              const SizedBox(width: 8),
              _buildColorBox('Error', theme.errorColor),
            ],
          ),

          const SizedBox(height: 16),

          // Bubble preview
          Text(
            'معاينة الفقاعات:',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 8),

          // Incoming bubble
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: theme.bubblePadding,
              decoration: BoxDecoration(
                color: theme.incomingBubbleColor,
                borderRadius: theme.incomingBubbleBorderRadius,
                boxShadow: theme.bubbleShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.description, color: theme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'document.pdf',
                        style:
                            theme.fileNameStyle ??
                            TextStyle(color: theme.textColor),
                      ),
                      Text(
                        '2.5 MB',
                        style:
                            theme.fileSizeStyle ??
                            TextStyle(color: theme.subtitleColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Outgoing bubble
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Container(
              padding: theme.bubblePadding,
              decoration: BoxDecoration(
                color: theme.outgoingBubbleColor,
                borderRadius: theme.outgoingBubbleBorderRadius,
                boxShadow: theme.bubbleShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.successColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.check_circle, color: theme.successColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'photo.jpg',
                        style:
                            theme.fileNameStyle ??
                            TextStyle(color: theme.textColor),
                      ),
                      Text(
                        'مكتمل',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.successColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Theme info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معلومات المظهر:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Skin: ${theme.skin.name}'),
                Text('Button Size: ${theme.actionButtonSize}px'),
                Text('Progress Stroke: ${theme.progressStrokeWidth}px'),
                Text('Show Speed: ${theme.showSpeed}'),
                Text('Show ETA: ${theme.showEta}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBox(String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
