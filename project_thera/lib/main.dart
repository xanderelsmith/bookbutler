import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:project_thera/services/serverpod_service.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/home_widget_service.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_page.dart';
import 'package:project_thera_client/project_thera_client.dart';

late Client client;
var newVariable = '10.223.5.151';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Serverpod and restore session
  final serverpodService = ServerpodService();
  await serverpodService.initialize();
  client = serverpodService.client;

  // Restore user session from cache/server
  await serverpodService.restoreSession();

  // Note: client.auth.initialize() is not needed - the session manager handles this automatically
  // Initialize pdfrx library
  pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);

  // Initialize notification service (local notifications)
  final notificationService = NotificationService();
  notificationService.initialize();

  // Initialize push notification service (FCM)
  final pushNotificationService = PushNotificationService();
  await pushNotificationService.initialize();

  // Initialize home widget service
  final homeWidgetService = HomeWidgetService();
  homeWidgetService.initialize();

  // Send first launch notification if this is the first time opening the app
  notificationService.sendFirstLaunchNotification();

  runApp(const ProviderScope(child: FlutterButlerApp()));
}

class FlutterButlerApp extends StatelessWidget {
  const FlutterButlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Butler',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainNavigationScreen(),
    );
  }
}
