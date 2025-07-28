import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kaching/models/orders.dart';
import 'package:kaching/screens/complete_order.dart';
import 'package:kaching/screens/user_number.dart';
import 'package:kaching/services/web_service.dart';
import 'package:kaching/styles/app_styles.dart';
import '../services/logging_service.dart';
import '../services/intent_service.dart';
import '../services/secure_storage_service.dart';
import '../services/printer_service.dart';

class SelectOrderPage extends StatefulWidget {
  const SelectOrderPage({required Key key, required this.ordersDTO})
      : super(key: key);

  final OrdersDto ordersDTO;

  @override
  createState() => _SelectOrderPageState();
}

class _SelectOrderPageState extends State<SelectOrderPage> with WidgetsBindingObserver {
  late List<Order> orders = [];
  late int selectedIndex = -1;
  Timer? _pollingTimer;
  bool _isRefreshing = false;
  Timer? _inactivityTimer; // Timer to detect inactivity and show a prompt
  bool _isSettlementIntent = false; // Add flag to track settlement intent
  bool isLoading = true;
  bool isPrinting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    debugPrint("SelectOrderPage initState called");
    setState(() {
      isLoading = true;
      selectedIndex = -1;
      debugPrint("Initialized selectedIndex=$selectedIndex");
    });
    loadData();
    startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint("AppLifecycleState changed: $state");
    if (state == AppLifecycleState.resumed) {
      // App resumed from background (e.g., after unlocking or returning from Addpay)
      debugPrint("App resumed, checking if settlement result needs to be checked");
      if (_isSettlementIntent) {
        _checkSettlementResult();
        _isSettlementIntent = false; // Reset the flag
      }
      
      // Force a UI rebuild
      setState(() {
        orders = List.from(orders); // Trigger rebuild of ListView
      });
      startPolling();
    } else if (state == AppLifecycleState.paused) {
      // App paused (e.g., when device locks)
      debugPrint("App paused, stopping timers");
      _pollingTimer?.cancel();
      _inactivityTimer?.cancel();
    }
  }


  loadData() async {
    debugPrint("UserNo: ${widget.ordersDTO.data!.userNo.toString()}");
    orders.clear();
    if (widget.ordersDTO.data!.orders != null) {
      orders.addAll(widget.ordersDTO.data!.orders!);
      for (var order in orders) {
        debugPrint(
            "Initial Order: orderNo=${order.orderNo}, name=${order.name}, total=${order.total}, volume=${order.volume}, gradedesc=${order.gradeDesc}, unitPrice=${order.unitPrice}");
      }
    }
    debugPrint("Orders loaded: ${orders.length}");
    setState(() {
      isLoading = false;
    });
  }

  void startPolling() {
    _pollingTimer?.cancel();
    debugPrint("Starting polling timer");
    _pollingTimer = Timer.periodic(Duration(seconds: 300), (timer) {
      if (mounted && !isLoading) {
        debugPrint("Polling data refresh...");
        _refreshOrders();
      } else {
        debugPrint("Polling skipped: widget not mounted or loading");
      }
    });
  }

  Future<void> _manualRefresh() async {
    if (_isRefreshing) return;
    debugPrint("Manual refresh triggered");
    setState(() {
      _isRefreshing = true;
    });
    await _refreshOrders();
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _refreshOrders() async {
    try {
      final userNo = widget.ordersDTO.data!.userNo.toString();
      debugPrint("Refreshing orders for userNo: $userNo");
      final resp = await WebService.fetchOrders(userNo);
      debugPrint("FetchOrders response status: ${resp.statusCode}");
      debugPrint("FetchOrders response body: ${resp.body}");
      if (resp.statusCode == 200) {
        final newOrdersDTO = ordersDtoFromJson(resp.body);
        if (newOrdersDTO.data?.orders != null) {
          setState(() {
            final currentOrderNo =
            selectedIndex != -1 ? orders[selectedIndex].orderNo : null;
            orders.clear();
            orders.addAll(newOrdersDTO.data!.orders!);
            for (var order in orders) {
              debugPrint(
                  "Refreshed Order: orderNo=${order.orderNo}, name=${order.name}, total=${order.total}");
            }
            if (currentOrderNo != null) {
              selectedIndex = orders
                  .indexWhere((order) => order.orderNo == currentOrderNo);
              if (selectedIndex == -1) {
                selectedIndex = -1;
              }
            }
          });
          debugPrint("Orders refreshed: ${orders.length}");
        } else {
          debugPrint("No orders in refreshed DTO");
        }
      } else {
        debugPrint("Failed to fetch orders: ${resp.statusCode}");
      }
    } catch (e) {
      debugPrint("Error polling orders: $e");
    }
  }

  @override
  void dispose() {
    debugPrint("SelectOrderPage dispose called");
    _pollingTimer?.cancel();
    _inactivityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _getUserRole() {
    final String? orderTypeName = widget.ordersDTO.data!.orderTypeName;
    final String? userName = widget.ordersDTO.data!.userName;

    if (orderTypeName?.toLowerCase().contains('waiter') == true ||
        userName?.toLowerCase().contains('waiter') == true) {
      return 'waiter';
    } else if (orderTypeName?.toLowerCase().contains('barman') == true ||
        userName?.toLowerCase().contains('barman') == true) {
      return 'barman';
    } else if (orderTypeName?.toLowerCase().contains('takeaway') == true ||
        userName?.toLowerCase().contains('togo') == true) {
      return 'togo';
    } else {
      return 'attendant';
    }
  }

  Size _getImageSize(String role) {
    switch (role) {
      case 'waiter':
      case 'togo':
        return Size(80.w, 80.h);
      case 'barman':
        return Size(60.w, 80.h);
      default:
        return Size(30.w, 30.h);
    }
  }

  String _trimName(String? DISTname, int maxLength) {
    if (DISTname == null || DISTname.isEmpty) return 'ORDER';
    if (DISTname.length <= maxLength) return DISTname;
    return '${DISTname.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    // Reinitialize ScreenUtil to handle screen size changes
    ScreenUtil.init(
      context,
      designSize: const Size(360, 780),
      minTextAdapt: true,
      splitScreenMode: true,
    );

    final String role = _getUserRole();
    final String selectionText;
    final String imageAsset;
    final Size imageSize = _getImageSize(role);

    switch (role) {
      case 'waiter':
        selectionText = 'SELECT TABLE';
        imageAsset = 'assets/images/table_white.png';
        break;
      case 'togo':
        selectionText = 'SELECT TAKEAWAY';
        imageAsset = 'assets/images/takeaway.png';
        break;
      case 'barman':
        selectionText = 'SELECT BAR TAB';
        imageAsset = 'assets/images/bar_tab_white_resized.png';
        break;
      default:
        selectionText = 'SELECT PUMP';
        imageAsset = 'assets/images/whitegaspump.png';
        break;
    }

    return GestureDetector(
      onTap: () {
        debugPrint("User tapped screen, resetting inactivity timer");
      },
      child: Container(
        constraints: const BoxConstraints.expand(),
        child: SafeArea(
          child: Scaffold(
            backgroundColor: Color(0xff1D2125),
            body: Column(
              children: [
                Container(
                  color: Color(0xff1D2125),
                  padding: const EdgeInsets.fromLTRB(0, 10, 20, 0).h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                        onPressed: _showBottomSheet,
                        tooltip: 'Menu',
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.ordersDTO.data!.userName.toString()} ${widget.ordersDTO.data!.userNo.toString()}',
                            style: AppStyles.mediumTextStyle,
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 5).h,
                            child: Text(
                              selectionText,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0,
                                  fontSize: 18.sp),
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Row(
                        children: [
                          IconButton(
                            icon: _isRefreshing
                                ? SizedBox(
                              width: 24.w,
                              height: 24.h,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : Icon(
                              Icons.refresh,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                            onPressed: _manualRefresh,
                            tooltip: 'Refresh Orders',
                          ),
                          Container(
                            alignment: Alignment.topLeft,
                            height: 40.h,
                            child: Image.asset("assets/images/kachinglogo.png"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0).h,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: Container(
                        width: 360.0.w,
                        padding: const EdgeInsets.fromLTRB(10, 1, 10, 1).h,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white10,
                              width: 1,
                            ),
                            top: BorderSide(
                              color: Colors.white10,
                              width: 1,
                            ),
                          ),
                          color: Color.fromARGB(255, 31, 31, 31),
                        ),
                        child: ListView.builder(
                          key: ValueKey(orders.length),
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: orders.length,
                          itemBuilder: (context, position) {
                            final String displayName = role == 'waiter'
                                ? _trimName('Table ${orders[position].orderNo}', 10)
                                : _trimName(orders[position].name, 10);

                            return Container(
                              key: ValueKey(orders[position].orderNo ?? position),
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0).h,
                              child: ClipRRect(
                                child: Container(
                                  width: 350.0.w,
                                  height: role == 'attendant' ? 110.h : 70.h,
                                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 0).h,
                                  decoration: BoxDecoration(
                                    color: position == selectedIndex
                                        ? const Color.fromARGB(255, 53, 78, 21)
                                        : const Color.fromARGB(255, 31, 31, 31),
                                  ),
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(0),
                                      ),
                                      side: BorderSide(
                                        color: position == selectedIndex
                                            ? const Color(0xFF89bf40)
                                            : const Color(0xFF353535),
                                      ),
                                    ),
                                    onPressed: () {
                                      debugPrint(
                                          'Selected order at index: $position, orderNo: ${orders[position].orderNo}');
                                      setState(() {
                                        selectedIndex = position;
                                      });
                                    },
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Stack(
                                          alignment: Alignment.centerLeft,
                                          children: [
                                            Positioned(
                                              child: SizedBox(
                                                width: imageSize.width,
                                                height: imageSize.height,
                                                child: Center(
                                                  child: Image.asset(
                                                    imageAsset,
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.fromLTRB(12, 0, 0, 0).h,
                                                child: Text(
                                                  displayName,
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontFamily: 'RobotoCondensed',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18.sp,
                                                  ),
                                                ),
                                              ),
                                              if (role == 'attendant') ...[
                                                Container(
                                                  padding: const EdgeInsets.fromLTRB(12, 4, 0, 0).h,
                                                  child: Text(
                                                    'Volume: ${orders[position].volume?.toStringAsFixed(2) ?? "0.00"}',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontFamily: 'RobotoCondensed',
                                                      fontSize: 14.sp,
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.fromLTRB(12, 2, 0, 0).h,
                                                  child: Text(
                                                    'Grade: ${orders[position].gradeDesc ?? "N/A"}',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontFamily: 'RobotoCondensed',
                                                      fontSize: 14.sp,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.fromLTRB(12, 0, 0, 0).h,
                                              child: Text(
                                                orders[position].total!.toStringAsFixed(2),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'RobotoCondensed',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18.sp,
                                                ),
                                              ),
                                            ),
                                            if (role == 'attendant') ...[
                                              Container(
                                                padding: const EdgeInsets.fromLTRB(12, 2, 0, 0).h,
                                                child: Text(
                                                  'Unit Price: ${orders[position].unitPrice?.toStringAsFixed(2) ?? "0.00"}',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontFamily: 'RobotoCondensed',
                                                    fontSize: 14.sp,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(15, 15, 5, 15).h,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                      backgroundColor: Colors.redAccent,
                      side: const BorderSide(
                        width: 1.0,
                        color: Color.fromARGB(255, 100, 101, 99),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserNumberPage(
                            key: UniqueKey(),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      alignment: Alignment.center,
                      height: 38.h,
                      width: 107.w,
                      child: Text(
                        'BACK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          letterSpacing: 0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(5, 15, 15, 15).h,
                  child: Opacity(
                    opacity: selectedIndex != -1 ? 1 : 0,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        backgroundColor: const Color(0xFF199D36),
                      ),
                      onPressed: () async {
                        if (selectedIndex != -1) {
                          try {
                            String userNo = widget.ordersDTO.data!.userNo.toString();
                            final response = await WebService.fetchOrders(userNo);
                            if (response.statusCode == 200) {
                              final jsonData = jsonDecode(response.body);
                              OrdersDto updatedOrdersDTO = OrdersDto.fromJson(jsonData);
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CompleteOrderPage(
                                      key: UniqueKey(),
                                      ordersDTO: updatedOrdersDTO,
                                      selectedOrderIndex: selectedIndex,
                                    ),
                                  ),
                                );
                              }
                            } else {
                              LoggingService.logInformation(
                                  'Failed to fetch updated orders: ${response.statusCode} - ${response.body}');
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CompleteOrderPage(
                                      key: UniqueKey(),
                                      ordersDTO: widget.ordersDTO,
                                      selectedOrderIndex: selectedIndex,
                                    ),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            LoggingService.logInformation('Error fetching updated orders: $e');
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CompleteOrderPage(
                                    key: UniqueKey(),
                                    ordersDTO: widget.ordersDTO,
                                    selectedOrderIndex: selectedIndex,
                                  ),
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: 38.h,
                        width: 107.w,
                        child: Text(
                          'CONFIRM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                            letterSpacing: 0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppStyles.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Colors.white),
                title: Text(
                  'SETTLEMENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  
                  // Show confirmation dialog
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: Text(
                          'Confirm Settlement',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to finalize your settlement?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                        backgroundColor: Color(0xff1D2125),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(false); // Cancel
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop(true); // Confirm
                            },
                            child: Text(
                              'Yes',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );

                  // If user confirmed, proceed with settlement
                  if (confirm == true) {
                    try {
                      // Set flag before launching settlement intent
                      _isSettlementIntent = true;
                      
                      // Launch settlement intent
                      final result = await IntentService.launchSettlementIntent();
                      
                      if (result.startsWith('Error:')) {
                        _isSettlementIntent = false; // Reset flag on error
                        // Show error message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text(
                              result,
                              style: TextStyle(color: Colors.white, fontSize: 16.sp),
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      _isSettlementIntent = false; // Reset flag on error
                      // Show error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text(
                            'Error performing settlement: $e',
                            style: TextStyle(color: Colors.white, fontSize: 16.sp),
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  }
                },
              ),
              SizedBox(height: 30,),
              ListTile(
                leading: Icon(Icons.print, color: Colors.white),
                title: Text(
                  'REPRINT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context); // Close the bottom sheet
                  String supervisorCode = '';
                  bool codeError = false;
                  final codeAccepted = await showDialog<bool>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setDialogState) => AlertDialog(
                          backgroundColor: AppStyles.backgroundColor,
                          title: const Text('Supervisor Code Required', style: TextStyle(color: Colors.white)),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Please enter your 4 digit supervisor code to access reprints.', style: TextStyle(color: Colors.white)),
                                const SizedBox(height: 12),
                                TextField(
                                  autofocus: true,
                                  obscureText: true,
                                  maxLength: 4,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: 'Supervisor Code',
                                    hintStyle: const TextStyle(color: Colors.white54),
                                    errorText: codeError ? 'Incorrect code' : null,
                                  ),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      supervisorCode = value;
                                      codeError = false;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                            ),
                            TextButton(
                              onPressed: () {
                                if (supervisorCode == (widget.ordersDTO.data?.branch?['kaching_pass']?.toString() ?? '')) {
                                  Navigator.of(context).pop(true);
                                } else {
                                  setDialogState(() {
                                    codeError = true;
                                  });
                                }
                              },
                              child: const Text('Okay', style: TextStyle(color: Color(0xFF199D36))),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                  if (codeAccepted == true) {
                    _showReprintDialog();
                  }
                },
              ),
              SizedBox(height: 10,),
              ListTile(
                leading: Icon(Icons.list_alt, color: Colors.white),
                title: Text(
                  'TRANSACTIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _showTransactionsDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReprintDialog() async {
    final transactions = await SecureStorageService.getTransactions();
    final reprintedTransIds = Set<String>.from(await SecureStorageService.getReprintedTransactionIds());
    const int pageSize = 20;
    int currentPage = 1;
    String searchQuery = '';

    List<Map<String, dynamic>> getFilteredTransactions() {
      if (searchQuery.isEmpty) return transactions;
      return transactions
          .where((t) => t['total']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
          .toList();
    }

    List<Map<String, dynamic>> getCurrentPageTransactions() {
      final filteredTransactions = getFilteredTransactions();
      final start = (currentPage - 1) * pageSize;
      final end = (start + pageSize) > filteredTransactions.length
          ? filteredTransactions.length
          : (start + pageSize);
      return filteredTransactions.sublist(start, end);
    }

    int getTotalPages() {
      return (getFilteredTransactions().length / pageSize).ceil();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppStyles.backgroundColor,
              insetPadding: EdgeInsets.zero,
              child: Scaffold(
                backgroundColor: AppStyles.backgroundColor,
                appBar: AppBar(
                  backgroundColor: const Color(0xff1D2125),
                  title: const Text('Reprint', style: TextStyle(color: Colors.white)),
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                body: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10.w),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by amount (e.g., 100.00)',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          filled: true,
                          fillColor: const Color(0xff2a2a2a),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                            currentPage = 1; // Reset to first page on search
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: getFilteredTransactions().isEmpty
                          ? Center(child: Text(searchQuery.isEmpty ? 'No recent transactions found.' : 'No transactions match your search.', style: TextStyle(color: Colors.white)))
                          : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: getCurrentPageTransactions().length,
                              itemBuilder: (context, index) {
                                final transaction = getCurrentPageTransactions()[index];
                                final isApproved = transaction['status'] == '00';
                                final amount = transaction['total']?.toString() ?? 'R0.00';
                                final transId = transaction['transId']?.toString() ?? 'N/A';
                                final dateTime = transaction['transDate']?.toString() ?? 'Unknown Date';
                                final isReprinted = reprintedTransIds.contains(transId);

                                return Opacity(
                                  opacity: isReprinted ? 0.4 : 1.0,
                                  child: Card(
                                    color: const Color(0xff2a2a2a),
                                    margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                    child: ListTile(
                                      title: Text(
                                        '$transId - $amount',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
                                      ),
                                      subtitle: Text(
                                        dateTime,
                                        style: TextStyle(color: Colors.grey[400], fontSize: 10.sp),
                                      ),
                                      trailing: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                isApproved ? 'APPROVED' : 'DECLINED',
                                                style: TextStyle(
                                                  color: isApproved ? Colors.greenAccent : Colors.redAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 10.sp,
                                                ),
                                              ),
                                              SizedBox(width: 5.w),
                                              const Icon(Icons.print, color: Colors.white),
                                            ],
                                          ),
                                          if ((transaction['items'] is List && (transaction['items'] as List).isNotEmpty))
                                            ...((transaction['items'] as List)
                                                .where((item) => item.toString().startsWith('Fuel:'))
                                                .map((fuelItem) => Padding(
                                              padding: EdgeInsets.only(top: 2.h),
                                              child: Text(
                                                fuelItem.toString(),
                                                style: TextStyle(color: Colors.amberAccent, fontSize: 10.sp),
                                              ),
                                            ))
                                                .toList()),
                                        ],
                                      ),
                                      onTap: () async {
                                        if (isPrinting) return;
                                        setState(() { isPrinting = true; });
                                        if (isReprinted) {
                                          String supervisorCode = '';
                                          bool codeError = false;
                                          final codeAccepted = await showDialog<bool>(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) {
                                              return StatefulBuilder(
                                                builder: (context, setDialogState) => AlertDialog(
                                                  backgroundColor: AppStyles.backgroundColor,
                                                  title: const Text('Supervisor Code Required', style: TextStyle(color: Colors.white)),
                                                  content: SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Text('Please enter your 4 digit supervisor code to reprint this transaction.', style: TextStyle(color: Colors.white)),
                                                        const SizedBox(height: 12),
                                                        TextField(
                                                          autofocus: true,
                                                          obscureText: true,
                                                          maxLength: 4,
                                                          keyboardType: TextInputType.number,
                                                          style: const TextStyle(color: Colors.white),
                                                          decoration: InputDecoration(
                                                            counterText: '',
                                                            hintText: 'Supervisor Code',
                                                            hintStyle: const TextStyle(color: Colors.white54),
                                                            errorText: codeError ? 'Incorrect code' : null,
                                                          ),
                                                          onChanged: (value) {
                                                            setDialogState(() {
                                                              supervisorCode = value;
                                                              codeError = false;
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.of(context).pop(false),
                                                      child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        if (supervisorCode == (widget.ordersDTO.data?.branch?['kaching_pass']?.toString() ?? '')) {
                                                          Navigator.of(context).pop(true);
                                                        } else {
                                                          setDialogState(() {
                                                            codeError = true;
                                                          });
                                                        }
                                                      },
                                                      child: const Text('Okay', style: TextStyle(color: Color(0xFF199D36))),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                          if (codeAccepted != true) { setState(() { isPrinting = false; }); return; }
                                        }
                                        // Normal reprint flow
                                        final reprintMerchant = await showDialog<bool>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: AppStyles.backgroundColor,
                                            title: const Text('Reprint Merchant Copy?', style: TextStyle(color: Colors.white)),
                                            content: const Text('Do you want to reprint the Merchant Copy?', style: TextStyle(color: Colors.white)),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('No', style: TextStyle(color: Colors.white)),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: const Text('Yes', style: TextStyle(color: Color(0xFF199D36))),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (reprintMerchant == true) {
                                          final slipData = Map<String, dynamic>.from(transaction);
                                          slipData['copyType'] = 'MERCHANT COPY';
                                          slipData['duplicateCopy'] = true;
                                          await PrinterService.printCustomSlip(slipData);
                                          final printerStatus = await PrinterService.checkPrinterStatus(context);
                                          if (printerStatus == 'out_of_paper') { setState(() { isPrinting = false; }); return; }
                                          await SecureStorageService.addReprintedTransactionId(transId);
                                          setState(() {
                                            reprintedTransIds.add(transId);
                                          });
                                          if (printerStatus == 'out_of_paper') { setState(() { isPrinting = false; }); return; }
                                          final reprintCustomer = await showDialog<bool>(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: AppStyles.backgroundColor,
                                              title: const Text('Reprint Customer Copy?', style: TextStyle(color: Colors.white)),
                                              content: const Text('Do you want to reprint the Customer Copy?', style: TextStyle(color: Colors.white)),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('No', style: TextStyle(color: Colors.white)),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  child: const Text('Yes', style: TextStyle(color: Color(0xFF199D36))),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (reprintCustomer == true) {
                                            final customerSlipData = Map<String, dynamic>.from(transaction);
                                            customerSlipData['copyType'] = 'CUSTOMER COPY';
                                            customerSlipData['duplicateCopy'] = true;
                                            await PrinterService.printCustomSlip(customerSlipData);
                                          }
                                        }
                                        setState(() { isPrinting = false; });
                                        return;
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (getTotalPages() > 1)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(getTotalPages(), (i) {
                                  final page = i + 1;
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: currentPage == page ? const Color(0xFF199D36) : Colors.transparent,
                                        side: BorderSide(color: Colors.white24),
                                        minimumSize: Size(36.w, 36.h),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          currentPage = page;
                                        });
                                      },
                                      child: Text(
                                        page.toString(),
                                        style: TextStyle(
                                          color: currentPage == page ? Colors.white : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTransactionsDialog() async {
    final transactions = await SecureStorageService.getTransactions();
    const int pageSize = 20;
    int currentPage = 1;
    String searchQuery = '';

    List<Map<String, dynamic>> getFilteredTransactions() {
      if (searchQuery.isEmpty) return transactions;
      return transactions
          .where((t) => t['total']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
          .toList();
    }

    List<Map<String, dynamic>> getCurrentPageTransactions() {
      final filteredTransactions = getFilteredTransactions();
      final start = (currentPage - 1) * pageSize;
      final end = (start + pageSize) > filteredTransactions.length
          ? filteredTransactions.length
          : (start + pageSize);
      return filteredTransactions.sublist(start, end);
    }

    int getTotalPages() {
      return (getFilteredTransactions().length / pageSize).ceil();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: AppStyles.backgroundColor,
              insetPadding: EdgeInsets.zero,
              child: Scaffold(
                backgroundColor: AppStyles.backgroundColor,
                appBar: AppBar(
                  backgroundColor: const Color(0xff1D2125),
                  title: const Text('Transactions', style: TextStyle(color: Colors.white)),
                  leading: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                body: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10.w),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by amount (e.g., 100.00)',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          filled: true,
                          fillColor: const Color(0xff2a2a2a),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                            currentPage = 1; // Reset to first page on search
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: getFilteredTransactions().isEmpty
                          ? const Center(child: Text('No transactions found.', style: TextStyle(color: Colors.white)))
                          : Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: getCurrentPageTransactions().length,
                              itemBuilder: (context, index) {
                                final transaction = getCurrentPageTransactions()[index];
                                final isApproved = transaction['status'] == '00';
                                final amount = transaction['total']?.toString() ?? 'R0.00';
                                final transId = transaction['transId']?.toString() ?? 'N/A';
                                final dateTime = transaction['transDate']?.toString() ?? 'Unknown Date';
                                return Card(
                                  color: const Color(0xff2a2a2a),
                                  margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Purchase',
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                dateTime,
                                                style: TextStyle(color: Colors.grey[400], fontSize: 12.sp),
                                              ),
                                              if ((transaction['items'] is List && (transaction['items'] as List).isNotEmpty))
                                                ...((transaction['items'] as List)
                                                    .where((item) => item.toString().startsWith('Fuel:'))
                                                    .map((fuelItem) => Padding(
                                                  padding: EdgeInsets.only(top: 2.h),
                                                  child: Text(
                                                    fuelItem.toString(),
                                                    style: TextStyle(color: Colors.amberAccent, fontSize: 12.sp),
                                                  ),
                                                ))
                                                    .toList()),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              amount,
                                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
                                            ),
                                            SizedBox(height: 4.h),
                                            Text(
                                              isApproved ? 'APPROVED' : 'DECLINED',
                                              style: TextStyle(
                                                color: isApproved ? Colors.greenAccent : Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (getTotalPages() > 1)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(getTotalPages(), (i) {
                                  final page = i + 1;
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: currentPage == page ? const Color(0xFF199D36) : Colors.transparent,
                                        side: BorderSide(color: Colors.white24),
                                        minimumSize: Size(36.w, 36.h),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          currentPage = page;
                                        });
                                      },
                                      child: Text(
                                        page.toString(),
                                        style: TextStyle(
                                          color: currentPage == page ? Colors.white : Colors.white70,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _checkSettlementResult() async {
    try {
      debugPrint("Checking settlement result...");
      String settlementResult = await IntentService.checkSettlementResult();
      debugPrint("Settlement result: $settlementResult");
      String settlementResultCode = await IntentService.checkSettlementResultCode();

      String settlementData = await IntentService.checkSettlementResultData();
      debugPrint("Settlement data: $settlementData");

      if (settlementResultCode == "00") {
        try {
          // Parse settlement data
          debugPrint("Raw settlement data: $settlementData");
          var data = jsonDecode(settlementData);
          debugPrint("Parsed settlement data: $data");
          debugPrint("Data type: ${data.runtimeType}");

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF199D36),
                content: Text(
                  'Settlement completed successfully',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          debugPrint("Error processing settlement: $e");
          if (e.toString().contains("Printer is out of paper")) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Printer Error'),
                  content: Text('The printer is out of paper. Please replace the paper and try again.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text(
                    'Error processing settlement: $e',
                    style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  ),
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
      } else if (settlementResultCode == "K019") {
        // Show specific message for K019 error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text(
                'K019 No data to be settled',
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Show error message for other error codes
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text(
                'Settlement failed: ${jsonDecode(settlementData)['resultMsg'] ?? 'Unknown error'}',
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error checking settlement result: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'Error checking settlement result: $e',
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
