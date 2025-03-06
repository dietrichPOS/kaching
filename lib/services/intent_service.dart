import 'package:flutter/services.dart';

class IntentService {
  static const platform = MethodChannel('com.pos.kaching/channel');

  static Future<String> launchAddpayIntent(String parameters) async {
    try {
      final result =
          await platform.invokeMethod('launchAddpayIntent', parameters);
      return result;
      //}
    } on PlatformException catch (e) {
      return "Failed to launch custom intent: '${e.message}'.";
      //}
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
}
