import 'package:aqua/NavBar/Notification.dart';
import 'package:aqua/NavBar/Settings.dart';
import 'package:aqua/NavBar/Statistics.dart';
import 'package:aqua/pages/Admin/AdminDashboard.dart';
import 'package:aqua/pages/Admin/AdminDetails.dart';
import 'package:aqua/pages/Admin/AdminNotification.dart';
import 'package:aqua/pages/Admin/AdminSettings.dart';
import 'package:aqua/pages/Calendar.dart';
import 'package:aqua/pages/CalibrationRequest.dart';
import 'package:aqua/pages/SAdmin/SAdminHome.dart';
import 'package:aqua/pages/User/UserSettings.dart';

import 'package:aqua/pages/ForgotPassword/ForgotPass.dart';
import 'package:aqua/pages/SAdmin/SAdminDetails.dart';
import 'package:aqua/pages/SAdmin/SAdminNotification.dart';
import 'package:aqua/pages/SAdmin/SAdminSettings.dart';
import 'package:aqua/pages/User/Details.dart';
import 'package:aqua/pages/LandingPage.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/pages/SAdmin/SAdminDashboard.dart';
import 'package:aqua/pages/Signup.dart';
import 'package:aqua/pages/User/UserDashboard.dart';
import 'package:aqua/pages/sample.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aqua/pages/Theme_Provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aqua/components/colors.dart';

void main() {
  runApp(
    ScreenUtilInit(
      designSize: Size(375, 812), // Set to your design's width and height
      minTextAdapt: true,
      builder:
          (context, child) => ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
            child: MyApp(),
          ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: ASColor.BGFourth,
        primaryColor: ASColor.getTextColor(context),
        colorScheme: ColorScheme.light(
          background: ASColor.BGFourth,
          primary: ASColor.getTextColor(context),
          secondary: ASColor.getTextColor(context),
          onBackground: Colors.black,
          onPrimary: Colors.white,
        ),
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.black,
          displayColor: Colors.black,
          fontFamily: 'Poppins',
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: ASColor.getTextColor(context),
        colorScheme: ColorScheme.dark(
          background: Colors.black,
          primary: Colors.white,
          secondary: Colors.white,
          onBackground: Colors.white,
          onPrimary: Colors.white,
        ),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
          fontFamily: 'Poppins',
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: Sadmindashboard(),
    );
  }
}
