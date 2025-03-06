import 'dart:convert';
import 'dart:ffi';

import 'package:device_info/device_info.dart';
import 'package:kaching/services/logging_service.dart';
import 'package:kaching/services/secure_storage_service.dart';
import 'package:unique_identifier/unique_identifier.dart';

class RegistrationService {
  static Future<String> getDeviceID() async {
    String? identifier = await UniqueIdentifier.serial; //MAC
    identifier ??= "Unknown"; 
    return identifier;
  }

  //This method may need to be re-instated depending on the final implementation (post testing)
  // static Future<http.Response> registerDevice() {
  //   return http.post(
  //     Uri.parse('http://dev.myhalo.co.za:1895/api/orders/register/v1'),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json; charset=UTF-8',
  //     },
  //     body: jsonEncode(<String, String>{
  //       'Apikey': '',
  //       'IMEI': '12345'
  //     }),
  //   );
  // }
}
