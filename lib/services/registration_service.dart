import 'package:unique_identifier/unique_identifier.dart';
import 'package:http/http.dart' as http;
import 'package:kaching/services/secure_storage_service.dart';

class RegistrationService {
  static Future<String> getDeviceID() async {
    String? identifier = await UniqueIdentifier.serial; // MAC
    identifier ??= "Unknown";
    return identifier;
  }


}