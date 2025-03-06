// To parse this JSON data, do
//
//     final ordersDto = ordersDtoFromJson(jsonString);

import 'dart:convert';

OrdersDto ordersDtoFromJson(String str) => OrdersDto.fromJson(json.decode(str));

String ordersDtoToJson(OrdersDto data) => json.encode(data.toJson());

class OrdersDto {
  Data? data;
  bool? success;
  dynamic message;

  OrdersDto({
    this.data,
    this.success,
    this.message,
  });

  factory OrdersDto.fromJson(Map<String, dynamic> json) => OrdersDto(
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
  int? userNo;
  String? userName;
  int? orderTypeNo;
  String? orderTypeName;
  List<Order>? orders;

  Data({
    this.userNo,
    this.userName,
    this.orderTypeNo,
    this.orderTypeName,
    this.orders,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        userNo: json["userNo"],
        userName: json["userName"],
        orderTypeNo: json["orderTypeNo"],
        orderTypeName: json["orderTypeName"],
        orders: json["orders"] == null
            ? []
            : List<Order>.from(json["orders"]!.map((x) => Order.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "userNo": userNo,
        "userName": userName,
        "orderTypeNo": orderTypeNo,
        "orderTypeName": orderTypeName,
        "orders": orders == null
            ? []
            : List<dynamic>.from(orders!.map((x) => x.toJson())),
      };
}

class Order {
  int? orderNo;
  String? name;
  double? total;

  Order({
    this.orderNo,
    this.name,
    this.total,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderNo: json["orderNo"],
        name: json["name"],
        total: json["total"]?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        "orderNo": orderNo,
        "name": name,
        "total": total,
      };
}
