import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kaching/models/orders.dart';
import 'package:kaching/models/products.dart';
import 'package:kaching/screens/user_number.dart';
import 'package:kaching/services/intent_service.dart';
import 'package:kaching/services/logging_service.dart';
import 'package:kaching/styles/app_styles.dart';
import 'package:kaching/widgets/number_entry_grid.dart';
import 'package:kaching/services/web_service.dart';
import 'package:focus_detector/focus_detector.dart';
import 'package:kaching/services/secure_storage_service.dart';

import '../services/printer_service.dart';

class CompleteOrderPage extends StatefulWidget {
  const CompleteOrderPage({
    required Key key,
    required this.ordersDTO,
    required this.selectedOrderIndex,
  }) : super(key: key);

  final OrdersDto ordersDTO;
  final int selectedOrderIndex;

  @override
  _CompleteOrderPageState createState() => _CompleteOrderPageState();
}

class _CompleteOrderPageState extends State<CompleteOrderPage> with WidgetsBindingObserver {
  late List<Order> orders = [];
  String orderNoJson = "-1";
  String totalAmountJson = "00";
  int declinedAttemptCount = 0;
  int finalizeRetryCount = 0;
  bool isFinalizing = false;

  String userNumber = "";
  String displayNumber = "____";
  String typedDigit = "";
  bool shakeActive = false;

  bool isInTipMode = false;
  bool isInPaymentMode = false;
  bool canPayNow = false;
  bool isLoading = false;
  bool isPaymentCompleted = false;
  bool isAddOnsDialogOpen = false;
  bool isVehicleDetailsDialogOpen = false;
  bool isPrintingDialogOpen = false;

  String paymentStatus = '';
  bool alternatePaymentMethodsAllowed = false;

  String tipAmountString = '0';
  String totalAmountString = '';
  String calculatedTipAmountString = '0';
  String calculatedTotalAmountString = '0';

  Map<String, int> productQuantities = {};
  double additionalTotal = 0.0;
  List<Products> selectedProducts = [];

  Timer? _pollingTimer;
  final Random _random = Random();

  Order? _originalOrder;
  String? _lastPaymentResultData;

  int? mileage;
  String regNo = '';

  // FocusNodes and TextEditingControllers for the dialog TextFields
  final FocusNode _mileageFocusNode = FocusNode();
  final FocusNode _regNoFocusNode = FocusNode();
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _regNoController = TextEditingController();

