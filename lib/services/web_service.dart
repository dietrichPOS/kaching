import 'dart:ffi';

import 'package:http/http.dart' as http;
import 'package:kaching/services/logging_service.dart';
import 'dart:convert';
import 'package:kaching/services/registration_service.dart';
import 'package:kaching/services/secure_storage_service.dart';
import '../models/products.dart';
import '../models/paymentResponse.dart';

class WebService {
  static Future<http.Response> fetchOrders(String userNumber) async {
    String ip = await SecureStorageService.fetchIpOrUrl();
    String port = await SecureStorageService.fetchPort();
    String apiKey = await SecureStorageService.fetchToken();

    String urlHeader = 'http';
    if (ip.contains('dev.myhalo.co.za')) urlHeader = 'http';

    LoggingService.logInformation(
        'Fetching orders for user: $userNumber @ http://$ip:$port/api/orders/user/v1');
    LoggingService.logInformation('ApiKey: $apiKey');
    return http.post(
      Uri.parse('$urlHeader://$ip:$port/api/orders/user/v1'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'ApiKey': apiKey
      },
      body: jsonEncode(<String, String>{'UserNo': userNumber}),
    );
  }

  static Future<http.Response> finalizeOrder(
      String orderNumber,
      String userNumber,
      String card,
      String batchNo,
      double ? cash,
      int? mileage,
      String? regNo,
      String txData, {
        List<Map<String, dynamic>>? forecourtData,
      }) async {
    String ip = await SecureStorageService.fetchIpOrUrl();
    String port = await SecureStorageService.fetchPort();
    String apiKey = await SecureStorageService.fetchToken();

    String urlHeader = 'http';
    if (ip.contains('dev.myhalo.co.za')) urlHeader = 'http';

    PaymentResponseDto paymentResponseDto = PaymentResponseDto.fromJson(jsonDecode(txData));
    String dt = '${paymentResponseDto.transDate.toString()} ${paymentResponseDto.transTime.toString()}';

    int amountInt = int.parse(paymentResponseDto.amt.toString());
    double amountDouble = amountInt / 100;

    // Validate that the total forecourtData amount matches the order amount
    if (forecourtData != null && forecourtData.isNotEmpty) {
      int totalForecourtAmount = forecourtData.fold(0, (sum, item) => sum + int.parse(item['amount'] ?? '0'));
      if (totalForecourtAmount != amountInt) {
        throw Exception('Total forecourtData amount ($totalForecourtAmount) does not match order amount ($amountInt)');
      }
    }

    Map<String, dynamic> payload = {
      'DateTime': dt,
      'UserNo': userNumber,
      'OrderNo': orderNumber,
      'Total': amountDouble,
      'Tipp': '0',
      'ServiceCharge': '0',
      'Type': card,
      'CashUpNo': "0",
      'TransactionID': paymentResponseDto.businessOrderNo.toString(),
      'PaymentType': 'APPROVED',
      'CustomerName': '',
      'CardNo': paymentResponseDto.cardNo.toString(),
      'AcqRefData': '',
      'AuthID': paymentResponseDto.authCode.toString(),
      'ProcessData': '',
      'RecordNo': '',
      'RefNo': paymentResponseDto.refNo.toString(),
      'SignaturePath': batchNo,
      'Mileage': mileage ?? 0,
      'RegNo': regNo ?? "",
      'CashAmount': cash ?? 0,
      'TransType': 'PAYATPUMP',
      'ApprovedAmount': amountDouble.toString(),
      'forecourtData': forecourtData ?? [],
      'SVCFee': '0',
      'Voided': '0'
    };

    String json = jsonEncode(payload);

    LoggingService.logInformation(
        'Finalizing order: $orderNumber for user: $userNumber @ http://$ip:$port/api/orders/finalize/v1 -> $json');

    final response = await http.post(
      Uri.parse('$urlHeader://$ip:$port/api/orders/finalize/v1'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'ApiKey': apiKey
      },
      body: json,
    );

    LoggingService.logInformation('Finalize API Response: ${response.body}');
    return response;
  }

  static Future<http.Response> registerDevice() async {
    String deviceID = await RegistrationService.getDeviceID();
    String ip = await SecureStorageService.fetchIpOrUrl();
    String port = await SecureStorageService.fetchPort();
    String apiKey = await SecureStorageService.fetchToken();

    String urlHeader = 'http';
    if (ip.contains('dev.myhalo.co.za')) urlHeader = 'http';

    if (apiKey == '') apiKey = await SecureStorageService.fetchTempToken();
    return http.post(
      Uri.parse('$urlHeader://$ip:$port/api/orders/register/v1'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'Apikey': apiKey, 'IMEI': deviceID}),
    );
  }

  static Future<ProductsResponse> getPumpVas() async {
    String ip = await SecureStorageService.fetchIpOrUrl();
    String port = await SecureStorageService.fetchPort();
    String apiKey = await SecureStorageService.fetchToken();

    String urlHeader = 'http';
    if (ip.contains('dev.myhalo.co.za')) urlHeader = 'http';

    LoggingService.logInformation('Fetching pump VAS via GET @ http://$ip:$port/api/orders/vas/v1');
    LoggingService.logInformation('ApiKey: $apiKey');

    final response = await http.get(
      Uri.parse('$urlHeader://$ip:$port/api/orders/vas/v1'),
      headers: <String, String>{
        'ApiKey': apiKey,
      },
    );

    LoggingService.logInformation('GetPumpVas Raw API Response: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final jsonData = json.decode(response.body);
        LoggingService.logInformation('GetPumpVas Decoded JSON: $jsonData');
        return ProductsResponse.fromJson(jsonData);
      } catch (e) {
        LoggingService.logInformation('Error parsing getPumpVas response: $e');
        throw FormatException('Failed to parse VAS response: $e');
      }
    } else {
      LoggingService.logInformation('Failed to fetch pump VAS: ${response.statusCode} ${response.body}');
      throw Exception('Failed to fetch pump VAS: ${response.statusCode}');
    }
  }
  static Future<http.Response> createPumpVas(
       orderNumber,
      int userNumber,
      double sellingPrice,
      String productCode,
      int pumpNumber,
      int lineNo,
      ) async {
    String ip = await SecureStorageService.fetchIpOrUrl();
    String port = await SecureStorageService.fetchPort();
    String apiKey = await SecureStorageService.fetchToken();

    String urlHeader = 'http';
    if (ip.contains('dev.myhalo.co.za')) urlHeader = 'http';

    Map<String, dynamic> payload = {
      'Line_No': lineNo,
      'Date_Time': DateTime.now().toIso8601String(),
      'Pump_No': pumpNumber ?? '1',
      'Trans_No': orderNumber,
      'Product_Code': productCode,
      'Unit_price': sellingPrice,
      'Attendant_No': userNumber,
      'Status': '0',
    };

    String json = jsonEncode(payload);

    // Log the exact payload being sent
    LoggingService.logInformation(
        'Sending VAS entry for lineNo: $lineNo @ http://$ip:$port/api/orders/vas/create/v1 -> $json');

    final response = await http.post(
      Uri.parse('$urlHeader://$ip:$port/api/orders/vas/create/v1'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'ApiKey': apiKey
      },
      body: json,
    );

    // Log the full response to diagnose the issue
    LoggingService.logInformation('VAS API Response for lineNo $lineNo: Status ${response.statusCode} - ${response.body}');
    return response;
  }

}