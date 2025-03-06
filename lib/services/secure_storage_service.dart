import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static Future<bool> storeToken(String token) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: "token", value: token);
    await storage.write(key: "tempToken", value: '');
    return true;
  }

  static Future<String> fetchToken() async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: "token");
    if (token == null) {
      return '';
    } else {
      return token;
    }
  }

  static Future<bool> storeTempToken(String token) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: "tempToken", value: token);
    await storage.write(key: "token", value: '');
    return true;
  }

  static Future<String> fetchTempToken() async {
    const storage = FlutterSecureStorage();
    String? token = await storage.read(key: "tempToken");
    if (token == null) {
      return '';
    } else {
      return token;
    }
  }

  static Future<bool> storeBaseUrl(String ipOrUrl, String port) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: "ipOrUrl", value: ipOrUrl);
    await storage.write(key: "port", value: port);
    return true;
  }

  //This needs to be refactored POST testing
  static Future<String> fetchIpOrUrl() async {
    const storage = FlutterSecureStorage();
    String? ipOrUrl = await storage.read(key: "ipOrUrl");
    if (ipOrUrl == null || ipOrUrl == '') {
      //return '192.168.1.1';
      return 'dev.myhalo.co.za';
    } else {
      return ipOrUrl;
    }
  }

  static Future<String> fetchPort() async {
    const storage = FlutterSecureStorage();
    String? port = await storage.read(key: "port");
    if (port == null || port == '') {
      return '1895';
    } else {
      return port;
    }
  }
}