  double cashSplitAmount = 0.0;
  final TextEditingController _cashSplitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint("CompleteOrderPage initState called");
    setState(() {
      isLoading = true;
      declinedAttemptCount = 0;
      finalizeRetryCount = 0;  // Reset retry count on page load
      mileage = null;
      regNo = '';
      debugPrint("Initialized declinedAttemptCount=$declinedAttemptCount, finalizeRetryCount=$finalizeRetryCount");
    });
    loadData();
    _startPolling();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _mileageFocusNode.dispose();
    _regNoFocusNode.dispose();
    _mileageController.dispose();
    _regNoController.dispose();
    _cashSplitController.dispose();
    debugPrint("CompleteOrderPage dispose called");
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint("AppLifecycleState changed: $state");
    if (state == AppLifecycleState.resumed) {
      if (isVehicleDetailsDialogOpen) {
        if (mounted) {
          setState(() {
            isVehicleDetailsDialogOpen = false;
          });
          Navigator.of(context, rootNavigator: true).popUntil((route) => route.isCurrent);
        }
      } else if (isPrintingDialogOpen) {
        // If we're in the printing dialog, close it and navigate to user number page
        if (mounted) {
          setState(() {
            isPrintingDialogOpen = false;
            isPaymentCompleted = false;  // Reset payment completed state
          });
          // Use Future.microtask to ensure navigation happens after state updates
          Future.microtask(() {
            if (mounted) {
              _navigateToUserNumberPage();
            }
          });
        }
      }
    } else if (state == AppLifecycleState.paused) {
      if (isVehicleDetailsDialogOpen) {
        setState(() {
          isVehicleDetailsDialogOpen = false;
        });
      }
      if (isPrintingDialogOpen) {
        setState(() {
          isPrintingDialogOpen = false;
        });
      }
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 300), (timer) {
      if (mounted && !isInPaymentMode && !isLoading && !isPaymentCompleted) {
        debugPrint("Polling data refresh...");
        loadData();
      } else {
        debugPrint("Polling skipped: widget not mounted, in payment mode, loading, or payment completed");
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    debugPrint("Polling stopped");
  }

  void loadData() async {
    debugPrint("loadData called for userNo: ${widget.ordersDTO.data?.userNo}");
    try {
      setState(() {
        isLoading = true;
      });
      var response = await WebService.fetchOrders(widget.ordersDTO.data!.userNo.toString());
      var jsonData = json.decode(response.body);
      OrdersDto updatedOrdersDTO = OrdersDto.fromJson(jsonData);

      if (updatedOrdersDTO.data == null ||
          updatedOrdersDTO.data!.orders == null ||
          widget.selectedOrderIndex < 0 ||
          widget.selectedOrderIndex >= updatedOrdersDTO.data!.orders!.length) {
        debugPrint(
            "Invalid data: updatedOrdersDTO.data=${updatedOrdersDTO.data}, selectedOrderIndex=${widget.selectedOrderIndex}");
        setState(() {
          orders.clear();
          _originalOrder = null;
          canPayNow = false;
          calculatedTotalAmountString = '0.00';
          totalAmountString = '';
          isLoading = false;
        });
        return;
      }

      setState(() {
        orders.clear();
        orders.addAll(updatedOrdersDTO.data!.orders!);
        _originalOrder = Order.fromJson(orders[widget.selectedOrderIndex].toJson());
        calculatedTotalAmountString =
            orders[widget.selectedOrderIndex].total!.toStringAsFixed(2);
        totalAmountString = (double.parse(calculatedTotalAmountString) + additionalTotal).toStringAsFixed(2);
        double totalNeeded = double.parse(
            orders[widget.selectedOrderIndex].total!.toStringAsFixed(2));
        double currentTotalAmount = double.tryParse(totalAmountString) ?? 0.0;
        canPayNow = currentTotalAmount >= totalNeeded;
        isLoading = false;
        debugPrint(
            "loadData completed: orders=${orders.length}, calculatedTotalAmountString=$calculatedTotalAmountString, totalAmountString=$totalAmountString, canPayNow=$canPayNow");
      });
    } catch (e) {
      debugPrint("Error in loadData: $e");
      setState(() {
        orders.clear();
        _originalOrder = null;
        canPayNow = false;
        calculatedTotalAmountString = '0.00';
        totalAmountString = '';
        isLoading = false;
      });
    }
  }

  Future<bool> _isNetworkAvailable() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void _resetPaymentState() {
    debugPrint("Resetting payment state, declinedAttemptCount=$declinedAttemptCount");
    setState(() {
      isInPaymentMode = false;
      isInTipMode = false;
      tipAmountString = '0';
      totalAmountString = (double.parse(calculatedTotalAmountString) + additionalTotal).toStringAsFixed(2);
      canPayNow = orders.isNotEmpty &&
          widget.selectedOrderIndex < orders.length &&
          double.tryParse(totalAmountString) != null &&
          double.parse(totalAmountString) >=
              double.parse(orders[widget.selectedOrderIndex].total!.toStringAsFixed(2));
      isLoading = true;
      isPaymentCompleted = false;
      productQuantities.clear();
      additionalTotal = 0.0;
      selectedProducts.clear();
      finalizeRetryCount = 0;




      _lastPaymentResultData = null;
      mileage = null;
      regNo = '';
    });
    _startPolling();
    loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
        debugPrint("Post-frame UI refresh triggered");
      }
    });
  }

  void _fetchPumpVas() async {
    try {
      setState(() {
        isLoading = true;
      });
      ProductsResponse productsResponse = await WebService.getPumpVas();
      LoggingService.logInformation('Fetched products (raw toJson): ${productsResponse.toJson()}');
      LoggingService.logInformation('Fetched products count: ${productsResponse.data.length}');
      for (var i = 0; i < productsResponse.data.length; i++) {
        var product = productsResponse.data[i];
        LoggingService.logInformation('Product $i - lineNo: ${product.lineNo}, productCode: ${product.productCode}, shortDescription: ${product.shortDescription}, sellingPrice: ${product.sellingPrice}, status: ${product.status}');
      }

      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      if (productsResponse.data.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Oils/Services'),
              content: const Text('No products available at this time.'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return;
      }

      List<Products> products = productsResponse.data.map((p) => Products(
        lineNo: p.lineNo,
        productCode: p.productCode,
        sellingPrice: p.sellingPrice,
        shortDescription: p.shortDescription,
        status: p.status,
      )).toList();
      LoggingService.logInformation('Deep copied products for dialog: ${products.length} items');
      for (var i = 0; i < products.length; i++) {
        var product = products[i];
        LoggingService.logInformation('Copied Product $i - shortDescription: ${product.shortDescription}, unitPrice: ${product.sellingPrice}');
      }

      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      setState(() {
        isAddOnsDialogOpen = true;
      });

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter dialogSetState) {
              Map<String, int> dialogProductQuantities = Map.from(productQuantities);

              double subtotal = 0.0;
              for (var i = 0; i < products.length; i++) {
                final product = products[i];
                String productKey = product.productCode ?? 'product_$i';
                double price = double.tryParse(product.sellingPrice ?? '0') ?? 0.0;
                int quantity = dialogProductQuantities[productKey] ?? 0;
                subtotal += quantity * price;
              }

              return Scaffold(
                backgroundColor: AppStyles.backgroundColor,
                body: SafeArea(
                  child: WillPopScope(
                    onWillPop: () async {
                      if (mounted) {
                        setState(() {
                          isAddOnsDialogOpen = false;
                        });
                      }
                      Navigator.of(dialogContext).pop();
                      return true;
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          color: AppStyles.backgroundColor,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                "assets/images/kachinglogo.png",
                                height: 50.h,
                                width: 50.w,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint("Error loading addons_icon.png: $error");
                                  return const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 40,
                                  );
                                },
                              ),
                              SizedBox(height: 8.h),
                              const Text(
                                'ADD-ONS',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              color: AppStyles.backgroundColor,
                              child: Column(
                                children: [
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(5),
                                      1: FlexColumnWidth(1),
                                    },
                                    children: [
                                      TableRow(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                                            child: Text(
                                              'Description',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                                            child: Text(
                                              'Qty',
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Divider(
                                    height: 1.h,
                                    color: Colors.grey,
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: products.length,
                                    itemBuilder: (context, index) {
                                      if (index >= products.length) {
                                        LoggingService.logInformation('Index out of bounds: $index, products length: ${products.length}');
                                        return const SizedBox.shrink();
                                      }

                                      final product = products[index];

                                      String productKey = product.productCode ?? 'product_$index';
                                      String description = product.shortDescription ?? 'Product Not Available';
                                      double price = double.tryParse(product.sellingPrice ?? '0') ?? 0.0;
                                      int quantity = dialogProductQuantities[productKey] ?? 0;

                                      LoggingService.logInformation('Rendering product $index: description=$description, price=$price, quantity=$quantity, productKey=$productKey');

                                      return Container(
                                        decoration: BoxDecoration(
                                          color: AppStyles.backgroundColor,
                                          border: Border(
                                            bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Table(
                                              columnWidths: const {
                                                0: FlexColumnWidth(3),
                                                1: FlexColumnWidth(1),
                                              },
                                              children: [
                                                TableRow(
                                                  children: [
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 14.h),
                                                      child: Row(
                                                        children: [
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  description,
                                                                  style: TextStyle(
                                                                    fontSize: 14.sp,
                                                                    color: Colors.white,
                                                                  ),
                                                                  maxLines: 4,
                                                                  softWrap: true,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                                SizedBox(height: 4.h),
                                                                Text(
                                                                  'Quantity: $quantity',
                                                                  style: TextStyle(
                                                                    fontSize: 14.sp,
                                                                    color: Colors.white,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          Text(
                                                            'R${price.toStringAsFixed(2)}',
                                                            style: TextStyle(
                                                              fontSize: 14.sp,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 14.h),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Container(
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              color: const Color(0xFF199D36),
                                                            ),
                                                            child: IconButton(
                                                              icon: Icon(
                                                                Icons.add,
                                                                size: 16.sp,
                                                                color: Colors.white,
                                                              ),
                                                              padding: EdgeInsets.zero,
                                                              constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                                                              onPressed: () {
                                                                dialogSetState(() {
                                                                  dialogProductQuantities[productKey] = quantity + 1;
                                                                  setState(() {
                                                                    productQuantities[productKey] = dialogProductQuantities[productKey]!;
                                                                    additionalTotal += price;
                                                                    additionalTotal = additionalTotal < 0 ? 0.0 : additionalTotal;
                                                                    totalAmountString = (double.parse(calculatedTotalAmountString) + additionalTotal).toStringAsFixed(2);
                                                                    canPayNow = double.parse(totalAmountString) >=
                                                                        double.parse(orders[widget.selectedOrderIndex].total!.toStringAsFixed(2));
                                                                  });
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          if (quantity > 0) ...[
                                                            SizedBox(height: 8.h),
                                                            Container(
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape.circle,
                                                                color: Colors.redAccent,
                                                              ),
                                                              child: IconButton(
                                                                icon: Icon(
                                                                  Icons.remove,
                                                                  size: 16.sp,
                                                                  color: Colors.white,
                                                                ),
                                                                padding: EdgeInsets.zero,
                                                                constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
                                                                onPressed: () {
                                                                  dialogSetState(() {
                                                                    dialogProductQuantities[productKey] = quantity - 1;
                                                                    setState(() {
                                                                      productQuantities[productKey] = dialogProductQuantities[productKey]!;
                                                                      additionalTotal -= price;
                                                                      additionalTotal = additionalTotal < 0 ? 0.0 : additionalTotal;
                                                                      totalAmountString = (double.parse(calculatedTotalAmountString) + additionalTotal).toStringAsFixed(2);
                                                                      canPayNow = double.parse(totalAmountString) >=
                                                                          double.parse(orders[widget.selectedOrderIndex].total!.toStringAsFixed(2));
                                                                    });
                                                                  });
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Subtotal',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          'R${subtotal.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                          color: AppStyles.backgroundColor,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 90.w),
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    side: const BorderSide(width: 1.0, color: Colors.black87),
                                  ),
                                  child: Text(
                                    'BACK',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  onPressed: () {
                                    // Reset all changes when BACK is clicked
                                    setState(() {
                                      productQuantities.clear();
                                      additionalTotal = 0.0;
                                      selectedProducts.clear();
                                      totalAmountString = (double.parse(calculatedTotalAmountString) + additionalTotal).toStringAsFixed(2);
                                      canPayNow = double.parse(totalAmountString) >=
                                          double.parse(orders[widget.selectedOrderIndex].total!.toStringAsFixed(2));
                                      isAddOnsDialogOpen = false;
                                    });
                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 160.w),
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    backgroundColor: const Color(0xFF199D36),
                                    side: const BorderSide(width: 1.0, color: Colors.black87),
                                  ),
                                  child: Text(
                                    'ADD TO BILL',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  onPressed: () async {
                                    List<Products> selectedProductsTemp = [];
                                    for (var i = 0; i < products.length; i++) {
                                      final product = products[i];
                                      String productKey = product.productCode ?? 'product_$i';
                                      int quantity = dialogProductQuantities[productKey] ?? 0;
                                      if (quantity > 0) {
                                        selectedProductsTemp.add(product);
                                      }
                                    }

                                    setState(() {
                                      selectedProducts = selectedProductsTemp;
                                      isAddOnsDialogOpen = false;
                                    });

                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      if (mounted) {
        setState(() {
          isAddOnsDialogOpen = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching pump VAS: $e");
      LoggingService.logInformation('Error fetching pump VAS: $e');
      setState(() {
        isLoading = false;
        isAddOnsDialogOpen = false;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to load Oils/Services. Please try again later.\nError: $e'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  String trimUsername(String username, int maxLength) {
    try {
      if (username.length <= maxLength) return username;
      return '${username.substring(0, maxLength)}...';
    } catch (e) {
      debugPrint("Error in trimUsername: $e");
      return username;
    }
  }

  String _generateRandomPrefix() {
    return (_random.nextInt(9000) + 1000).toString();
  }

  String _removePrefixFromBusinessOrderNo(String paymentResultData, String originalOrderNo) {
    try {
      var jsonData = jsonDecode(paymentResultData);
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('businessOrderNo')) {
        String businessOrderNo = jsonData['businessOrderNo'];
        String unprefixedOrderNo = businessOrderNo.split('-').last;
        if (unprefixedOrderNo == originalOrderNo) {
          jsonData['businessOrderNo'] = unprefixedOrderNo;
          LoggingService.logInformation(
              'Removed prefix from businessOrderNo: $businessOrderNo -> $unprefixedOrderNo');
          return jsonEncode(jsonData);
        } else {
          LoggingService.logInformation(
              'businessOrderNo $businessOrderNo does not match expected orderNo $originalOrderNo');
        }
      } else {
        LoggingService.logInformation('No businessOrderNo found in paymentResultData: $paymentResultData');
      }
    } catch (e) {
      debugPrint("Error removing prefix from paymentResultData: $e");
      LoggingService.logInformation('Error removing prefix: $e');
    }
    return paymentResultData;
  }

  Future<bool> _attemptFinalizeOrder(String paymentResultData, {bool isRetry = false}) async {
    try {
      Order currentOrder = isRetry && _originalOrder != null
          ? _originalOrder!
          : orders[widget.selectedOrderIndex];

      if (selectedProducts.isNotEmpty) {
        bool allVasCreatedSuccessfully = true;
        StringBuffer errorMessages = StringBuffer();
        String orderNumber = currentOrder.orderNo!.toString();

        for (var product in selectedProducts) {
          String productKey = product.productCode ?? 'unknown_${selectedProducts.indexOf(product)}';
          int quantity = productQuantities[productKey] ?? 0;

          for (int i = 0; i < quantity; i++) {
            var createResponse = await WebService.createPumpVas(
              orderNumber,
              widget.ordersDTO.data!.userNo!,
              (double.tryParse(product.sellingPrice ?? '0') ?? 0.0 * 100),
              product.productCode!,
              (int.tryParse(widget.ordersDTO.data!.orders![widget.selectedOrderIndex].name.toString().split(':')[1].trim()) ?? 1),
              currentOrder.orderNo!,
            );

            if (createResponse.statusCode != 200) {
              allVasCreatedSuccessfully = false;
              errorMessages.write(
                  'Failed to create VAS for product ${product.productCode} (unit ${i + 1}/${quantity}): ${createResponse.statusCode} ${createResponse.body}\n');
            } else {
              LoggingService.logInformation(
                  'Successfully created VAS for product ${product.productCode} (unit ${i + 1}/${quantity})');
            }
          }
        }

        if (!allVasCreatedSuccessfully) {
          LoggingService.logInformation('Failed to create some pump VAS products: $errorMessages');
          throw Exception('Failed to create some additional products: $errorMessages');
        }

        LoggingService.logInformation('Successfully created all pump VAS products');
      } else {
        LoggingService.logInformation('No selected products to create pump VAS for');
      }

      String grade = currentOrder.gradeDesc ?? "02";
      String volume = currentOrder.volume?.toStringAsFixed(3) ?? "1.050";
      double totalAmount = double.tryParse(totalAmountString)! - cashSplitAmount;
      int forecourtAmount = (totalAmount * 100).round();

      List<Map<String, dynamic>> forecourtData = [
        {
          'code': grade,
          'quantity': volume,
          'amount': forecourtAmount.toString(),
        },
      ];

      String originalOrderNo = currentOrder.orderNo!.toString();
      String modifiedPaymentResultData =
      _removePrefixFromBusinessOrderNo(paymentResultData, originalOrderNo);
      
      // Parse paymentResultData to get paymentMethod
      var paymentData = jsonDecode(paymentResultData);
      String paymentMethod = paymentData['paymentMethod'] ?? 'CARD';
      // Parse paymentResultData to get paymentMethod
      String card = paymentData['paymentMethod'] ?? 'CARD';
      double cash = double.parse(cashSplitAmount.toStringAsFixed(2));
      String batchNo = paymentData['batchNo'] ;
      LoggingService.logInformation(
          'Finalizing order with originalOrderNo=$originalOrderNo, modifiedPaymentResultData=$modifiedPaymentResultData, mileage=$mileage, regNo=$regNo, paymentMethod=$paymentMethod');
      var finalizeResponse = await WebService.finalizeOrder(
        originalOrderNo,
        widget.ordersDTO.data!.userNo.toString(),
        card,
        batchNo,
        cash,
        mileage,
        regNo,

        modifiedPaymentResultData,
        forecourtData: forecourtData,
      );
      LoggingService.logInformation('Finalize order response: $finalizeResponse');
      LoggingService.logInformation('Order finalized successfully with forecourtData: $forecourtData');
      return true;
    } catch (e) {
      debugPrint("Error in _attemptFinalizeOrder: $e");
      LoggingService.logInformation('Error in _attemptFinalizeOrder: ${e.toString()}');
      throw e;
    }
  }

  void _navigateToUserNumberPage() {
    if (mounted) {
      setState(() {
        orders.clear();
        _originalOrder = null;
        orderNoJson = "-1";
        totalAmountJson = "00";
        isInPaymentMode = false;
        declinedAttemptCount = 0;
        finalizeRetryCount = 0;
        productQuantities.clear();
        additionalTotal = 0.0;
        selectedProducts.clear();
        _lastPaymentResultData = null;
        isPaymentCompleted = false;
        mileage = null;
        regNo = '';
        debugPrint("Navigating to UserNumberPage, reset declinedAttemptCount=$declinedAttemptCount, finalizeRetryCount=$finalizeRetryCount");
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserNumberPage(key: UniqueKey()),
        ),
      );
    }
  }

  void _showVehicleDetailsDialog() {
    if (!mounted) return;

    setState(() {
      isVehicleDetailsDialogOpen = true;
    });

    int? tempMileage = mileage;
    String tempRegNo = regNo ?? '';

    _mileageController.text = tempMileage?.toString() ?? '';
    _regNoController.text = tempRegNo;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: AppStyles.backgroundColor,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vehicle Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                height: 230.h,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        keyboardType: TextInputType.number,
                        controller: _mileageController,
                        focusNode: _mileageFocusNode,
                        onChanged: (value) {
                          setDialogState(() {
                            tempMileage = int.tryParse(value);
                          });
                        },
                        maxLength: 7,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                        decoration: InputDecoration(
                          labelText: 'Mileage',
                          labelStyle: TextStyle(color: Colors.white70, fontSize: 14.sp),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white, width: 1.0),
                          ),
                          counterStyle: TextStyle(color: Colors.white70, fontSize: 12.sp),
                        ),
                        autofocus: true,
                      ),
                      SizedBox(height: 20.h),
                      TextField(
                        keyboardType: TextInputType.text,
                        controller: _regNoController,
                        focusNode: _regNoFocusNode,
                        onChanged: (value) {
                          setDialogState(() {
                            tempRegNo = value;
                          });
                        },
                        maxLength: 12,
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                        decoration: InputDecoration(
                          labelText: 'Reg No',
                          labelStyle: TextStyle(color: Colors.white70, fontSize: 14.sp),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70, width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white, width: 1.0),
                          ),
                          counterStyle: TextStyle(color: Colors.white70, fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    backgroundColor: const Color(0xFF199D36),
                    side: const BorderSide(width: 1.0, color: Colors.black87),
                  ),
                  child: Text(
                    'CONTINUE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                  onPressed: () {
                    if (tempMileage != null && tempMileage.toString().length > 7) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text(
                            'Mileage cannot exceed 7 digits.',
                            style: TextStyle(color: Colors.white, fontSize: 14.sp),
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    if (mounted) {
                      setState(() {
                        mileage = tempMileage ?? 0;
                        regNo = tempRegNo.isEmpty ? '' : tempRegNo;
                        isVehicleDetailsDialogOpen = false;
                      });
                      LoggingService.logInformation('Vehicle Details - Mileage: $mileage, Reg No: $regNo');
                      if (Navigator.of(dialogContext).canPop()) {
                        Navigator.of(dialogContext).pop();
                        _proceedToPayment();
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          isVehicleDetailsDialogOpen = false;
        });
      }
    }).catchError((e) {
      debugPrint("Error showing vehicle details dialog: $e");
      LoggingService.logInformation('Error showing vehicle details dialog: $e');
      if (mounted) {
        setState(() {
          isVehicleDetailsDialogOpen = false;
        });
      }
    });
  }

  void _proceedToPayment() {
    debugPrint("Proceed with payment pressed");
    setState(() {
      isInPaymentMode = true;
      _stopPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        "build called, isLoading=$isLoading, orders.length=${orders.length}, isPaymentCompleted=$isPaymentCompleted, declinedAttemptCount=$declinedAttemptCount");
    try {
      if (isLoading) {
        return Scaffold(
          backgroundColor: AppStyles.backgroundColor,
          body: SafeArea(
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      }

      if (widget.ordersDTO.data == null ||
          widget.ordersDTO.data!.orders == null ||
          widget.selectedOrderIndex < 0 ||
          widget.selectedOrderIndex >= widget.ordersDTO.data!.orders!.length) {
        debugPrint("Invalid order data, rendering error UI");
        return Scaffold(
          backgroundColor: AppStyles.backgroundColor,
          body: SafeArea(
            child: Center(
              child: Text(
                "Error: Invalid order data",
                style: TextStyle(color: Colors.red, fontSize: 20.sp),
              ),
            ),
          ),
        );
      }

      if (isPaymentCompleted) {
        return Scaffold(
          backgroundColor: AppStyles.backgroundColor,
          body: SafeArea(
            child: WillPopScope(
              onWillPop: () async {
                _navigateToUserNumberPage();
                return false;
              },
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 20.h),
                    Text(
                      "Processing transaction...",
                      style: TextStyle(color: Colors.white, fontSize: 20.sp),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      double baseBillAmount = orders.isNotEmpty && widget.selectedOrderIndex < orders.length
          ? orders[widget.selectedOrderIndex].total!
          : widget.ordersDTO.data!.orders![widget.selectedOrderIndex].total!;
      double displayedBillAmount = baseBillAmount;

      debugPrint("Rendering main UI");
      return Scaffold(
        backgroundColor: AppStyles.backgroundColor,
        body: SafeArea(
          child: FocusDetector(
            onForegroundGained: () async {
              debugPrint('----Foreground Gained');
              try {
                _stopPolling();
                String paymentResultData = await IntentService.checkAddpayResultData();
                String paymentResultCode = await IntentService.checkAddpayResultCode();

                LoggingService.logInformation('Foreground gained - payment result code: $paymentResultCode');
                LoggingService.logInformation('Foreground gained - payment result data: $paymentResultData');

                if (!mounted) return;

                // Show insufficient funds popup if paymentResultCode == 'N003'
                if (isInPaymentMode && paymentResultCode == 'N003') {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppStyles.backgroundColor,
                      title: Text(
                        'Insufficient funds',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'Dismiss',
                            style: TextStyle(color: const Color(0xFF199D36), fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                // Only proceed with payment finalization if we're in payment mode, have a successful payment,
                // not in the middle of printing, and not already finalizing
                if (isInPaymentMode && paymentResultCode == '00' && !isPrintingDialogOpen && !isFinalizing) {
                  setState(() {
                    _lastPaymentResultData = paymentResultData;
                    isPaymentCompleted = true;
                  });

                  _retryFinalizeOrder();
                }
              } catch (e) {
                debugPrint("Error in onForegroundGained: $e");
                LoggingService.logInformation('Error processing payment result: $e');
              }
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: const Color(0xff1D2125),
                    padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 8.w),
                    child: Row(
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            backgroundColor: Colors.redAccent,
                            side: const BorderSide(width: 1.0, color: Color.fromARGB(255, 100, 101, 99)),
                          ),
                          onPressed: isFinalizing
                              ? null
                              : () {
                                  debugPrint("Back button pressed");
                                  setState(() {
                                    orderNoJson = "-1";
                                    declinedAttemptCount = 0;
                                    debugPrint("Back navigation, reset declinedAttemptCount= $declinedAttemptCount");
                                  });
                                  Navigator.pop(context);
                                },
                          child: SizedBox(
                            height: 22.h,
                            width: 45.w,
                            child: Center(
                              child: Text(
                                'BACK',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Padding(
                            padding: EdgeInsets.only(right: 10.w),
                            child: Text(
                              '${trimUsername(widget.ordersDTO.data!.userName.toString(), 10)} ${widget.ordersDTO.data!.userNo} | ${widget.ordersDTO.data!.orders![widget.selectedOrderIndex].name}',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                    color: const Color(0xff212121),
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/images/whitelock.png",
                          height: 22.h,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint("Error loading whitelock.png: $error");
                            return const Icon(Icons.error, color: Colors.red);
                          },
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'BILL',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp),
                        ),
                        const Spacer(),
                        Text(
                          displayedBillAmount.toStringAsFixed(2),
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white70, height: 1),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                    color: const Color(0xff212121),
                    child: Row(
                      children: [
                        Icon(Icons.receipt, color: Colors.white),
                        SizedBox(width: 10.w),
                        Text(
                          'ADD-ONS',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp),
                        ),
                        const Spacer(),
                        Text(
                          (additionalTotal < 0 ? 0.0 : additionalTotal).toStringAsFixed(2),
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                    color: const Color(0xff212121),
                    child: Row(
                      children: [
                        Icon(Icons.receipt, color: Colors.white),
                        SizedBox(width: 10.w),
                        Text(
                          'CASH SPLIT',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp),
                        ),
                        const Spacer(),
                        Text(
                          cashSplitAmount.toStringAsFixed(2),
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                    color: AppStyles.backgroundColor,
                    child: Row(
                      children: [
                        Image.asset(
                          "assets/images/whitecalc.png",
                          height: 22.h,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint("Error loading whitecalc.png: $error");
                            return const Icon(Icons.error, color: Colors.red);
                          },
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'TOTAL AMOUNT',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp),
                        ),
                        const Spacer(),
                        Text(
                          (double.tryParse(totalAmountString) != null
                                  ? (double.parse(totalAmountString) - cashSplitAmount).clamp(0, double.infinity)
                                  : 0.0)
                              .toStringAsFixed(2),
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20.sp),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white70, height: 1),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    color: const Color(0xffededed),
                    child: isInPaymentMode
                        ? Center(
                      child: Text(
                        'CHOOSE A PAYMENT METHOD',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.black45,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold),
                      ),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Opacity(
                              opacity: canPayNow ? 1 : 0.5,
                              child: OutlinedButton(
                                onPressed: canPayNow ? _fetchPumpVas : null,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2.0),
                                  ),
                                  backgroundColor: const Color(0xFF0492c2),
                                  minimumSize: ui.Size(100.w, 44.h), // Minimum size as fallback
                                  fixedSize: ui.Size(100.w, 44.h), // Enforce exact size
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'ADD-ONS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Opacity(
                              opacity: canPayNow ? 1 : 0.5,
                              child: OutlinedButton(
                                onPressed: canPayNow
                                    ? () {
                                  _cashSplitController.text = cashSplitAmount > 0 ? cashSplitAmount.toStringAsFixed(2) : '';
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      String? errorText; // Declare outside the builder closure so it persists
                                      final FocusNode cashSplitFocusNode = FocusNode();
                                      // Request focus after the first frame
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        cashSplitFocusNode.requestFocus();
                                      });
                                      return StatefulBuilder(
                                        builder: (context, setDialogState) {
                                          return AlertDialog(
                                            backgroundColor: AppStyles.backgroundColor,
                                            title: Text('CASH SPLIT', style: TextStyle(color: Colors.white, fontSize: 14)),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text('Please enter the cash amount you would like to pay.', style: TextStyle(color: Colors.white,fontSize: 12)),
                                                SizedBox(height: 4),
                                                TextField(
                                                  controller: _cashSplitController,
                                                  focusNode: cashSplitFocusNode,
                                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                  style: TextStyle(color: Colors.white),
                                                  decoration: InputDecoration(
                                                    hintText: 'Cash Amount',
                                                    hintStyle: TextStyle(color: Colors.white54),
                                                    errorText: errorText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('Cancel', style: TextStyle(color: Colors.white)),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  final entered = double.tryParse(_cashSplitController.text.replaceAll(',', '.')) ?? 0.0;
                                                  final total = double.tryParse(totalAmountString) ?? 0.0;
                                                  if (entered >= total) {
                                                    setDialogState(() {
                                                      errorText = "Cash amount can't be the same or\nmore than the total amount.";
                                                    });
                                                    return;
                                                  }
                                                  setState(() {
                                                    cashSplitAmount = entered;
                                                  });
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('OK', style: TextStyle(color: Color(0xFF199D36))),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  );
                                }
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2.0),
                                  ),
                                  backgroundColor: Colors.orange,
                                  minimumSize: ui.Size(100.w, 44.h), // Minimum size as fallback
                                  fixedSize: ui.Size(100.w, 44.h), // Enforce exact size
                                  padding: EdgeInsets.zero,
                                ),
                                child: Text(
                                  'CASH-SPLIT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Opacity(
                          opacity: canPayNow ? 1 : 0.5,
                          child: OutlinedButton(
                            onPressed: canPayNow
                                ? () {
                              final total = double.tryParse(totalAmountString) ?? 0.0;
                              if (cashSplitAmount >= total) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppStyles.backgroundColor,
                                    title: Text('Error', style: TextStyle(color: Colors.white)),
                                    content: Text(
                                      'The cash split amount can\'t be more than the total amount. Please adjust the cash split amount before proceeding.',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text('OK', style: TextStyle(color: Color(0xFF199D36))),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                              _showVehicleDetailsDialog();
                            }
                                : null,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(2.0),
                              ),
                              backgroundColor: const Color(0xFF199D36),
                              minimumSize: ui.Size(200.w, 100.h), // Minimum size as fallback
                              fixedSize: ui.Size(200.w, 100.h), // Enforce exact size
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'PROCEED WITH PAYMENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  isInPaymentMode
                      ? Container(
                    height: 300.h,
                    child: ListView(
                      children: [
                        InkWell(
                          onTap: isPrintingDialogOpen ? null : () async {
                            debugPrint(
                                "Tapped on Pay with Card Container, declinedAttemptCount=$declinedAttemptCount");
                            try {
                              String originalOrderNo =
                              orders[widget.selectedOrderIndex].orderNo!.toString();
                              String randomPrefix = _generateRandomPrefix();
                              orderNoJson = "$randomPrefix-$originalOrderNo";
                              double totalAmount = (double.tryParse(totalAmountString) ?? 0.0) - cashSplitAmount;
                              if (totalAmount < 0) totalAmount = 0.0;
                              totalAmountJson = (totalAmount * 100).round().toString();

                              String? grade = orders[widget.selectedOrderIndex].kaChingGrade;
                              String volume = orders[widget.selectedOrderIndex].volume?.toStringAsFixed(3) ?? "1.050";
                              String forecourtAmount = (totalAmount * 100).round().toString();

                              List<Map<String, dynamic>> forecourtData = [
                                {
                                  'code': grade,
                                  'quantity': volume,
                                  'amount': forecourtAmount,
                                },
                              ];

                              if (selectedProducts.isNotEmpty) {
                                double totalQuantity = 0.0;
                                for (var product in selectedProducts) {
                                  String productKey = product.productCode ?? 'unknown_${selectedProducts.indexOf(product)}';
                                  double quantity = (productQuantities[productKey] ?? 0).toDouble(); // Ensure quantity is a double
                                  totalQuantity += quantity;
                                }

                                forecourtData.add({
                                  'code': "22",
                                  'quantity': totalQuantity.toStringAsFixed(3), // Format to 3 decimal places
                                  'amount': (additionalTotal * 100).round().toString(),
                                });
                              }

                              String jsonString =
                                  "{\"businessOrderNo\":\"$orderNoJson\",\"paymentScenario\":\"CARD\",\"amt\":\"$totalAmountJson\",\"forecourtData\":${jsonEncode(forecourtData)}}";
                              LoggingService.logInformation(
                                  'Payment Request with businessOrderNo=$orderNoJson, randomPrefix=$randomPrefix: $jsonString');

                              await IntentService.launchAddpayIntent(jsonString);
                            } catch (e) {
                              debugPrint("Error in card payment: $e");
                              LoggingService.logInformation('Error initiating card payment: $e');
                              setState(() {
                                declinedAttemptCount++;
                                debugPrint(
                                    "Card payment error, incremented declinedAttemptCount=$declinedAttemptCount");
                              });
                              _resetPaymentState();
                            }
                          },
                          child: Container(
                            color: AppStyles.lightBackgroundColor,
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0).h,
                            child: Container(
                              decoration: BoxDecoration(
                                  color: const Color(0xffededed),
                                  border: Border.all(color: Colors.black)),
                              padding: EdgeInsets.all(10.h),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'DEBIT / CREDIT CARD',
                                      style: TextStyle(
                                          color: const Color(0xff383f48),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18.sp),
                                    ),
                                  ),
                                  Image.asset(
                                    "assets/images/pmdccard.png",
                                    height: 64.h,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint("Error loading pmdccard.png: $error");
                                      return const Icon(Icons.error, color: Colors.red);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            debugPrint("Tapped on SMS Container");
                          },
                          child: Container(
                            color: AppStyles.lightBackgroundColor,
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 0).h,
                            child: Opacity(
                              opacity: alternatePaymentMethodsAllowed ? 1 : 0.1,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: const Color(0xffededed),
                                    border: Border.all(color: Colors.black)),
                                padding: EdgeInsets.all(10.h),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'SEND LINK VIA SMS',
                                        style: TextStyle(
                                            color: const Color(0xff383f48),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.sp),
                                      ),
                                    ),
                                    Image.asset(
                                      "assets/images/pmsms.png",
                                      height: 64.h,
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint("Error loading pmsms.png: $error");
                                        return const Icon(Icons.error, color: Colors.red);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            debugPrint("Tapped on Email Container");
                          },
                          child: Container(
                            color: AppStyles.lightBackgroundColor,
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 0).h,
                            child: Opacity(
                              opacity: alternatePaymentMethodsAllowed ? 1 : 0.1,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: const Color(0xffededed),
                                    border: Border.all(color: Colors.black)),
                                padding: EdgeInsets.all(10.h),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'SEND LINK VIA EMAIL',
                                        style: TextStyle(
                                            color: const Color(0xff383f48),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.sp),
                                      ),
                                    ),
                                    Image.asset(
                                      "assets/images/pmemail.png",
                                      height: 64.h,
                                      errorBuilder: (context, error, stackTrace) {
                                        debugPrint("Error loading pmemail.png: $error");
                                        return const Icon(Icons.error, color: Colors.red);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            debugPrint("Tapped on WhatsApp Container");
                          },
                          child: Container(
                            color: AppStyles.lightBackgroundColor,
                            padding: const EdgeInsets.fromLTRB(10, 5, 10, 10).h,
                            child: Opacity(
                              opacity: alternatePaymentMethodsAllowed ? 1 : 0.1,
                              child: Container(
                                decoration: BoxDecoration(
                                    color: const Color(0xffededed),
                                    border: Border.all(color: Colors.black)),
                                padding: EdgeInsets.all(10.h),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'SEND LINK VIA WHATSAPP',
                                        style: TextStyle(
                                            color: const Color(0xff383f48),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18.sp),
                                      ),
                                    ),
                                    Image.asset(
                                      "assets/images/pmwhatsapp.png",
                                      height: 64.h,
                                      errorBuilder: (index, error, stackTrace) {
                                        debugPrint("Error loading pmwhatsapp.png: $error");
                                        return const Icon(Icons.error, color: Colors.red);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      : NumberEntryGridWidget(
                    key: UniqueKey(),
                    onChanged: (value) {
                      debugPrint("NumberEntryGrid input: $value");
                      try {
                        setState(() {
                          typedDigit = value;

                          if (typedDigit == 'OK' && canPayNow) {
                            final total = double.tryParse(totalAmountString) ?? 0.0;
                            if (cashSplitAmount >= total) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppStyles.backgroundColor,
                                  title: Text('Error', style: TextStyle(color: Colors.white)),
                                  content: Text(
                                    'The cash split amount can\'t be more than the total amount. Please adjust the cash split amount before proceeding.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text('OK', style: TextStyle(color: Color(0xFF199D36))),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }
                            isInPaymentMode = true;
                            _stopPolling();
                            return;
                          }

                          if (typedDigit == 'CLEAR') {
                            if (isInTipMode) {
                              tipAmountString = '0';
                              calculatedTipAmountString = '0';
                            }
                            debugPrint("Cleared: tipAmountString=$tipAmountString");
                            return;
                          }

                          if (typedDigit == 'BACK') {
                            if (isInTipMode && tipAmountString.isNotEmpty) {
                              tipAmountString =
                                  tipAmountString.substring(0, tipAmountString.length - 1);
                              if (tipAmountString.isEmpty) {
                                tipAmountString = '0';
                              }
                            }
                            debugPrint("Backspace: tipAmountString=$tipAmountString");
                            return;
                          }

                          if (typedDigit != 'OK' && typedDigit != '00') {
                            if (isInTipMode) {
                              if (typedDigit == '.' && !tipAmountString.contains('.')) {
                                tipAmountString += typedDigit;
                              } else if (typedDigit != '.') {
                                tipAmountString += typedDigit;
                              }
                              calculatedTipAmountString = tipAmountString;
                            }
                            debugPrint("Digit added: tipAmountString=$tipAmountString");
                          }

                          if (isInTipMode) {
                            double totalNeeded = double.parse(
                                orders[widget.selectedOrderIndex].total!.toStringAsFixed(2));
                            double tipAmount = double.tryParse(tipAmountString) ?? 0.0;
                            double totalAmount = totalNeeded + tipAmount + additionalTotal - cashSplitAmount;
                            calculatedTotalAmountString = totalAmount.toStringAsFixed(2);
                            totalAmountString = calculatedTotalAmountString;
                          }

                          double totalNeeded = double.parse(
                              orders[widget.selectedOrderIndex].total!.toStringAsFixed(2));
                          double currentTotalAmount = double.tryParse(totalAmountString) ?? 0.0;
                          canPayNow = currentTotalAmount >= totalNeeded;
                          debugPrint(
                              "Validation: currentTotalAmount=$currentTotalAmount, totalNeeded=$totalNeeded, canPayNow=$canPayNow");
                        });
                      } catch (e) {
                        debugPrint("Error in NumberEntryGrid onChanged: $e");
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error in build: $e");
      return Scaffold(
        backgroundColor: AppStyles.backgroundColor,
        body: SafeArea(
          child: Center(
            child: Text(
              "Error: Failed to render page\n$e",
              style: TextStyle(color: Colors.red, fontSize: 20.sp),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _retryFinalizeOrder() async {
    if (isFinalizing) {
      debugPrint("Finalization already in progress, skipping");
      return;
    }
    
    // Only proceed if we're actually in payment mode or have payment data
    if (!isInPaymentMode && _lastPaymentResultData == null) {
      debugPrint("Not in payment mode and no payment data, skipping finalization");
      return;
    }
    
    isFinalizing = true;
    debugPrint("Starting finalization process");
    
    try {
      if (!await _isNetworkAvailable()) {
        LoggingService.logInformation('No network available for retry. Waiting for connectivity.');
        // Check retry count before showing dialog
        if (finalizeRetryCount >= 4) {
          _showFinalErrorDialog();
        } else {
          _showConnectionLostDialog();
        }
        return;
      }

      // First, attempt to finalize the order
      bool success = await _attemptFinalizeOrder(_lastPaymentResultData!, isRetry: true);
      if (success) {
        // Build slipData and save transaction immediately after successful finalization
        final currentOrder = orders[widget.selectedOrderIndex];
        final paymentData = jsonDecode(_lastPaymentResultData!);
        final transId = paymentData['transactionID']?.toString();
        final paymentMethod = paymentData['paymentMethod']?.toString();
        final cardNumber = paymentData['cardNo']?.toString();
        final status = paymentData['respCode']?.toString();
        final merchantID = paymentData['merchantID']?.toString() ?? '';
        final terminalID = paymentData['terminalID']?.toString() ?? '';
        final transDate = paymentData['transEndTime']?.toString() ?? '';
        final authNo = paymentData['authCode']?.toString() ?? '';
        final tvrNo = paymentData['tVR']?.toString() ?? '';
        final aidNo = paymentData['aID']?.toString() ?? '';
        final attendee = trimUsername(widget.ordersDTO.data!.userName.toString(), 20);
        final cash = cashSplitAmount;
        final cardAmount = 'R${(double.parse(totalAmountString) - cashSplitAmount).toStringAsFixed(2)}';

        if (status == "00") {
          final items = <String>[
            'Fuel: ${currentOrder.gradeDesc ?? "Unknown"} (${currentOrder.volume?.toStringAsFixed(3) ?? "0.000"} L)',
            'Fuel Amount: R${currentOrder.total?.toStringAsFixed(2) ?? "0.00"}',
          ];

          if (selectedProducts.isNotEmpty) {
            for (var product in selectedProducts) {
              final productKey = product.productCode ?? 'unknown_${selectedProducts.indexOf(product)}';
              final quantity = productQuantities[productKey] ?? 0;
              if (quantity > 0) {
                String baseName = product.shortDescription ?? "Unknown";
                baseName = baseName.replaceAll(RegExp(r'\s*\d+\s*(?:w|W|DOT|dot)\s*\d*'), '');
                baseName = baseName.replaceAll(RegExp(r'\s*\d+\s*'), '').trim();
                items.add('$baseName (x$quantity): R${((double.tryParse(product.sellingPrice ?? '0') ?? 0.0) * quantity).toStringAsFixed(2)}');
              }
            }
          }

          if (mileage != null) items.add('Mileage: $mileage km');
          if (regNo.isNotEmpty) items.add('Reg No: $regNo');

          final slipData = {
            'title': 'Freshstop Stellendale',
            'address': 'Cnr Sunvalley Road, Stellendale Ave, &, Cape Town, 7580',
            'transId': transId,
            'items': items,
            'total': 'R$totalAmountString',
            'footer title': 'Powered by Kaching',
            'paymentMethod': '$paymentMethod',
            'cardNo': '$cardNumber',
            'status': '$status',
            'merchantID': merchantID,
            'terminalID': terminalID,
            'transDate': transDate,
            'copyType': 'MERCHANT COPY',
            'authNo': authNo,
            'tvrNo': tvrNo,
            'aidNo': aidNo,
            'attendee': attendee,
            'cash': 'R${cashSplitAmount.toStringAsFixed(2)}',
            'cardAmount': 'R${(double.parse(totalAmountString) - cashSplitAmount).toStringAsFixed(2)}'
          };
          await SecureStorageService.saveTransaction(slipData);
        }
        setState(() {
          isFinalizing = false;
          isPaymentCompleted = false;
        });
        _showMerchantCopyPrompt();
      } else {
        _handleFinalizationError('Finalization attempt returned false.');
      }
    } catch (e) {
      _handleFinalizationError(e.toString());
    }
  }

  void _showConnectionLostDialog() {
    if (!mounted) return;
    
    setState(() {
      isPaymentCompleted = false;  // Remove processing screen
    });

    // Show retry dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: AppStyles.backgroundColor,
            title: Text(
              'Connection Lost',
              style: TextStyle(color: Colors.white, fontSize: 18.sp),
            ),
            content: Text(
              'We couldn\'t finalize your order. Please try again.',
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Try Again',
                  style: TextStyle(color: const Color(0xFF199D36), fontSize: 16.sp),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    finalizeRetryCount++;
                  });
                  _retryFinalizeOrder();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFinalErrorDialog() {
    if (!mounted) return;
    
    setState(() {
      isPaymentCompleted = false;  // Remove processing screen
    });

    // Max retries reached - show final error dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: AppStyles.backgroundColor,
            title: Text(
              'Connection Error',
              style: TextStyle(color: Colors.white, fontSize: 18.sp),
            ),
            content: Text(
              'Connection could not be restored. Please check your WiFi connection and contact support.',
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Close',
                  style: TextStyle(color: const Color(0xFF199D36), fontSize: 16.sp),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToUserNumberPage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMerchantCopyPrompt() {
    if (!mounted) return;
    setState(() {
      isPrintingDialogOpen = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppStyles.backgroundColor,
          title: Text('Merchant Copy', style: TextStyle(color: Colors.white, fontSize: 18.sp)),
          content: Text('Would you like to print the Merchant\'s copy?', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
          actions: [
            TextButton(
              child: Text('NO', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
              onPressed: () {
                Navigator.of(dialogContext).pop();

                _showCustomerCopyDialog();
              },
            ),
            TextButton(
              child: Text('YES', style: TextStyle(color: const Color(0xFF199D36), fontSize: 16.sp)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _triggerPrinting(isMerchantCopy: true);
                final printerStatus = await PrinterService.checkPrinterStatus(context);
                if (printerStatus == 'out_of_paper') return;
                _showCustomerCopyDialog();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCustomerCopyDialog() {
    if (!mounted) return;
    // isPrintingDialogOpen is already true from merchant copy prompt
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppStyles.backgroundColor,
          title: Text('Print Customer Copy?', style: TextStyle(color: Colors.white, fontSize: 18.sp)),
          content: Text('Would you like to print the customer\'s copy?', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
          actions: <Widget>[
            TextButton(
              child: Text('No', style: TextStyle(color: Colors.white, fontSize: 16.sp)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  isPrintingDialogOpen = false;
                });
                _navigateToUserNumberPage();
              },
            ),
            TextButton(
              child: Text('Yes', style: TextStyle(color: const Color(0xFF199D36), fontSize: 16.sp)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _triggerPrinting(isMerchantCopy: false);
                setState(() {
                  isPrintingDialogOpen = false;
                });
                _navigateToUserNumberPage();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleFinalizationError(String error) {
    setState(() {
      isFinalizing = false;
      isPaymentCompleted = false;
      isPrintingDialogOpen = false;
    });

    // Log the specific error
    LoggingService.logInformation('Handling finalization error: $error');

    // Re-introduce the retry logic here
    if (!mounted) return;

    if (finalizeRetryCount >= 4) {
      _showFinalErrorDialog();
    } else {
      _showConnectionLostDialog();
    }
  }

  Future<void> _triggerPrinting({required bool isMerchantCopy}) async {
    try {
      if (!mounted) return;

      final currentOrder = orders[widget.selectedOrderIndex];
      final paymentData = jsonDecode(_lastPaymentResultData!);
      final transId = paymentData['transactionID']?.toString();
      final paymentMethod = paymentData['paymentMethod']?.toString();
      final cardNumber = paymentData['cardNo']?.toString();
      final status = paymentData['respCode']?.toString();
      final merchantID = paymentData['merchantID']?.toString() ?? '';
      final terminalID = paymentData['terminalID']?.toString() ?? '';
      final transDate = paymentData['transEndTime']?.toString() ?? '';
      final authNo = paymentData['authCode']?.toString() ?? '';
      final tvrNo = paymentData['tVR']?.toString() ?? '';
      final aidNo = paymentData['aID']?.toString() ?? '';
      final attendee = trimUsername(widget.ordersDTO.data!.userName.toString(), 20);
      final cash = cashSplitAmount;
      final cardAmount = 'R${(double.parse(totalAmountString) - cashSplitAmount).toStringAsFixed(2)}';

      if (status == "00") {
        final items = <String>[
          'Fuel: ${currentOrder.gradeDesc ?? "Unknown"} (${currentOrder.volume?.toStringAsFixed(3) ?? "0.000"} L)',
          'Fuel Amount: R${currentOrder.total?.toStringAsFixed(2) ?? "0.00"}',
        ];

        if (selectedProducts.isNotEmpty) {
          for (var product in selectedProducts) {
            final productKey = product.productCode ?? 'unknown_${selectedProducts.indexOf(product)}';
            final quantity = productQuantities[productKey] ?? 0;
            if (quantity > 0) {
              String baseName = product.shortDescription ?? "Unknown";
              baseName = baseName.replaceAll(RegExp(r'\s*\d+\s*(?:w|W|DOT|dot)\s*\d*'), '');
              baseName = baseName.replaceAll(RegExp(r'\s*\d+\s*'), '').trim();
              items.add('$baseName (x$quantity): R${((double.tryParse(product.sellingPrice ?? '0') ?? 0.0) * quantity).toStringAsFixed(2)}');
            }
          }
        }

        if (mileage != null) items.add('Mileage: $mileage km');
        if (regNo.isNotEmpty) items.add('Reg No: $regNo');

        final slipData = {
          'title': 'Freshstop Stellendale',
          'address': 'Cnr Sunvalley Road, Stellendale Ave, &, Cape Town, 7580',
          'transId': transId,
          'items': items,
          'total': 'R$totalAmountString',
          'footer title': 'Powered by Kaching',
          'paymentMethod': '$paymentMethod',
          'cardNo': '$cardNumber',
          'status': '$status',
          'merchantID': merchantID,
          'terminalID': terminalID,
          'transDate': transDate,
          'copyType': isMerchantCopy ? 'MERCHANT COPY' : 'CUSTOMER COPY',
          'authNo': authNo,
          'tvrNo': tvrNo,
          'aidNo': aidNo,
          'attendee': attendee,
          'cash': 'R${cashSplitAmount.toStringAsFixed(2)}',
          'cardAmount': 'R${(double.parse(totalAmountString) - cashSplitAmount).toStringAsFixed(2)}'
        };

        await PrinterService.checkPrinterStatus(context);
        await PrinterService.printCustomSlip(slipData);
      }
    } catch (e) {
      debugPrint("Error in _triggerPrinting: $e");
      LoggingService.logInformation('Error in _triggerPrinting: ${e.toString()}');
    }
  }
}
