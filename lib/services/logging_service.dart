import 'dart:io';
import 'package:dart_seq/dart_seq.dart';
import 'package:dart_seq_http_client/dart_seq_http_client.dart';

class LoggingService {
  static final logger = SeqHttpLogger.create(
    host: '',  // Cleared for security
    globalContext: {
      'Environment': {'Project': 'Kaching'},
    },
  );

  static Future<bool> logInformation(String message) async {
    try {
      await logger.log(
        SeqLogLevel.information,
        message,
        null,
        {'Dart': Platform.version, 'Name': ''},  // Cleared for security
      );
      await logger.flush();
      return true;
    } catch (e) {
      return false;
    }
  }
}