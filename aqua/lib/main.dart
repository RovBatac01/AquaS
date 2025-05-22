import 'package:aqua/pages/Admin/AdminDashboard.dart';
import 'package:aqua/pages/Admin/AdminDetails.dart';
import 'package:aqua/pages/ForgotPassword/ConfirmPassword.dart';
import 'package:aqua/pages/ForgotPassword/ForgotPass.dart';
import 'package:aqua/pages/ForgotPassword/OTP.dart';
import 'package:aqua/pages/LandingPage.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/pages/SAdmin/AddAccount.dart';
import 'package:aqua/pages/SAdmin/SAdminDashboard.dart';
import 'package:aqua/pages/SAdmin/SAdminHome.dart';
import 'package:aqua/pages/Signup.dart';
import 'package:aqua/pages/User/UserDashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aqua/pages/Theme_Provider.dart';
import 'package:aqua/components/colors.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => ThemeProvider(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: themeProvider.themeMode,
      home: LandingPage(),
    );
  }
}
