import 'dart:io';
import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

typedef RawSms = ({String body, String sender, DateTime date});

class SmsService {
  static final Telephony _telephony = Telephony.instance;

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
      return status.isGranted;
    }
    return false;
  }

  /// Read SMS from Android device inbox.
  /// Returns empty list if permission not granted or no SMS found.
  static Future<List<RawSms>> readMessages() async {
    if (!kIsWeb && Platform.isAndroid) {
      final granted = await hasPermission();
      if (granted) {
        try {
          final messages = await _telephony.getInboxSms(
            columns: [
              SmsColumn.BODY,
              SmsColumn.ADDRESS,
              SmsColumn.DATE,
            ],
            sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
          );

          if (messages.isNotEmpty) {
            return messages.map((m) {
              final date = m.date != null
                  ? DateTime.fromMillisecondsSinceEpoch(m.date!)
                  : DateTime.now();
              return (
                body: m.body ?? '',
                sender: m.address ?? 'Bank',
                date: date,
              );
            }).toList();
          }
        } catch (e) {
          debugPrint('Error reading device SMS: $e');
        }
      }
    }

    return [];
  }
}
