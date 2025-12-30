import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

/// Demonstrates RTL (Right-to-Left) support.
///
/// Full right-to-left language support for Arabic, Hebrew, Persian, etc.
class RtlSupportScreen extends StatefulWidget {
  const RtlSupportScreen({super.key});

  @override
  State<RtlSupportScreen> createState() => _RtlSupportScreenState();
}

class _RtlSupportScreenState extends State<RtlSupportScreen> {
  bool _isRtl = true;
  double _progress = 0.65;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RTL Support'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _isRtl = !_isRtl),
            icon: Icon(
              _isRtl
                  ? Icons.format_textdirection_r_to_l
                  : Icons.format_textdirection_l_to_r,
            ),
            label: Text(_isRtl ? 'RTL' : 'LTR'),
          ),
        ],
      ),
      body: Directionality(
        textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Info Card
            _buildInfoCard(theme),
            const SizedBox(height: 16),

            // Direction Toggle
            _buildDirectionCard(theme),
            const SizedBox(height: 16),

            // Message Bubbles Demo
            _buildMessageBubblesDemo(theme),
            const SizedBox(height: 16),

            // Progress Demo
            _buildProgressDemo(theme),
            const SizedBox(height: 16),

            // File List Demo
            _buildFileListDemo(theme),
            const SizedBox(height: 16),

            // Arabic UI Demo
            _buildArabicUIDemo(theme),
          ],
        ),
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
                Icon(
                  Icons.format_textdirection_r_to_l,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'RTL Language Support',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'All widgets automatically adapt to right-to-left languages. '
              'Perfect for Arabic, Hebrew, Persian, Urdu, and other RTL languages.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: const [
                Chip(label: Text('العربية')),
                Chip(label: Text('עברית')),
                Chip(label: Text('فارسی')),
                Chip(label: Text('اردو')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectionCard(ThemeData theme) {
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isRtl
                  ? Icons.format_textdirection_r_to_l
                  : Icons.format_textdirection_l_to_r,
              size: 40,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isRtl
                        ? 'الاتجاه من اليمين لليسار'
                        : 'Direction: Left to Right',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isRtl
                        ? 'جميع العناصر تتكيف تلقائياً'
                        : 'All elements adapt automatically',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer.withOpacity(
                        0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isRtl,
              onChanged: (value) => setState(() => _isRtl = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubblesDemo(ThemeData theme) {
    final whatsappTheme = SocialTransferThemeData.whatsapp();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isRtl ? 'فقاعات الرسائل' : 'Message Bubbles',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Outgoing message
            Align(
              alignment: _isRtl ? Alignment.centerLeft : Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  color: whatsappTheme.outgoingBubbleColor,
                  borderRadius:
                      _isRtl
                          ? whatsappTheme.incomingBubbleBorderRadius
                          : whatsappTheme.outgoingBubbleBorderRadius,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRtl
                          ? 'هذه رسالة صادرة مع ملف مرفق'
                          : 'This is an outgoing message with attachment',
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.black12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Incoming message
            Align(
              alignment: _isRtl ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                constraints: const BoxConstraints(maxWidth: 280),
                decoration: BoxDecoration(
                  color: whatsappTheme.incomingBubbleColor,
                  borderRadius:
                      _isRtl
                          ? whatsappTheme.outgoingBubbleBorderRadius
                          : whatsappTheme.incomingBubbleBorderRadius,
                ),
                child: Text(
                  _isRtl ? 'هذه رسالة واردة' : 'This is an incoming message',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDemo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isRtl ? 'مؤشر التقدم' : 'Progress Indicator',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_isRtl ? 'جاري التحميل...' : 'Downloading...'),
                          Text('${(_progress * 100).toInt()}%'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isRtl
                                ? '٦.٥ ميجابايت / ١٠ ميجابايت'
                                : '6.5 MB / 10 MB',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            _isRtl ? '٢.٥ ميجابايت/ث' : '2.5 MB/s',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Slider(
              value: _progress,
              onChanged: (value) => setState(() => _progress = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileListDemo(ThemeData theme) {
    final files =
        _isRtl
            ? [
              ('صورة_العطلة.jpg', '٢.٥ ميجابايت', Icons.image, Colors.blue),
              (
                'فيديو_الحفلة.mp4',
                '٢٥ ميجابايت',
                Icons.videocam,
                Colors.purple,
              ),
              (
                'تقرير_المشروع.pdf',
                '١.٢ ميجابايت',
                Icons.description,
                Colors.red,
              ),
            ]
            : [
              ('vacation_photo.jpg', '2.5 MB', Icons.image, Colors.blue),
              ('party_video.mp4', '25 MB', Icons.videocam, Colors.purple),
              ('project_report.pdf', '1.2 MB', Icons.description, Colors.red),
            ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isRtl ? 'قائمة الملفات' : 'File List',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...files.map(
              (file) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: file.$4.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(file.$3, color: file.$4),
                ),
                title: Text(file.$1),
                subtitle: Text(file.$2),
                trailing: Icon(
                  Icons.download,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArabicUIDemo(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isRtl ? 'واجهة عربية كاملة' : 'Full Arabic UI',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            if (_isRtl) ...[
              // Arabic status badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusBadge(
                    'جاري التحميل',
                    Colors.blue,
                    Icons.downloading,
                  ),
                  _buildStatusBadge(
                    'متوقف مؤقتاً',
                    Colors.amber,
                    Icons.pause_circle,
                  ),
                  _buildStatusBadge('مكتمل', Colors.green, Icons.check_circle),
                  _buildStatusBadge('فشل', Colors.red, Icons.error),
                ],
              ),
              const SizedBox(height: 16),

              // Arabic action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('تحميل'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.cancel),
                      label: const Text('إلغاء'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // English status badges
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusBadge(
                    'Downloading',
                    Colors.blue,
                    Icons.downloading,
                  ),
                  _buildStatusBadge('Paused', Colors.amber, Icons.pause_circle),
                  _buildStatusBadge(
                    'Completed',
                    Colors.green,
                    Icons.check_circle,
                  ),
                  _buildStatusBadge('Failed', Colors.red, Icons.error),
                ],
              ),
              const SizedBox(height: 16),

              // English action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
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
}
