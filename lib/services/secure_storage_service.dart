import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'api_token';
  static const _ipOrUrlKey = 'ip_or_url';
  static const _portKey = 'port';
  static const _deviceIDKey = 'device_id';
  static const _transactionsKey = 'transactions_list';
  static const _reprintedTransactionIdsKey = 'reprinted_transaction_ids';

  static Future<bool> storeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: "tempToken", value: '');
    return true;
  }

  static Future<String> fetchToken() async {
    String? token = await _storage.read(key: _tokenKey);
    if (token == null) {
      return '';
    } else {
      return token;
    }
  }

  static Future<bool> storeTempToken(String token) async {
    await _storage.write(key: "tempToken", value: token);
    await _storage.write(key: _tokenKey, value: '');
    return true;
  }

  static Future<String> fetchTempToken() async {
    String? token = await _storage.read(key: "tempToken");
    if (token == null) {
      return '';
    } else {
      return token;
    }
  }

  static Future<bool> storeBaseUrl(String ipOrUrl, String port) async {
    await _storage.write(key: _ipOrUrlKey, value: ipOrUrl);
    await _storage.write(key: _portKey, value: port);
    return true;
  }

  //This needs to be refactored POST testing
  static Future<String> fetchIpOrUrl() async {
    String? ipOrUrl = await _storage.read(key: _ipOrUrlKey);
    if (ipOrUrl == null || ipOrUrl == '') {
      //return '192.168.1.1';
      return 'dev.myhalo.co.za';
    } else {
      return ipOrUrl;
    }
  }

  static Future<String> fetchPort() async {
    String? port = await _storage.read(key: _portKey);
    if (port == null || port == '') {
      return '1895';
    } else {
      return port;
    }
  }

  static Future<void> deleteDeviceID() async {
    await _storage.delete(key: _deviceIDKey);
  }

  static Future<void> saveTransaction(Map<String, dynamic> transactionData) async {
    try {
      final transactions = await getTransactions();
      transactions.insert(0, transactionData);
      // Keep only the latest 150 transactions
      if (transactions.length > 150) {
        transactions.removeRange(150, transactions.length);
      }
      await _storage.write(key: _transactionsKey, value: jsonEncode(transactions));
    } catch (e) {
      // Handle potential errors, e.g., logging
      print('Error saving transaction: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getTransactions() async {
    try {
      final transactionsJson = await _storage.read(key: _transactionsKey);
      if (transactionsJson != null) {
        final List<dynamic> decodedList = jsonDecode(transactionsJson);
        return decodedList.cast<Map<String, dynamic>>().toList();
      }
    } catch (e) {
      // Handle potential errors, e.g., logging
      print('Error getting transactions: $e');
    }
    return [];
  }

  static Future<void> addReprintedTransactionId(String id) async {
    final ids = await getReprintedTransactionIds();
    if (!ids.contains(id)) {
      ids.add(id);
      await _storage.write(key: _reprintedTransactionIdsKey, value: jsonEncode(ids));
    }
  }

  static Future<List<String>> getReprintedTransactionIds() async {
    final value = await _storage.read(key: _reprintedTransactionIdsKey);
    if (value == null || value.isEmpty) return [];
    final List<dynamic> decoded = jsonDecode(value);
    return decoded.cast<String>();
  }
}
