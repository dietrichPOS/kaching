import 'package:http/http.dart' as http;
import 'package:kaching/models/paymentResponse.dart';
import 'package:kaching/services/logging_service.dart';
import 'dart:convert';

import 'package:kaching/services/registration_service.dart';
import 'package:kaching/services/secure_storage_service.dart';

class WebService {
  static Future<http.Response> fetchOrders(String userNumber) async {
    String ip = await SecureStorageService.fetchIpOrUrl();
    String port = await SecureStorageService.fetchPort();
    String apiKey = await SecureStorageService.fetchToken();

    //Workaround for myhalo.co.za not being https, to be removed POST testing
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
      String orderNumber, String userNumber, String txData) async {
    String ip = await SecureStorageService.fetchIpOrUrl();
    String port = await SecureStorageService.fetchPort();
    String apiKey = await SecureStorageService.fetchToken();

    String urlHeader = 'http';
    if (ip.contains('dev.myhalo.co.za')) urlHeader = 'http';

    PaymentResponseDto paymentResponseDto =
        PaymentResponseDto.fromJson(jsonDecode(txData));
    String dt =
        '${paymentResponseDto.transDate.toString()} ${paymentResponseDto.transTime.toString()}';

    int amountInt = int.parse(paymentResponseDto.amt.toString());
    double amountDouble = amountInt / 100;

    String json = jsonEncode(<String, String>{
      'DateTime': dt,
      'UserNo': userNumber,
      'OrderNo': orderNumber,
      'Total': paymentResponseDto.amt.toString(),
      'Tipp': '0', //To follow
      'ServiceCharge': '0',
      'Type': paymentResponseDto.paymentScenario.toString(),
      'CashUpNo': "0",
      'TransactionID': paymentResponseDto.businessOrderNo.toString(),
      'PaymentType': 'APPROVED', //DECLINED
      'CustomerName': '',
      'CardNo': paymentResponseDto.cardNo.toString(),
      'AcqRefData': '',
      'AuthID': paymentResponseDto.authCode.toString(),
      'ProcessData': '',
      'RecordNo': '',
      'RefNo': paymentResponseDto.refNo.toString(),
      'SignaturePath': '',
      'TransType': 'PAYATPUMP',
      //'ApprovedAmount': paymentResponseDto.amt.toString(),
      'ApprovedAmount': amountDouble.toString(),
      'SVCFee': '0',
      'Voided': '0'
    });

    LoggingService.logInformation(
        'Finalizing order: $orderNumber for user: $userNumber @ http://$ip:$port/api/orders/finalize/v1 -> $json');

    return http.post(
      Uri.parse('$urlHeader://$ip:$port/api/orders/finalize/v1'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'ApiKey': apiKey
      },
      body: jsonEncode(<String, String>{
        'DateTime': dt,
        'UserNo': userNumber,
        'OrderNo': orderNumber,
        'Total': paymentResponseDto.amt.toString(),
        'Tipp': '0', //To follow
        'ServiceCharge': '0',
        'Type': paymentResponseDto.paymentScenario.toString(),
        'CashUpNo': "0",
        'TransactionID': paymentResponseDto.businessOrderNo.toString(),
        'PaymentType': 'APPROVED', //DECLINED
        'CustomerName': '',
        'CardNo': paymentResponseDto.cardNo.toString(),
        'AcqRefData': '',
        'AuthID': paymentResponseDto.authCode.toString(),
        'ProcessData': '',
        'RecordNo': '',
        'RefNo': paymentResponseDto.refNo.toString(),
        'SignaturePath': '',
        'TransType': 'PAYATPUMP',
        //'ApprovedAmount': paymentResponseDto.amt.toString(),
        'ApprovedAmount': amountDouble.toString(),
        'SVCFee': '0',
        'Voided': '0'
      }),
    );
  }

  static Future<http.Response> registerDevice() async {
    String deviceID = await RegistrationService.getDeviceID(); //IMEI
    String ip = await SecureStorageService.fetchIpOrUrl();
    String port = await SecureStorageService.fetchPort();
    String apiKey = await SecureStorageService.fetchToken();

    //Workaround for myhalo.co.za not being https, to be removed POST testing
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
}
