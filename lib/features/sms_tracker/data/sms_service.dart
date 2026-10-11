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

  /// Read SMS from Android device inbox, or fallback to realistic mock messages
  /// if permission is denied, or running on iOS / desktop / simulator.
  static Future<List<RawSms>> readMessages({bool forceMock = false}) async {
    if (!forceMock && !kIsWeb && Platform.isAndroid) {
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

    // Default to rich demo messages for testing & iOS demonstration
    return getMockDemoMessages();
  }

  /// Realistic mock bank, UPI & credit card SMS for demonstration
  static List<RawSms> getMockDemoMessages() {
    final now = DateTime.now();
    return [
      (
        body: 'Rs.540.00 debited from A/c **4321 on 11-Oct at Swiggy. Avail bal: Rs.48,250.00',
        sender: 'HDFCBK',
        date: now.subtract(const Duration(hours: 2)),
      ),
      (
        body: 'INR 1,250.00 debited from A/c XX5678 on 11-Oct via UPI Ref 428194829102. Paid to Zomato. Avail bal Rs 14,800.00',
        sender: 'ICICIB',
        date: now.subtract(const Duration(hours: 5)),
      ),
      (
        body: 'You have successfully paid Rs.350 to Uber India via UPI. Ref No: 428194829103',
        sender: 'GPAY',
        date: now.subtract(const Duration(hours: 8)),
      ),
      (
        body: 'HDFC Bank Credit Card XX4321 — Statement due ₹14,500 by 25 Oct. Min due Rs.1,450. Avail limit: Rs.85,500',
        sender: 'HDFCCC',
        date: now.subtract(const Duration(days: 1)),
      ),
      (
        body: 'You have received Rs.1,500 from Rahul Sharma via PhonePe UPI. UPI Ref: 428194829104',
        sender: 'PHONEPE',
        date: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      (
        body: 'ICICI Bank Credit Card ending 8812 statement generated: Total due Rs.8,250 by 20-Oct. Min due Rs.825. Available limit: Rs.1,41,750',
        sender: 'ICICICRD',
        date: now.subtract(const Duration(days: 2)),
      ),
      (
        body: 'Rs 2,499.00 debited from A/c no. XX9012 on 09-Oct for Amazon Shopping. Avail bal: Rs.22,400.00',
        sender: 'AXISBK',
        date: now.subtract(const Duration(days: 2, hours: 4)),
      ),
      (
        body: 'Rs.1,200.00 debited from A/c XX1234 on 08-Oct at Apollo Pharmacy. Avail bal: Rs.70,900.00',
        sender: 'SBIINB',
        date: now.subtract(const Duration(days: 3)),
      ),
      (
        body: 'INR 649.00 debited from A/c **4321 on 07-Oct. Paid to Netflix Entertainment. Avail bal Rs.47,601.00',
        sender: 'HDFCBK',
        date: now.subtract(const Duration(days: 4)),
      ),
      (
        body: 'Rs.65,000.00 credited to A/c XX1234 on 01-Oct by SALARY TRANSFER. Avail bal: Rs.72,100.00',
        sender: 'SBIINB',
        date: now.subtract(const Duration(days: 10)),
      ),
    ];
  }
}
