import 'package:workmanager/workmanager.dart';
import '../../features/sms_tracker/data/sms_parser_service.dart';
import '../../features/sms_tracker/data/sms_service.dart';
import 'notification_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Task name constants  (keep in sync with registration in main.dart)
// ──────────────────────────────────────────────────────────────────────────────
const kSmsSyncTask = 'kanakkufi.sms_sync';
const kDailySummaryTask = 'kanakkufi.daily_summary';

// ──────────────────────────────────────────────────────────────────────────────
// Top-level callback — MUST be a top-level function (not a class method)
// WorkManager runs this in a separate Dart isolate
// ──────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    switch (taskName) {
      case kSmsSyncTask:
        await _runSmsSync(inputData);
        break;
      case kDailySummaryTask:
        await _runDailySummary(inputData);
        break;
    }
    return true;
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// SMS Sync Task  (reads new SMS, parses, saves to local storage)
// ──────────────────────────────────────────────────────────────────────────────
Future<void> _runSmsSync(Map<String, dynamic>? inputData) async {
  try {
    final rawMessages = await SmsService.readMessages();
    final parsed = SmsParserService.parseAll(rawMessages);
    if (parsed.isNotEmpty) {
      await NotificationService.init();
      final latest = parsed.first;
      if (DateTime.now().difference(latest.date).inHours <= 3) {
        await NotificationService.showTransactionAlert(
          amount: latest.amount,
          isDebit: latest.isDebit,
          source: latest.bankName ?? (latest.isUpi ? 'UPI' : 'Bank'),
          merchant: latest.merchant,
        );
      }
    }
  } catch (e) {
    // Ignore background exceptions
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Daily Summary Task  (fired by WorkManager around 10 PM)
// ──────────────────────────────────────────────────────────────────────────────
Future<void> _runDailySummary(Map<String, dynamic>? inputData) async {
  await NotificationService.init();

  // Extract pre-computed summary values passed as input data
  final totalSpent = (inputData?['totalSpent'] as num?)?.toDouble() ?? 0.0;
  final totalReceived =
      (inputData?['totalReceived'] as num?)?.toDouble() ?? 0.0;
  final topCategory =
      (inputData?['topCategory'] as String?) ?? 'General';
  final creditCardAlert = inputData?['creditCardAlert'] as String?;
  final txCount = (inputData?['txCount'] as num?)?.toInt() ?? 0;

  await NotificationService.showDailySummary(
    totalSpent: totalSpent,
    totalReceived: totalReceived,
    topCategory: topCategory,
    creditCardAlert: creditCardAlert,
    transactionCount: txCount,
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Registration helper — call once from main()
// ──────────────────────────────────────────────────────────────────────────────
class BackgroundTaskManager {
  BackgroundTaskManager._();

  static Future<void> init() async {
    await Workmanager().initialize(
      workmanagerCallbackDispatcher,
    );
  }

  /// Register a periodic SMS sync every 3 hours.
  /// WorkManager enforces a minimum of 15 min; 3 hrs is well above that.
  static Future<void> registerSmsSyncTask() async {
    await Workmanager().registerPeriodicTask(
      kSmsSyncTask,
      kSmsSyncTask,
      frequency: const Duration(hours: 3),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }

  /// Register the daily summary task.
  /// This is a ONE-SHOT task that should be re-registered daily.
  /// `flutter_local_notifications` handles the exact 10 PM schedule natively —
  /// this task is a backup in case the notification is missed.
  static Future<void> registerDailySummaryTask({
    double totalSpent = 0,
    double totalReceived = 0,
    String topCategory = 'General',
    String? creditCardAlert,
    int txCount = 0,
  }) async {
    await Workmanager().registerOneOffTask(
      kDailySummaryTask,
      kDailySummaryTask,
      inputData: {
        'totalSpent': totalSpent,
        'totalReceived': totalReceived,
        'topCategory': topCategory,
        if (creditCardAlert != null) 'creditCardAlert': creditCardAlert,
        'txCount': txCount,
      },
      // Schedule for ~22:00 IST today
      initialDelay: _durationUntil(hour: 22, minute: 0),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }

  static Duration _durationUntil({required int hour, required int minute}) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target.difference(now);
  }

  /// Cancel all background tasks (call on logout)
  static Future<void> cancelAll() => Workmanager().cancelAll();
}
