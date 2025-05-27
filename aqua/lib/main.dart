import 'package:aqua/NavBar/Notification.dart';
import 'package:aqua/pages/Admin/AdminDashboard.dart';
import 'package:aqua/pages/Details.dart';
import 'package:aqua/pages/ForgotPassword/OTP.dart';
import 'package:aqua/pages/LandingPage.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/pages/SAdmin/SAdminDashboard.dart';
import 'package:aqua/pages/Signup.dart';
import 'package:aqua/pages/User/UserDashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aqua/pages/Theme_Provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.purple,
        colorScheme: ColorScheme.light(
          background: Colors.white,
          primary: Colors.purple,
          secondary: Colors.purpleAccent,
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
        primaryColor: Colors.purple,
        colorScheme: ColorScheme.dark(
          background: Colors.black,
          primary: Colors.purple,
          secondary: Colors.purpleAccent,
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
      home: OTPScreen(),
    );
  }
}
