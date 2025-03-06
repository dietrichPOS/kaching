import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:kaching/screens/device_registration.dart';
import 'package:kaching/screens/user_number.dart';
import 'package:kaching/services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (await SecureStorageService.fetchToken() != '') {
    runApp(const MyApp(true)); //has token
  } else {
    runApp(const MyApp(false)); //no token yet
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black, // Set status bar color
    statusBarBrightness: Brightness.light, // Set status bar brightness
  ));
}

class MyApp extends StatelessWidget {
  const MyApp(this.hasToken, {super.key});

  final bool hasToken;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: const Size(360, 780),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Kaching',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: hasToken
                ? UserNumberPage(key: UniqueKey())
                : const DeviceRegistrationPage(),
          );
        });
  }
}
