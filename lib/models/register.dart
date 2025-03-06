// To parse this JSON data, do
//
//     final registerDto = registerDtoFromJson(jsonString);

import 'dart:convert';

RegisterDto registerDtoFromJson(String str) =>
    RegisterDto.fromJson(json.decode(str));

String registerDtoToJson(RegisterDto data) => json.encode(data.toJson());

class RegisterDto {
  Data? data;
  bool? success;
  dynamic message;

  RegisterDto({
    this.data,
    this.success,
    this.message,
  });

  factory RegisterDto.fromJson(Map<String, dynamic> json) => RegisterDto(
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
        success: json["success"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "data": data?.toJson(),
        "success": success,
        "message": message,
      };
}

class Data {
  String? apiKey;
  String? status;

  Data({
    this.apiKey,
    this.status,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        apiKey: json["apiKey"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "apiKey": apiKey,
        "status": status,
      };
}
