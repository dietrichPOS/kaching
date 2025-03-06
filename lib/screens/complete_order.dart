import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kaching/models/orders.dart';
import 'package:kaching/screens/select_order.dart';
import 'package:kaching/screens/user_number.dart';
import 'package:kaching/services/intent_service.dart';
import 'package:kaching/services/logging_service.dart';
import 'package:kaching/styles/app_styles.dart';
import 'package:kaching/widgets/number_entry_grid.dart';
import 'package:kaching/services/web_service.dart';
import 'package:focus_detector/focus_detector.dart';

class CompleteOrderPage extends StatefulWidget {
  const CompleteOrderPage(
      {required Key key,
      required this.ordersDTO,
      required this.selectedOrderIndex})
      : super(key: key);

  final OrdersDto ordersDTO;
  final int selectedOrderIndex;

  @override
  createState() => _CompleteOrderPageState();
}

class _CompleteOrderPageState extends State<CompleteOrderPage> {
  late List<Order> orders = [];
  //late int selectedIndex = -1;

  String orderNoJson = "-1";
  String totalAmountJson = "00";

  String userNumber = "";
  String displayNumber = "____";
  String typedDigit = "";
  bool shakeActive = false;

  bool isInTipMode = false;
  bool isInTotalMode = true;
  bool canPayNow = false;
  bool isInPaymentMode = false;

  String paymentStatus = '';

  bool alternatePaymentMethodsAllowed = false;

  String tipAmountString = '0';
  String totalAmountString = '0';

