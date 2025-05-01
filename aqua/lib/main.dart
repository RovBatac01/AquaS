import 'package:aqua/AdminDashboard.dart';
import 'package:aqua/Dashboard.dart';
import 'package:aqua/GaugeMeter.dart';
import 'package:aqua/Home.dart';
import 'package:aqua/components/Details.dart';
import 'package:aqua/bg/Background.dart';
import 'package:aqua/LandingPage.dart';
import 'package:aqua/Login.dart';
import 'package:aqua/meters/DissolvedOxygen.dart';
import 'package:aqua/pages/HomeScreen.dart';
import 'package:aqua/pages/Notification.dart';
import 'package:aqua/pages/SAdminAccountManagement.dart';
import 'package:aqua/pages/SAdminDashboard.dart';
import 'package:aqua/pages/Statistics.dart';
import 'package:aqua/UserDashboard.dart';
import 'package:aqua/components/navbar.dart';
import 'package:aqua/components/navbar.dart';
import 'package:flutter/material.dart';
import 'colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget { // Changed to StatefulWidget
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<ThemeMode> _themeNotifier =
      ValueNotifier(ThemeMode.light); // Initialize with light mode

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (_, currentTheme, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Flutter Demo',
          theme: ThemeData.light(), // Define your light theme
          darkTheme: ThemeData.dark(), // Define your dark theme
          themeMode: currentTheme, // Set the current theme based on the notifier
          home: BottomNavigationBarWidget(
              themeNotifier: _themeNotifier), // Pass the notifier
        );
      },
    );
  }
}