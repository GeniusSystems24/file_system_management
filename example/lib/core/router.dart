import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/downloads/parallel_downloads_screen.dart';
import '../features/downloads/batch_downloads_screen.dart';
import '../features/downloads/background_downloads_screen.dart';
import '../features/queue/queue_management_screen.dart';
import '../features/widgets/message_widgets_screen.dart';
import '../features/themes/social_themes_screen.dart';
import '../features/handlers/custom_handlers_screen.dart';
import '../features/storage/shared_storage_screen.dart';
import '../features/cache/cache_management_screen.dart';
import '../features/permissions/permissions_screen.dart';
import '../features/rtl/rtl_support_screen.dart';

/// App router configuration using go_router.
final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),

    // Downloads
    GoRoute(
      path: '/parallel-downloads',
      name: 'parallel-downloads',
      builder: (context, state) => const ParallelDownloadsScreen(),
    ),
    GoRoute(
      path: '/batch-downloads',
      name: 'batch-downloads',
      builder: (context, state) => const BatchDownloadsScreen(),
    ),
    GoRoute(
      path: '/background-downloads',
      name: 'background-downloads',
      builder: (context, state) => const BackgroundDownloadsScreen(),
    ),

    // Queue
    GoRoute(
      path: '/queue-management',
      name: 'queue-management',
      builder: (context, state) => const QueueManagementScreen(),
    ),

    // Widgets
    GoRoute(
      path: '/message-widgets',
      name: 'message-widgets',
      builder: (context, state) => const MessageWidgetsScreen(),
    ),

    // Themes
    GoRoute(
      path: '/social-themes',
      name: 'social-themes',
      builder: (context, state) => const SocialThemesScreen(),
    ),

    // Handlers
    GoRoute(
      path: '/custom-handlers',
      name: 'custom-handlers',
      builder: (context, state) => const CustomHandlersScreen(),
    ),

    // Storage
    GoRoute(
      path: '/shared-storage',
      name: 'shared-storage',
      builder: (context, state) => const SharedStorageScreen(),
    ),

    // Cache
    GoRoute(
      path: '/cache-management',
      name: 'cache-management',
      builder: (context, state) => const CacheManagementScreen(),
    ),

    // Permissions
    GoRoute(
      path: '/permissions',
      name: 'permissions',
      builder: (context, state) => const PermissionsScreen(),
    ),

    // RTL
    GoRoute(
      path: '/rtl-support',
      name: 'rtl-support',
      builder: (context, state) => const RtlSupportScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(
      child: Text('Page not found: ${state.uri}'),
    ),
  ),
);
