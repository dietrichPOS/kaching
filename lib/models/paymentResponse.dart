// To parse this JSON data, do
//
//     final paymentResponseDto = paymentResponseDtoFromJson(jsonString);

import 'dart:convert';

PaymentResponseDto paymentResponseDtoFromJson(String str) =>
    PaymentResponseDto.fromJson(json.decode(str));

String paymentResponseDtoToJson(PaymentResponseDto data) =>
    json.encode(data.toJson());

class PaymentResponseDto {
  String? refNo;
  String? batchNo;
  String? authCode;
  String? transTime;
  String? traceNo;
  String? amt;
  String? cardNo;
  String? businessOrderNo;
  String? paymentScenario;
  String? transDate;
  String? respCode;

  PaymentResponseDto({
    this.refNo,
    this.batchNo,
    this.authCode,
    this.transTime,
    this.traceNo,
    this.amt,
    this.cardNo,
    this.businessOrderNo,
    this.paymentScenario,
    this.transDate,
    this.respCode,
  });

  factory PaymentResponseDto.fromJson(Map<String, dynamic> json) =>
      PaymentResponseDto(
        refNo: json["refNo"],
        batchNo: json["batchNo"],
        authCode: json["authCode"],
        transTime: json["transTime"],
        traceNo: json["traceNo"],
        amt: json["amt"],
        cardNo: json["cardNo"],
        businessOrderNo: json["businessOrderNo"],
        paymentScenario: json["paymentScenario"],
        transDate: json["transDate"],
        respCode: json["respCode"],
      );

  Map<String, dynamic> toJson() => {
        "refNo": refNo,
        "batchNo": batchNo,
        "authCode": authCode,
        "transTime": transTime,
        "traceNo": traceNo,
        "amt": amt,
        "cardNo": cardNo,
        "businessOrderNo": businessOrderNo,
        "paymentScenario": paymentScenario,
        "transDate": transDate,
        "respCode": respCode,
      };
}
