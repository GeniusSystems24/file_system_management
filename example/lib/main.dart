import 'package:file_system_management/file_system_management.dart';
import 'package:flutter/material.dart';

import 'screens/chat_demo_screen.dart';
import 'screens/clean_arch_demo_screen.dart';
import 'screens/settings_screen.dart';

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
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      ChatDemoScreen(currentSkin: widget.currentSkin),
      const CleanArchDemoScreen(),
      SettingsScreen(
        currentSkin: widget.currentSkin,
        themeMode: widget.themeMode,
        isRtl: widget.isRtl,
        onSkinChanged: widget.onSkinChanged,
        onThemeModeChanged: widget.onThemeModeChanged,
        onRtlChanged: widget.onRtlChanged,
      ),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'المحادثات',
          ),
          NavigationDestination(
            icon: Icon(Icons.architecture_outlined),
            selectedIcon: Icon(Icons.architecture),
            label: 'Clean Arch',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
