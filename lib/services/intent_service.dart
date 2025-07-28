import 'package:flutter/services.dart';
import 'dart:convert';

import 'logging_service.dart';

class IntentService {
  static const platform = MethodChannel('com.pos.kaching/channel');
  static const APP_ID = "wzbdd525151af914b1";

  static Future<String> launchAddpayIntent(String parameters) async {
    try {
      final result =
          await platform.invokeMethod('launchAddpayIntent', parameters);
      return result;
    } on PlatformException catch (e) {
      return "Failed to launch custom intent: '${e.message}'.";
    }
  }

  static Future<String> checkAddpayResult() async {
    try {
      final result = await platform.invokeMethod('checkResult');
      return result;
    } on PlatformException catch (e) {
      return "Failed to check Addpay Result Code: '${e.message}'.";
    }
  }

  static Future<String> checkAddpayResultCode() async {
    try {
      final result = await platform.invokeMethod('checkResultCode');
      return result;
    } on PlatformException catch (e) {
      return "Failed to check Addpay Result Code: '${e.message}'.";
    }
  }

  static Future<String> checkAddpayResultMessage() async {
    try {
      final result = await platform.invokeMethod('checkResultMessage');
      return result;
    } on PlatformException catch (e) {
      return "Failed to check Addpay Result Message: '${e.message}'.";
    }
  }

  static Future<String> checkAddpayResultData() async {
    try {
      final result = await platform.invokeMethod('checkResultData');
      return result;
    } on PlatformException catch (e) {
      return "Failed to check Addpay Result Data: '${e.message}'.";
    }
  }

  static Future<String> launchSettlementIntent() async {
    try {
      final Map<String, dynamic> params = {
        'version': 'A01',
        'appId': APP_ID,
        'transType': 'SETTLEMENT'
      };
      final result = await platform.invokeMethod('launchSettlementIntent', jsonEncode(params));
      return result;
    } catch (e) {
      LoggingService.logInformation('Error launching settlement intent: $e');
      rethrow;
    }
  }

  static Future<String> checkSettlementResult() async {
    try {
      final result = await platform.invokeMethod('checkSettlementResult');
      return result;
    } catch (e) {
      LoggingService.logInformation('Error checking settlement result: $e');
      rethrow;
    }
  }

  static Future<String> checkSettlementResultCode() async {
    try {
      final result = await platform.invokeMethod('checkSettlementResultCode');
      return result;
    } on PlatformException catch (e) {
      return "Failed to check Addpay Result Code: '${e.message}'.";
    }
  }

  static Future<String> checkSettlementResultMessage() async {
    try {
      final result = await platform.invokeMethod('checkSettlementResultMessage');
      return result;
    } on PlatformException catch (e) {
      return "Failed to check Addpay Result Message: '${e.message}'.";
    }
  }

  static Future<String> checkSettlementResultData() async {
    try {
      final result = await platform.invokeMethod('checkSettlementResultData');
      return result;
    } catch (e) {
      LoggingService.logInformation('Error checking settlement result data: $e');
      rethrow;
    }
  }

  static Future<String> getTransactions({
    required String merchantNo,
    required String terminalSn,
    required String currency,
    required String timeStart,
    required String timeEnd,
    String? payMethodId,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'merchantNo': merchantNo,
        'terminalSn': terminalSn,
        'currency': currency,
        'timeStart': timeStart,
        'timeEnd': timeEnd,
        'appId': APP_ID,
        if (payMethodId != null) 'payMethodId': payMethodId,
      };
      final result = await platform.invokeMethod('getTransactions', params);
      return result;
    } catch (e) {
      LoggingService.logInformation('Error getting transactions: $e');
      rethrow;
    }
  }
}
