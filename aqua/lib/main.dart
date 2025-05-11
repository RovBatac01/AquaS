import 'package:aqua/pages/Admin/AdminDashboard.dart';
import 'package:aqua/NavBar/Details.dart';
import 'package:aqua/pages/LandingPage.dart';
import 'package:aqua/NavBar/Notification.dart';
import 'package:aqua/pages/SAdmin/SAdminDashboard.dart';
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
      theme: ThemeData(
      ),
      home: Admindashboard()
    );
  }
}

