import 'package:aqua/pages/Admin/AdminDashboard.dart';
import 'package:aqua/pages/Details.dart';
import 'package:aqua/pages/ForgotPass.dart';
import 'package:aqua/pages/LandingPage.dart';
import 'package:aqua/NavBar/Notification.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/pages/SAdmin/SAdminAccountManagement.dart';
import 'package:aqua/pages/SAdmin/SAdminDashboard.dart';
import 'package:aqua/pages/Signup.dart';
import 'package:aqua/pages/User/UserDashboard.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData.light(), // 👈 Set light theme
      darkTheme: ThemeData.dark(), // Optional: define dark theme
      themeMode: ThemeMode.light,
      home: LoginScreen()
    );
  }
}
