import 'package:aqua/pages/Settings.dart';
import 'package:flutter/material.dart';
import 'package:aqua/pages/HomeScreen.dart';
import 'package:aqua/pages/Notification.dart';
import 'package:aqua/pages/SAdminAccountManagement.dart';
import 'package:aqua/AdminViewReport.dart';
import 'package:aqua/Dashboard.dart';
import 'package:aqua/History.dart';
import 'package:aqua/Login.dart';
import 'package:aqua/pages/Statistics.dart';
import 'package:aqua/colors.dart';
import 'package:aqua/components/navbar.dart'; // Import your navbar widget

void main() {
  runApp(MyDrawerAndNavBarApp());
}

class MyDrawerAndNavBarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Sadmindashboard(),
    );
  }
}

class Sadmindashboard extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<Sadmindashboard> {
  final ValueNotifier<ThemeMode> _notifier = ValueNotifier(ThemeMode.dark);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _notifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: Scaffold(
            body: BottomNavigationBarWidget(themeNotifier: _notifier), 
          ),
        );
      },
    );
  }
}