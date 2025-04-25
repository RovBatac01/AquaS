import 'package:aqua/AdminDashboard.dart';
import 'package:aqua/LandingPage.dart';
import 'package:aqua/SAdminDashboard.dart';
import 'package:aqua/UserDashboard.dart';
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

