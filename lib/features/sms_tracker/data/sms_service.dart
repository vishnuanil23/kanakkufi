import 'dart:io';
import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/notification_service.dart';
import 'sms_parser_service.dart';
import 'sms_repository.dart';

typedef RawSms = ({String body, String sender, DateTime date});
typedef TransactionCallback = void Function(ParsedTransaction transaction);

/// Top-level background callback for incoming SMS (required by Android background isolate)
@pragma('vm:entry-point')
void backgroundSmsCallback(SmsMessage message) async {
  try {
    final body = message.body ?? '';
    final sender = message.address ?? 'Bank';
    final date = message.date != null
        ? DateTime.fromMillisecondsSinceEpoch(message.date!)
        : DateTime.now();

    if (date.isBefore(SmsParserService.smsTrackingStartDate)) return;

    final parsed = SmsParserService.parse(
      body: body,
      sender: sender,
      date: date,
    );

    if (parsed != null) {
      await NotificationService.init();
      await NotificationService.showTransactionAlert(
        amount: parsed.amount,
        isDebit: parsed.isDebit,
        source: parsed.bankName ?? (parsed.isUpi ? 'UPI' : 'Bank'),
        merchant: parsed.merchant ?? parsed.resolveCategory(),
      );
    }
  } catch (e) {
    debugPrint('Error in background SMS callback: $e');
  }
}

class SmsService {
  static final Telephony _telephony = Telephony.instance;
  static bool _isListening = false;
  static final List<TransactionCallback> _listeners = [];

  /// Check if SMS permission is granted
  static Future<bool> hasPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      final status = await Permission.sms.status;
      return status.isGranted;
    }
    return false;
  }

  /// Request SMS permission from user
  static Future<bool> requestPermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      final status = await Permission.sms.request();
      if (status.isGranted) {
        await startListening();
      }
      return status.isGranted;
    }
    return false;
  }

  /// Register a listener for real-time transactions
  static void addListener(TransactionCallback callback) {
    if (!_listeners.contains(callback)) {
      _listeners.add(callback);
    }
  }

  /// Remove a registered listener
  static void removeListener(TransactionCallback callback) {
    _listeners.remove(callback);
  }

  /// Start listening for incoming SMS messages on Android
  static Future<void> startListening() async {
    if (_isListening || kIsWeb || !Platform.isAndroid) return;

    final granted = await hasPermission();
    if (!granted) return;

    try {
      _telephony.listenIncomingSms(
        onNewMessage: _handleIncomingSms,
        onBackgroundMessage: backgroundSmsCallback,
      );
      _isListening = true;
      debugPrint('Real-time SMS listener active');
    } catch (e) {
      debugPrint('Error starting SMS listener: $e');
    }
  }

  static void _handleIncomingSms(SmsMessage m) async {
    final body = m.body ?? '';
    final sender = m.address ?? 'Bank';
    final date = m.date != null
        ? DateTime.fromMillisecondsSinceEpoch(m.date!)
        : DateTime.now();

    if (date.isBefore(SmsParserService.smsTrackingStartDate)) return;

    final parsed = SmsParserService.parse(
      body: body,
      sender: sender,
      date: date,
    );

    if (parsed != null) {
      // Auto-add immediately to Supabase
      await SmsRepository.instance.autoAddTransaction(parsed);

      // Notify any active UI listeners
      for (final listener in List<TransactionCallback>.from(_listeners)) {
        try {
          listener(parsed);
        } catch (e) {
          debugPrint('Error notifying transaction listener: $e');
        }
      }
    }
  }

  /// Read SMS from Android device inbox from specified start date (default: 1 Oct onwards).
  /// Returns empty list if permission not granted or no SMS found.
  static Future<List<RawSms>> readMessages({DateTime? sinceDate}) async {
    if (!kIsWeb && Platform.isAndroid) {
      final granted = await hasPermission();
      if (granted) {
        try {
          final cutoff = sinceDate ?? SmsParserService.smsTrackingStartDate;
          final messages = await _telephony.getInboxSms(
            columns: [
              SmsColumn.BODY,
              SmsColumn.ADDRESS,
              SmsColumn.DATE,
            ],
            sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
          );

          if (messages.isNotEmpty) {
            final filtered = <RawSms>[];
            for (final m in messages) {
              final date = m.date != null
                  ? DateTime.fromMillisecondsSinceEpoch(m.date!)
                  : DateTime.now();

              // Only take SMS from 1 Oct to till date
              if (!date.isBefore(cutoff)) {
                filtered.add((
                  body: m.body ?? '',
                  sender: m.address ?? 'Bank',
                  date: date,
                ));
              }
            }
            return filtered;
          }
        } catch (e) {
          debugPrint('Error reading device SMS: $e');
        }
      }
    }

    return [];
  }
}
