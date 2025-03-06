import 'package:device_info/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kaching/models/orders.dart';
import 'package:kaching/screens/select_order.dart';
import 'package:kaching/services/intent_service.dart';
import 'package:kaching/services/logging_service.dart';
import 'package:kaching/services/registration_service.dart';
import 'package:kaching/styles/app_styles.dart';
import 'package:kaching/widgets/number_entry.dart';
import 'package:kaching/widgets/number_entry_grid.dart';
import 'package:kaching/services/web_service.dart';
import 'package:flutter_shake_animated/flutter_shake_animated.dart';

class UserNumberPage extends StatefulWidget {
  const UserNumberPage({required Key key}) : super(key: key);

  @override
  createState() => _UserNumberPageState();
}

class _UserNumberPageState extends State<UserNumberPage> {
  String userNumber = "";
  String displayNumber = "____";
  String typedDigit = "";
  bool shakeActive = false;

  static const platformChannel = const MethodChannel('yourTestChannel');

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();
    loadData();
  }

  loadData() async {
    await LoggingService.logInformation('KC App started');
    String deviceID = await RegistrationService.getDeviceID();
    debugPrint("[UserNumberPage] Device ID: $deviceID");
  }

  @override
  Widget build(BuildContext context) {
    
    return PopScope(
      canPop: false,
      child: Scaffold(
          backgroundColor: AppStyles.backgroundColor,
          body: Column(children: [
            //Expanded(
            //  flex: 1,
            Container(
              margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
              color: AppStyles.backgroundColor,
              child: Image.asset("assets/images/kachingtopdarker.png"),
              //     ),
            ),
            Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  color: AppStyles.backgroundColor,
                  child: Column(
                    children: [
                      Container(
                        alignment: Alignment.center,
                        padding: EdgeInsets.fromLTRB(50, 20, 50, 5),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Text(
                            'Enter your 4 digit user number',
                            textAlign: TextAlign.center,
                            style: AppStyles.mediumTextStyle,
                          ),
                        ),
                      ),
                      Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                          child: ShakeWidget(
                            duration: Duration(milliseconds: 3000),
                            shakeConstant: ShakeHorizontalConstant2(),
                            autoPlay: shakeActive,
                            enableWebMouseHover: true,
                            child: Text(
                                '${displayNumber[0]} ${displayNumber[1]} ${displayNumber[2]} ${displayNumber[3]}',
                                style: AppStyles.enterPinTextStyle),
                          )),
                    ],
                  ),
                )
                ),

            SizedBox(
                height: MediaQuery.of(context).size.width,
                child: NumberEntryGridWidget(
                  key: UniqueKey(),
                  onChanged: (value) async {
                    typedDigit = value;
                    debugPrint("Typed digit: $typedDigit");

                    if (typedDigit != "BACK" &&
                        typedDigit != '.' &&
                        typedDigit != 'OK' &&
                        typedDigit != '00') {
                      if (userNumber.length < 4) {
                        setState(() {
                          userNumber = userNumber + typedDigit;
                          displayNumber =
                              displayNumber.replaceFirst("_", typedDigit);
                        });
                      }
                    }

                    if (typedDigit == 'BACK') {
                      if (userNumber.length > 0) {
                        setState(() {
                          userNumber =
                              userNumber.substring(0, userNumber.length - 1);
                          displayNumber = '____';
                          displayNumber = displayNumber.replaceRange(
                              0, userNumber.length, userNumber);
                        });
                      }
                    }

                    if (userNumber.length == 4) {
                      //Check user number
                      final resp = await WebService.fetchOrders(userNumber);

                      debugPrint("Response:${resp.body}");
                      if (resp.statusCode == 500) {
                        debugPrint('Internal Server error, User not found?');

                        setState(() {
                          shakeActive = true;
                        });

                        final scaffoldContext = context;
                        //Future.delayed(const Duration(milliseconds: 500), () {
                        ScaffoldMessenger.of(scaffoldContext).showSnackBar(
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

                        Future.delayed(const Duration(milliseconds: 500), () {
                          setState(() {
                            shakeActive = false;
                            userNumber = "";
                            displayNumber = "____";
                            typedDigit = "";
                          });
                        });
                      }

                      if (resp.statusCode == 200) {
                        final ordersDTO = ordersDtoFromJson(resp.body);
                        if (ordersDTO.data == null) {
                          debugPrint('Data is null, user not found?');

                          setState(() {
                            shakeActive = true;
                          });

                          final scaffoldContext = context;
                          ScaffoldMessenger.of(scaffoldContext).showSnackBar(
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
                          );

                          Future.delayed(const Duration(milliseconds: 500), () {
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
                                  builder: (context) => SelectOrderPage(
                                      key: UniqueKey(), ordersDTO: ordersDTO),
                                ));
                          }
                        }
                      }
                    }
                  },
                ))
          ])),
    );
  }
}
