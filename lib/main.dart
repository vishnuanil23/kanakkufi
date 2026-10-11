import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/supabase_config.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_task_manager.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await SupabaseConfig.initialize();

  // Initialise notification channels + request permissions
  await NotificationService.init();

  // Schedule the repeating 10 PM daily summary notification
  await NotificationService.scheduleDailySummary();

  // Initialise WorkManager for background SMS sync
  await BackgroundTaskManager.init();
  await BackgroundTaskManager.registerSmsSyncTask();

  runApp(
    const ProviderScope(
      child: KanakkuFiApp(),
    ),
  );
}
