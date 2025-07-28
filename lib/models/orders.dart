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
  Map<String, dynamic>? branch;

  Data({
    this.userNo,
    this.userName,
    this.orderTypeNo,
    this.orderTypeName,
    this.orders,
    this.branch,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    userNo: json["userNo"],
    userName: json["userName"],
    orderTypeNo: json["orderTypeNo"],
    orderTypeName: json["orderTypeName"],
    orders: json["orders"] == null
        ? []
        : List<Order>.from(json["orders"]!.map((x) => Order.fromJson(x))),
    branch: json["branch"],
  );

  Map<String, dynamic> toJson() => {
    "userNo": userNo,
    "userName": userName,
    "orderTypeNo": orderTypeNo,
    "orderTypeName": orderTypeName,
    "orders": orders == null
        ? []
        : List<dynamic>.from(orders!.map((x) => x.toJson())),
    "branch": branch,
  };
}

class Order {
  int? orderNo;
  String? name;
  double? total;
  double? volume;
  double? grade;
  String? gradeDesc;
  double? unitPrice;
  String? kaChingGrade;

  Order({
    this.orderNo,
    this.name,
    this.total,
    this.volume,
    this.grade,
    this.gradeDesc,
    this.unitPrice,
    this.kaChingGrade
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Parse the metadata field if it exists
    Map<String, dynamic>? metadata;
    if (json["metadata"] != null) {
      metadata = jsonDecode(json["metadata"]);
    }

    return Order(
      orderNo: json["orderNo"],
      name: json["name"],
      total: json["total"]?.toDouble(),
      volume: metadata != null && metadata["Volume"] != null
          ? double.tryParse(metadata["Volume"]) ?? 10.00
          : 10.00,
      grade: metadata != null && metadata["Grade"] != null
          ? double.tryParse(metadata["Grade"])
          : null,
      gradeDesc: metadata != null && metadata["GradeDesc"] != null
          ? metadata["GradeDesc"]
          : "UNL PREM 2",
      unitPrice: metadata != null && metadata["Unit_price"] != null
          ? double.tryParse(metadata["Unit_price"]) ?? 18.00
          : 18.00,
      kaChingGrade: metadata != null && metadata["KaChing_Grade"] != null
          ? metadata["KaChing_Grade"]
          : "02",
    );
  }

  Map<String, dynamic> toJson() => {
    "orderNo": orderNo,
    "name": name,
    "total": total,
    "volume": volume,
    "grade": grade,
    "gradeDesc": gradeDesc,
    "unitPrice": unitPrice,
    "KaChing_Grade":kaChingGrade,
  };
}
