import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kaching/models/register.dart';
import 'package:kaching/screens/user_number.dart';
import 'package:kaching/services/logging_service.dart';
import 'package:kaching/services/registration_service.dart';
import 'package:kaching/services/secure_storage_service.dart';
import 'package:kaching/services/web_service.dart';
import 'package:kaching/styles/app_styles.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DeviceRegistrationPage extends StatefulWidget {
  const DeviceRegistrationPage({super.key});

  @override
  createState() => _DeviceRegistrationPageState();
}

class _DeviceRegistrationPageState extends State<DeviceRegistrationPage> {
  String serverIP = '';
  String serverPort = '';
  String deviceID = '';
  String deviceStatus = '---';
  String appVersion = '';
  String buildNumber = '';
  String buttonText = 'REGISTER DEVICE';

  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  bool isError = false;
  bool isLoaderShowing = false;

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();
    loadData();
  }

  Future<void> _initPackageInfo() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  loadData() async {
    await _initPackageInfo();
    serverIP = await SecureStorageService.fetchIpOrUrl();
    serverPort = await SecureStorageService.fetchPort();

    String _deviceID = await RegistrationService.getDeviceID();
    setState(() {
      appVersion = _packageInfo.version;
      buildNumber = _packageInfo.buildNumber;
      deviceID = _deviceID;
    });

    await LoggingService.logInformation("KC Device ID: $deviceID");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow resizing when keyboard appears
      backgroundColor: AppStyles.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
              color: AppStyles.backgroundColor,
              child: Image.asset("assets/images/kachingtopdarker.png"),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(30, 20, 30, 30).h,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    width: 350.w,
                    padding: const EdgeInsets.all(25).h,
                    decoration: BoxDecoration(
                      border: Border.all(
                          width: 1, color: Colors.grey.withOpacity(0)),
                      color: Color(0xff20262e).withOpacity(0.8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0).w,
                          child: Text(
                            'DEVICE REGISTRATION',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'BarlowCondensed',
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                              fontSize: 24.sp,
                            ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5).h,
                          child: Text(
                            'Enter the configuration IP and Port below',
                            style: TextStyle(
                              color: Color.fromARGB(255, 182, 182, 182),
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w200,
                              letterSpacing: 0,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 40, 0, 0).h,
                          child: TextField(
                            keyboardType: TextInputType.numberWithOptions(
                                signed: false, decimal: false),
                            controller: TextEditingController(text: serverIP),
                            onChanged: (value) {
                              serverIP = value;
                            },
                            autocorrect: false,
                            enableSuggestions: false,
                            style: AppStyles.textInputStyle,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Color(0xFF353535),
                              labelStyle: AppStyles.textInputStyle,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF353535), width: 0.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                BorderSide(color: Colors.white, width: 0.0),
                              ),
                              border: OutlineInputBorder(),
                              labelText: 'IP Address',
                              hintStyle: TextStyle(color: Color(0x50FFFFFF)),
                              hintText: 'Start typing',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 18, 0, 0).h,
                          child: TextField(
                            keyboardType: TextInputType.numberWithOptions(
                                signed: false, decimal: false),
                            controller: TextEditingController(text: serverPort),
                            onChanged: (value) {
                              serverPort = value;
                            },
                            autocorrect: false,
                            enableSuggestions: false,
                            style: AppStyles.textInputStyle,
                            decoration: const InputDecoration(
                              filled: true,
                              fillColor: Color(0xFF353535),
                              labelStyle: AppStyles.textInputStyle,
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFF353535), width: 0.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                BorderSide(color: Colors.white, width: 0.0),
                              ),
                              border: OutlineInputBorder(),
                              labelText: 'Port',
                              hintStyle: TextStyle(color: Color(0x50FFFFFF)),
                              hintText: 'Start typing',
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 45, 0, 0).h,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              backgroundColor: const Color(0xFF199D36),
                            ),
                            onPressed: () async {
                              await SecureStorageService.storeBaseUrl(
                                  serverIP, serverPort);
                              FocusScopeNode currentFocus =
                              FocusScope.of(context);
                              if (!currentFocus.hasPrimaryFocus) {
                                currentFocus.unfocus();
                              }

                              setState(() {
                                isLoaderShowing = true;
                              });

                              var resp = await WebService.registerDevice();
                              LoggingService.logInformation(
                                  "${resp.statusCode} Device Registration Response: ${resp.body}");

                              if (resp.statusCode == 500) {
                                setState(() {
                                  deviceStatus =
                                  'Device already in use (${resp.statusCode})';
                                });
                                return;
                              }

                              if (resp.statusCode == 200) {
                                RegisterDto registerDto =
                                registerDtoFromJson(resp.body);
                                if (registerDto.success == true) {
                                  if (registerDto.data?.status == 'Pending') {
                                    setState(() {
                                      deviceStatus =
                                      'Registration pending (${resp.statusCode})';
                                      buttonText = 'REFRESH';
                                    });

                                    await SecureStorageService.storeTempToken(
                                        registerDto.data?.apiKey ?? '');
                                    LoggingService.logInformation(
                                        "Storing temp token: ${registerDto.data?.apiKey}");

                                    return;
                                  }

                                  if (registerDto.data?.status == 'Approved') {
                                    setState(() {
                                      deviceStatus =
                                      'Approved (${resp.statusCode})';
                                      buttonText = 'CONTINUE';
                                    });

                                    await SecureStorageService.storeToken(
                                        registerDto.data?.apiKey ?? '');
                                    LoggingService.logInformation(
                                        "Storing token: ${registerDto.data?.apiKey}");

                                    if (context.mounted) {
                                      await Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => UserNumberPage(
                                              key: UniqueKey()),
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                }
                              }

                              setState(() {
                                deviceStatus =
                                'Unknown error (${resp.statusCode})';
                                buttonText = 'REGISTER DEVICE';
                              });
                            },
                            child: Container(
                              alignment: Alignment.center,
                              height: 48.h,
                              child: Text(
                                buttonText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontFamily: 'Roboto',
                                  letterSpacing: 0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20), // Add spacing
                        Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.fromLTRB(0, 5, 0, 0).h,
                          child: Text(
                            'Device ID: $deviceID',
                            style: TextStyle(
                              color: Color.fromARGB(255, 182, 182, 182),
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.fromLTRB(0, 5, 0, 0).h,
                          child: Text(
                            deviceStatus,
                            style: TextStyle(
                              color: Color.fromARGB(255, 182, 182, 182),
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w200,
                              letterSpacing: 0,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.fromLTRB(0, 5, 0, 0).h,
                          child: Text(
                            'App Version: $appVersion ($buildNumber)',
                            style: TextStyle(
                              color: Color.fromARGB(255, 182, 182, 182),
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w200,
                              letterSpacing: 0,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}