  String calculatedTipAmountString = '0';
  String calculatedTotalAmountString = '0';

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();
    loadData();
  }

  loadData() async {
    debugPrint(widget.ordersDTO.data!.userNo.toString());

    orders.clear();
    if (widget.ordersDTO.data!.orders != null) {
      orders.addAll(widget.ordersDTO.data!.orders!);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();

    return Container(
      constraints: const BoxConstraints.expand(),
      child: FocusDetector(
        onForegroundGained: () async {
          debugPrint('----Foreground Gained');

          String paymentResult = await IntentService.checkAddpayResult();
          String paymentResultCode =
              await IntentService.checkAddpayResultCode();
          String paymentResultMessage =
              await IntentService.checkAddpayResultMessage();
          String paymentResultData =
              await IntentService.checkAddpayResultData();

          //For testing only
          //paymentResultCode = '00';
          //paymentResultData =
          //    '{"refNo":"201504002012","batchNo":"000002","authCode":"745350","transTime":"09:29:50","traceNo":"000011","amt":"000000043272","cardNo":"448008******8034","businessOrderNo":"6","paymentScenario":"CARD","transDate":"2024-06-05","respCode":"00"}';

          LoggingService.logInformation(
              'Foreground gained - payment result: $paymentResult');
          LoggingService.logInformation(
              'Foreground gained - payment result code: $paymentResultCode');
          LoggingService.logInformation(
              'Foreground gained - payment result message: $paymentResultMessage');
          LoggingService.logInformation(
              'Foreground gained - payment result data: $paymentResultData');

          if (paymentResultCode != '00') {
            final scaffoldContext = context;
            ScaffoldMessenger.of(scaffoldContext).showSnackBar(
              SnackBar(
                duration: const Duration(milliseconds: 7500),
                backgroundColor: Colors.redAccent,
                content: Text(
                  paymentResultMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          } else {
            //Payment ResultCode is 00 - Payment has been processed
            final scaffoldContext = context;
            ScaffoldMessenger.of(scaffoldContext).showSnackBar(const SnackBar(
              duration: Duration(milliseconds: 2000),
              backgroundColor: Color(0xFF199D36),
              content: Text(
                'Payment successful',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ));

            bool paymentSuccess = false;

            try {
              await WebService.finalizeOrder(
                  orders[widget.selectedOrderIndex].orderNo.toString(),
                  widget.ordersDTO.data!.userNo.toString(),
                  paymentResultData);
              paymentSuccess = true;
            } on Exception catch (e) {
              LoggingService.logInformation(
                  'Error finalizing order: ${e.toString()}');
              showDialog(
                // ignore: use_build_context_synchronously
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Error Finalizing'),
                    content: Text('Exception: $e'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (context.mounted) {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UserNumberPage(key: UniqueKey()),
                                ));
                          }
                        },
                      ),
                    ],
                  );
                },
              );
            }

            //Finalize Transaction
            if (paymentSuccess) {
              Future.delayed(const Duration(milliseconds: 3000), () {
                if (context.mounted) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserNumberPage(key: UniqueKey()),
                      ));
                }
              });
            }
          }
          //Payment OK
        },
        child: SafeArea(
          child: Scaffold(
            backgroundColor: AppStyles.backgroundColor,
            body: Column(
              children: [
                Container(
                    color: Color(0xff1D2125),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(8, 5, 5, 5).h,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                backgroundColor: const Color(0x00000000),
                                side: const BorderSide(
                                    width: 1.0,
                                    color: Color.fromARGB(255, 100, 101, 99))),
                            onPressed: () {
                              // if (!hasChangedCourse) {
                              Navigator.pop(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SelectOrderPage(
                                      key: UniqueKey(),
                                      ordersDTO: widget.ordersDTO,
                                    ),
                                  ));
                            },
                            child: Container(
                              alignment: Alignment.center,
                              height: 22.h,
                              width: 45.w,
                              child: Text(
                                'BACK',
                                style: TextStyle(
                                    color:
                                        const Color.fromARGB(255, 100, 101, 99),
                                    fontSize: 12.sp,
                                    //fontFamily: 'Roboto',
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 0, 10, 0).h,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 0, 0, 0).h,
                                child: Text(
                                  textAlign: TextAlign.end,
                                  '${widget.ordersDTO.data!.userName.toString()} ${widget.ordersDTO.data!.userNo.toString()} | ${widget.ordersDTO.data!.orders![widget.selectedOrderIndex].name.toString()}',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0,
                                      fontSize: 16.sp),
                                  //   ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    )),

                const Divider(
                  height: 1,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0).h,
                    child: InkWell(
                      onTap: () {
                        debugPrint("Tapped on Bill Container");
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        color: const Color(0xff212121),
                        height: 100.0,
                        padding: const EdgeInsets.fromLTRB(15, 1, 10, 1).h,
                        child: Row(
                          children: [
                            Container(
                              height: 22.h,
                              padding: const EdgeInsets.fromLTRB(0, 1, 0, 0),
                              color: AppStyles.backgroundColor,
                              child: Image.asset("assets/images/whitelock.png"),
                            ),
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 5, 5, 1).h,
                              child: Text(
                                'BILL',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0,
                                    fontSize: 20.sp),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 5, 5, 1).h,
                              child: Text(
                                widget.ordersDTO.data!
                                    .orders![widget.selectedOrderIndex].total!
                                    .toString(),
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: Colors.white,
                                    //fontFamily: 'RobotoCondensed',
                                    //fontWeight: FontWeight.w500,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0,
                                    fontSize: 20.sp),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: false,
                  child: Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0).h,
                      child: InkWell(
                        onTap: () {
                          debugPrint("Tapped on Tip Container");
                          if (!isInPaymentMode) {
                            setState(() {
                              isInTipMode = true;
                              isInTotalMode = false;
                            });
                          }
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          color: AppStyles.backgroundColor,
                          height: 100.0,
                          padding: const EdgeInsets.fromLTRB(15, 1, 10, 1).h,
                          child: Row(
                            children: [
                              Opacity(
                                  opacity:
                                      (isInTipMode || isInTotalMode) ? 1 : 0,
                                  child: Container(
                                    height: 22.h,
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 1, 0, 0),
                                    color: AppStyles.backgroundColor,
                                    child: Image.asset(isInTipMode
                                        ? "assets/images/whitehand.png"
                                        : "assets/images/whitecalc.png"),
                                  )),
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 5, 5, 1).h,
                                child: Text(
                                  'TIP',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0,
                                      fontSize: 20.sp),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding:
                                    const EdgeInsets.fromLTRB(10, 5, 5, 1).h,
                                child: Text(
                                  isInTipMode
                                      ? double.parse(tipAmountString)
                                          .toStringAsFixed(2)
                                      : double.parse(calculatedTipAmountString)
                                          .toStringAsFixed(2),
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0,
                                      fontSize: 20.sp),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(
                  color: Colors.white70,
                  height: 1,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0).h,
                    child: InkWell(
                      onTap: () {
                        debugPrint("Tapped on Total Amount Container");
                        if (!isInPaymentMode) {
                          setState(() {
                            isInTipMode = false;
                            isInTotalMode = true;
                          });
                        }
                      },
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        color: AppStyles.backgroundColor,
                        height: 100.0,
                        padding: const EdgeInsets.fromLTRB(15, 1, 10, 1).h,
                        child: Row(
                          children: [
                            Opacity(
                              opacity: (isInTipMode || isInTotalMode) ? 1 : 0,
                              child: Container(
                                height: 22.h,
                                padding: const EdgeInsets.fromLTRB(0, 1, 0, 0),
                                color: AppStyles.backgroundColor,
                                child: Image.asset(isInTotalMode
                                    ? "assets/images/whitehand.png"
                                    : "assets/images/whitecalc.png"),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 5, 5, 1).h,
                              child: Text(
                                'TOTAL AMOUNT',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0,
                                    fontSize: 20.sp),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.fromLTRB(10, 5, 5, 1).h,
                              child: Text(
                                isInTotalMode
                                    ? '${double.parse(totalAmountString).toStringAsFixed(2)}'
                                    : '${double.parse(calculatedTotalAmountString).toStringAsFixed(2)}',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0,
                                    fontSize: 20.sp),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const Divider(
                  color: Colors.white70,
                  height: 1,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0).h,
                    child: isInPaymentMode
                        ? Container(
                            width: MediaQuery.of(context).size.width,
                            color: const Color(0xffededed),
                            height: 100.0,
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0.5).h,
                            child: Center(
                              child: Text(
                                'CHOOSE A PAYMENT METHOD',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.black45,
                                    fontSize: 16.sp,
                                    //fontFamily: 'Roboto',
                                    letterSpacing: 0,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          )
                        : Container(
                            width: MediaQuery.of(context).size.width,
                            color: const Color(0xffededed),
                            height: 100.0,
                            padding: const EdgeInsets.fromLTRB(0, 0, 0, 0.5).h,
                            child: Opacity(
                              opacity: canPayNow ? 1 : 0.5,
                              child: OutlinedButton(
                                onPressed: () {
                                  if (canPayNow) {
                                    setState(() {
                                      isInPaymentMode = true;
                                    });
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(2.0),
                                    ),
                                    backgroundColor: const Color(0xFF199D36)),
                                child: Text(
                                  'PROCEED WITH PAYMENT',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      //fontFamily: 'Roboto',
                                      letterSpacing: 0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )),
                  ),
                ),
                const Divider(
                  height: 1,
                ),
                SizedBox(
                    height: MediaQuery.of(context).size.width,
                    child: isInPaymentMode
                        ? Container(
                            child: Column(
                            children: [
                              InkWell(
                                onTap: () async {
                                  debugPrint(
                                      "Tapped on Pay with Card Container");

                                  orderNoJson =
                                      orders[widget.selectedOrderIndex]
                                          .orderNo!
                                          .toString();
                                  totalAmountJson =
                                      double.parse(totalAmountString)
                                          .toStringAsFixed(2)
                                          .replaceAll('.', '');

                                  String jsonString =
                                      "{\"businessOrderNo\":\"$orderNoJson\",\"paymentScenario\":\"CARD\",\"amt\":\"$totalAmountJson\"}";
                                  LoggingService.logInformation(
                                      'Payment Request: $jsonString');
                                  
                                  await IntentService.launchAddpayIntent(
                                      jsonString);
                                  
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  //color: const Color(0xffD8D8D8),
                                  color: AppStyles.lightBackgroundColor,
                                  height: 85.0,
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 10, 10, 0)
                                          .h,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: const Color(0xffededed),
                                        border:
                                            Border.all(color: Colors.black)),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.fromLTRB(
                                                  20, 5, 5, 5)
                                              .h,
                                          child: Text(
                                            'DEBIT / CREDIT CARD',
                                            textAlign: TextAlign.end,
                                            style: TextStyle(
                                                color: const Color(0xff383f48),
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0,
                                                fontSize: 18.sp),
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          height: 64.h,
                                          padding: const EdgeInsets.fromLTRB(
                                              8, 8, 14, 8),
                                          child: Image.asset(
                                              "assets/images/pmdccard.png"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  debugPrint("Tapped on Bill Container");
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  color: AppStyles.lightBackgroundColor,
                                  height: 90.0,
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 5, 10, 0).h,
                                  child: Opacity(
                                    opacity: alternatePaymentMethodsAllowed
                                        ? 1
                                        : 0.1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: const Color(0xffededed),
                                          border:
                                              Border.all(color: Colors.black)),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.fromLTRB(
                                                    20, 5, 5, 5)
                                                .h,
                                            child: Text(
                                              'SEND LINK VIA SMS',
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                  color:
                                                      const Color(0xff383f48),
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0,
                                                  fontSize: 18.sp),
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            height: 64.h,
                                            padding: const EdgeInsets.fromLTRB(
                                                8, 8, 14, 8),
                                            child: Image.asset(
                                                "assets/images/pmsms.png"),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  debugPrint("Tapped on Bill Container");
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  color: AppStyles.lightBackgroundColor,
                                  height: 90.0,
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 5, 10, 0).h,
                                  child: Opacity(
                                    opacity: alternatePaymentMethodsAllowed
                                        ? 1
                                        : 0.1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: const Color(0xffededed),
                                          border:
                                              Border.all(color: Colors.black)),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.fromLTRB(
                                                    20, 5, 5, 5)
                                                .h,
                                            child: Text(
                                              'SEND LINK VIA EMAIL',
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                  color:
                                                      const Color(0xff383f48),
                                                  //fontFamily: 'RobotoCondensed',
                                                  //fontWeight: FontWeight.w500,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0,
                                                  fontSize: 18.sp),
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            height: 64.h,
                                            padding: const EdgeInsets.fromLTRB(
                                                8, 8, 14, 8),
                                            child: Image.asset(
                                                "assets/images/pmemail.png"),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  debugPrint("Tapped on Bill Container");
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  color: AppStyles.lightBackgroundColor,
                                  height: 90.0,
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 5, 10, 10)
                                          .h,
                                  child: Opacity(
                                    opacity: alternatePaymentMethodsAllowed
                                        ? 1
                                        : 0.1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: const Color(0xffededed),
                                          border:
                                              Border.all(color: Colors.black)),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.fromLTRB(
                                                    20, 5, 5, 5)
                                                .h,
                                            child: Text(
                                              'SEND LINK VIA WHATSAPP',
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                  color:
                                                      const Color(0xff383f48),
                                                  //fontFamily: 'RobotoCondensed',
                                                  //fontWeight: FontWeight.w500,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0,
                                                  fontSize: 18.sp),
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            height: 64.h,
                                            padding: const EdgeInsets.fromLTRB(
                                                8, 8, 14, 8),
                                            //color: AppStyles.backgroundColor,
                                            child: Image.asset(
                                                "assets/images/pmwhatsapp.png"),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ))
                        : NumberEntryGridWidget(
                            key: UniqueKey(),
                            onChanged: (value) async {
                              typedDigit = value;
                              debugPrint("Typed digit: $typedDigit");

                              if (typedDigit == 'OK' && canPayNow) {
                                setState(() {
                                  isInPaymentMode = true;
                                  return;
                                });
                              }

                              if (typedDigit != "BACK" &&
                                  //typedDigit != '.' &&
                                  typedDigit != 'OK' &&
                                  typedDigit != '00') {
                                setState(() {
                                  if (isInTipMode) {
                                    if (typedDigit == '.' &&
                                        !tipAmountString.contains('.')) {
                                      tipAmountString =
                                          tipAmountString + typedDigit;
                                    } else {
                                      tipAmountString =
                                          tipAmountString + typedDigit;
                                    }

                                    totalAmountString = '0';
                                    calculatedTipAmountString = "0";
                                  }

                                  if (isInTotalMode) {
                                    if (typedDigit == '.' &&
                                        !totalAmountString.contains('.')) {
                                      totalAmountString =
                                          totalAmountString + typedDigit;
                                    } else {
                                      totalAmountString =
                                          totalAmountString + typedDigit;
                                    }

                                    tipAmountString = '0';
                                    calculatedTipAmountString = "0";
                                  }
                                });
                              }

                              if (typedDigit == 'BACK' && isInTipMode) {
                                if (tipAmountString != '0') {
                                  setState(() {
                                    tipAmountString = tipAmountString.substring(
                                        0, tipAmountString.length - 1);
                                    if (tipAmountString == '') {
                                      tipAmountString = '0';
                                    }
                                  });
                                }
                              }

                              if (typedDigit == 'BACK' && isInTotalMode) {
                                if (totalAmountString != '0') {
                                  setState(() {
                                    totalAmountString =
                                        totalAmountString.substring(
                                            0, totalAmountString.length - 1);
                                    if (totalAmountString == '') {
                                      totalAmountString = '0';
                                    }
                                  });
                                }
                              }

                              if (isInTipMode) {
                                double totalNeeded = widget.ordersDTO.data!
                                    .orders![widget.selectedOrderIndex].total!
                                    .toDouble();
                                double tipAmount =
                                    double.parse(tipAmountString);
                                double totalAmount = totalNeeded + tipAmount;
                                calculatedTotalAmountString =
                                    totalAmount.toString();
                              }

                              if (isInTotalMode) {
                                try {
                                  double totalNeeded = widget.ordersDTO.data!
                                      .orders![widget.selectedOrderIndex].total!
                                      .toDouble();

                                  double currentTotalAmount =
                                      double.parse(totalAmountString);

                                  if (currentTotalAmount > totalNeeded) {
                                    calculatedTipAmountString =
                                        (currentTotalAmount - totalNeeded)
                                            .toString();
                                  } else {
                                    calculatedTipAmountString = '0';
                                  }
                                } catch (e) {
                                  debugPrint("Error: $e");
                                }
                              }

                              double totalNeeded = widget.ordersDTO.data!
                                  .orders![widget.selectedOrderIndex].total!
                                  .toDouble();

                              double currentTotalAmount = 0;

                              if (isInTotalMode) {
                                currentTotalAmount =
                                    double.parse(totalAmountString);
                              } else {
                                currentTotalAmount =
                                    double.parse(calculatedTotalAmountString);
                              }

                              if (currentTotalAmount >= totalNeeded) {
                                canPayNow = true;
                              } else {
                                canPayNow = false;
                              }

                              if (userNumber.length == 4) {
                                //Check user number
                                final resp =
                                    await WebService.fetchOrders(userNumber);

                                debugPrint("Response:${resp.body}");

                                if (resp.statusCode == 200) {
                                  final ordersDTO =
                                      ordersDtoFromJson(resp.body);
                                  if (ordersDTO.data == null) {
                                    debugPrint('Data is null, user not found?');

                                    setState(() {
                                      shakeActive = true;
                                    });

                                    final scaffoldContext = context;
                                    //Future.delayed(const Duration(milliseconds: 500), () {
                                    ScaffoldMessenger.of(scaffoldContext)
                                        .showSnackBar(
                                      const SnackBar(
                                        duration: Duration(milliseconds: 1000),
                                        backgroundColor: Colors.blueGrey,
                                        content: Text(
                                          'User not found',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      //);
                                    );

                                    Future.delayed(
                                        const Duration(milliseconds: 500), () {
                                      setState(() {
                                        shakeActive = false;
                                        userNumber = "";
                                        displayNumber = "____";
                                        typedDigit = "";
                                      });
                                    });
                                  } else {
                                    if (context.mounted) {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                SelectOrderPage(
                                                    key: UniqueKey(),
                                                    ordersDTO: ordersDTO),
                                          ));
                                    }
                                  }
                                }
                              }
                            },
                          ))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
