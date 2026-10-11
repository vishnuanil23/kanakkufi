import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── Channel IDs ────────────────────────────────────────────────────────────
  static const String _dailyChannelId = 'kanakkufi_daily_summary';
  static const String _txChannelId = 'kanakkufi_transactions';
  static const String _alertChannelId = 'kanakkufi_alerts';

  // ── Notification IDs ───────────────────────────────────────────────────────
  static const int _dailySummaryId = 1001;
  static const int _txBaseId = 2000;
  static const int _ccBaseId = 3000;
  static const int _balBaseId = 4000;

  // ── Init ───────────────────────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // v22 API: initialize() uses named 'settings' parameter
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onTap,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  static void _onTap(NotificationResponse r) {
    debugPrint('Notification tapped: id=${r.id} payload=${r.payload}');
  }

  // ── Daily 10 PM repeating schedule ────────────────────────────────────────
  static Future<void> scheduleDailySummary() async {
    // v22: zonedSchedule() uses named parameters
    await _plugin.zonedSchedule(
      id: _dailySummaryId,
      title: '💰 Your Daily Money Summary',
      body: 'Tap to see what you spent and received today',
      scheduledDate: _nextAt(hour: 22, minute: 0),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          'Daily Summary',
          channelDescription: '10 PM daily spending & credit summary',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF6C63FF),
          enableVibration: true,
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Push the rich daily summary immediately (called from WorkManager at 10 PM)
  static Future<void> showDailySummary({
    required double totalSpent,
    required double totalReceived,
    required String topCategory,
    String? creditCardAlert,
    int transactionCount = 0,
  }) async {
    final now = DateTime.now();
    final dateStr =
        '${_wd(now.weekday)}, ${now.day} ${_mon(now.month)} ${now.year}';

    final lines = [
      '📤 Spent: ₹${_fmt(totalSpent)}   📥 Received: ₹${_fmt(totalReceived)}',
      '🏆 Top: $topCategory',
      if (transactionCount > 0) '🔄 $transactionCount transactions today',
      if (creditCardAlert != null) '💳 $creditCardAlert',
    ];

    await _plugin.show(
      id: _dailySummaryId,
      title: '💰 $dateStr',
      body: lines.first,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyChannelId,
          'Daily Summary',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF6C63FF),
          enableVibration: true,
          styleInformation: BigTextStyleInformation(
            lines.join('\n'),
            contentTitle: '💰 $dateStr',
            summaryText: transactionCount > 0
                ? '$transactionCount transactions'
                : 'Tap to review',
          ),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          subtitle: dateStr,
        ),
      ),
    );
  }

  // ── Instant transaction alert ──────────────────────────────────────────────
  static Future<void> showTransactionAlert({
    required double amount,
    required bool isDebit,
    required String source,
    String? merchant,
    int id = 0,
  }) async {
    final type = isDebit ? '📤 Debited' : '📥 Credited';
    final body = merchant != null
        ? '$source • $merchant — Tap to tag'
        : '$source — Tap to review';

    await _plugin.show(
      id: _txBaseId + id,
      title: '$type ₹${_fmt(amount)}',
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _txChannelId,
          'Transactions',
          channelDescription: 'Real-time bank & UPI transaction alerts',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: isDebit
              ? const Color(0xFFEF4444)
              : const Color(0xFF10B981),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: false,
        ),
      ),
      payload: 'transaction',
    );
  }

  // ── Credit card due alert ──────────────────────────────────────────────────
  static Future<void> showCreditCardDueAlert({
    required String bankName,
    required double amount,
    required int daysLeft,
    int id = 0,
  }) async {
    final icon = daysLeft <= 1 ? '🚨' : '⚠️';
    final when = daysLeft == 0
        ? 'due TODAY'
        : daysLeft == 1
            ? 'due TOMORROW'
            : 'due in $daysLeft days';

    await _plugin.show(
      id: _ccBaseId + id,
      title: '$icon $bankName Card — ₹${_fmt(amount)} $when',
      body: 'Tap to view your credit card details',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          'Alerts',
          channelDescription: 'Credit card & balance alerts',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFF59E0B),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: 'credit_card',
    );
  }

  // ── Low balance alert ──────────────────────────────────────────────────────
  static Future<void> showLowBalanceAlert({
    required String bankName,
    required double balance,
    int id = 0,
  }) async {
    await _plugin.show(
      id: _balBaseId + id,
      title: '🚨 Low Balance — $bankName',
      body: 'Available: ₹${_fmt(balance)} — Consider topping up',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          'Alerts',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFEF4444),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      payload: 'low_balance',
    );
  }

  // ── Cancel helpers ─────────────────────────────────────────────────────────
  static Future<void> cancelDailySummary() =>
      _plugin.cancel(id: _dailySummaryId);

  static Future<void> cancelAll() => _plugin.cancelAll();

  // ── Private helpers ────────────────────────────────────────────────────────
  static tz.TZDateTime _nextAt({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var t =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (t.isBefore(now)) t = t.add(const Duration(days: 1));
    return t;
  }

  static String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) {
      // Simple Indian comma format
      final s = v.toStringAsFixed(0);
      if (s.length > 5) {
        return '${s.substring(0, s.length - 5)},${s.substring(s.length - 5, s.length - 3)},${s.substring(s.length - 3)}';
      } else if (s.length > 3) {
        return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
      }
      return s;
    }
    return v.toStringAsFixed(0);
  }

  static String _wd(int d) =>
      ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d];

  static String _mon(int m) => [
        '',
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec',
      ][m];
}
