import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

import 'screens/cache_demo_screen.dart';
import 'screens/chat_demo_screen.dart';
import 'screens/clean_arch_demo_screen.dart';
import 'screens/downloads_demo_screen.dart';
import 'screens/handlers_demo_screen.dart';
import 'screens/message_widgets_demo_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/theme_demo_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize directories
  await AppDirectory.init();

  // Initialize the transfer controller
  await TransferController.instance.initialize();

  runApp(const ExampleApp());
}

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  SocialSkin _currentSkin = SocialSkin.whatsapp;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isRtl = true;

  void _onSkinChanged(SocialSkin skin) {
    setState(() => _currentSkin = skin);
  }

  void _onThemeModeChanged(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void _onRtlChanged(bool isRtl) {
    setState(() => _isRtl = isRtl);
  }

  SocialTransferThemeData _getThemeData({bool? isDark}) {
    isDark ??= _themeMode == ThemeMode.dark;

    return switch (_currentSkin) {
      SocialSkin.whatsapp => SocialTransferThemeData.whatsapp(isDark: isDark),
      SocialSkin.telegram => SocialTransferThemeData.telegram(isDark: isDark),
      SocialSkin.instagram => SocialTransferThemeData.instagram(isDark: isDark),
      SocialSkin.custom => SocialTransferThemeData.of(context),
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File System Management Demo',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _getSeedColor()),
        useMaterial3: true,
        extensions: [_getThemeData(isDark: false)],
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _getSeedColor(),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        extensions: [_getThemeData(isDark: true)],
      ),
      locale: _isRtl ? const Locale('ar') : const Locale('en'),
      builder: (context, child) {
        return Directionality(
          textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: MainScreen(
        currentSkin: _currentSkin,
        themeMode: _themeMode,
        isRtl: _isRtl,
        onSkinChanged: _onSkinChanged,
        onThemeModeChanged: _onThemeModeChanged,
        onRtlChanged: _onRtlChanged,
      ),
    );
  }

  Color _getSeedColor() {
    return switch (_currentSkin) {
      SocialSkin.whatsapp => const Color(0xFF00A884),
      SocialSkin.telegram => const Color(0xFF3390EC),
      SocialSkin.instagram => const Color(0xFFE1306C),
      SocialSkin.custom => Colors.blue,
    };
  }
}

class MainScreen extends StatefulWidget {
  final SocialSkin currentSkin;
  final ThemeMode themeMode;
  final bool isRtl;
  final ValueChanged<SocialSkin> onSkinChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<bool> onRtlChanged;

  const MainScreen({
    super.key,
    required this.currentSkin,
    required this.themeMode,
    required this.isRtl,
    required this.onSkinChanged,
    required this.onThemeModeChanged,
    required this.onRtlChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File System Management'),
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              widget.onThemeModeChanged(
                widget.themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('التحميلات والرفع', Icons.cloud_download),
          _buildFeatureCard(
            title: 'تحميلات حقيقية',
            subtitle: 'تحميل ملفات حقيقية (صور، فيديو، صوت، مستندات)',
            icon: Icons.download,
            color: Colors.blue,
            onTap: () => _navigateTo(const DownloadsDemoScreen()),
          ),
          _buildFeatureCard(
            title: 'Clean Architecture',
            subtitle: 'استخدام TransferController مع البنية النظيفة',
            icon: Icons.architecture,
            color: Colors.purple,
            onTap: () => _navigateTo(const CleanArchDemoScreen()),
          ),
          _buildFeatureCard(
            title: 'Handlers مخصصة',
            subtitle: 'تنفيذ UploadHandler و DownloadHandler',
            icon: Icons.code,
            color: Colors.teal,
            onTap: () => _navigateTo(const HandlersDemoScreen()),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('واجهات المستخدم', Icons.widgets),
          _buildFeatureCard(
            title: 'ويدجت الرسائل',
            subtitle: 'ImageMessage, VideoMessage, AudioMessage, FileMessage',
            icon: Icons.chat_bubble,
            color: Colors.green,
            onTap: () => _navigateTo(
              MessageWidgetsDemoScreen(currentSkin: widget.currentSkin),
            ),
          ),
          _buildFeatureCard(
            title: 'محادثة تجريبية',
            subtitle: 'محاكاة محادثة مع تحميل ورفع الملفات',
            icon: Icons.forum,
            color: Colors.indigo,
            onTap: () => _navigateTo(
              ChatDemoScreen(currentSkin: widget.currentSkin),
            ),
          ),
          _buildFeatureCard(
            title: 'تخصيص الثيمات',
            subtitle: 'WhatsApp, Telegram, Instagram, Custom',
            icon: Icons.palette,
            color: Colors.orange,
            onTap: () => _navigateTo(const ThemeDemoScreen()),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('التخزين والإعدادات', Icons.storage),
          _buildFeatureCard(
            title: 'إدارة الكاش',
            subtitle: 'عرض وحذف الملفات المخزنة',
            icon: Icons.folder,
            color: Colors.brown,
            onTap: () => _navigateTo(const CacheDemoScreen()),
          ),
          _buildFeatureCard(
            title: 'الإعدادات',
            subtitle: 'تخصيص الستايل واللغة والوضع',
            icon: Icons.settings,
            color: Colors.grey,
            onTap: () => _navigateTo(
              SettingsScreen(
                currentSkin: widget.currentSkin,
                themeMode: widget.themeMode,
                isRtl: widget.isRtl,
                onSkinChanged: widget.onSkinChanged,
                onThemeModeChanged: widget.onThemeModeChanged,
                onRtlChanged: widget.onRtlChanged,
              ),
            ),
          ),

          const SizedBox(height: 32),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'عن المكتبة',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'file_system_management هي مكتبة Flutter شاملة لإدارة عمليات '
              'التحميل والرفع مع دعم Clean Architecture والـ Handlers المخصصة '
              'والـ Widgets الجاهزة للمحادثات.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildBadge('Clean Architecture'),
                _buildBadge('Custom Handlers'),
                _buildBadge('Message Widgets'),
                _buildBadge('Theming'),
                _buildBadge('Cache Management'),
                _buildBadge('Progress Tracking'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }
}
