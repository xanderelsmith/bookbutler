import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'services/home_widget_service.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/main_page.dart';
import 'package:project_thera_client/project_thera_client.dart';

///TODO: change back to url
var newVariable = '10.165.83.151';
late Client client;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  client =
      Client(
          'http://$newVariable:8080/',
          connectionTimeout: const Duration(seconds: 10),
          streamingConnectionTimeout: const Duration(seconds: 5),
          disconnectStreamsOnLostInternetConnection: true,
        )
        ..connectivityMonitor = FlutterConnectivityMonitor()
        ..authSessionManager = FlutterAuthSessionManager();

  // Note: client.auth.initialize() is not needed - the session manager handles this automatically
  // Initialize pdfrx library
  await pdfrxFlutterInitialize(dismissPdfiumWasmWarnings: true);

  // Initialize notification service (local notifications)
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize push notification service (FCM)
  final pushNotificationService = PushNotificationService();
  await pushNotificationService.initialize();

  // Initialize home widget service
  final homeWidgetService = HomeWidgetService();
  await homeWidgetService.initialize();

  // Send first launch notification if this is the first time opening the app
  await notificationService.sendFirstLaunchNotification();

  runApp(const ProviderScope(child: FlutterButlerApp()));
}

class FlutterButlerApp extends StatelessWidget {
  const FlutterButlerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Flutter Butler',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const MainNavigationScreen(),
    );
  }
}
