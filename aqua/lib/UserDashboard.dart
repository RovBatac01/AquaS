import 'package:aqua/Settings.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:aqua/Dashboard.dart';
import 'package:aqua/AccountManagement.dart';
import 'package:aqua/History.dart';
import 'package:aqua/Home.dart';
import 'package:aqua/Login.dart';
import 'colors.dart';

void main() {
  runApp(MyDrawerAndNavBarApp());
}

class MyDrawerAndNavBarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Userdashboard(),
    );
  }
}

class Userdashboard extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<Userdashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    Dashboard(),
    HistoricalData(),
    Settings(),
  ];

  final ValueNotifier<ThemeMode> _notifier = ValueNotifier(ThemeMode.light);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _notifier,
      builder: (_, mode, __) {
        return MaterialApp(
          themeMode: mode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: Scaffold(
            appBar: AppBar(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop,
                    color: ASColor.txt1Color,
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'AQUASENSE',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 25,
                      color: ASColor.txt1Color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
              flexibleSpace: Container(
                decoration: BoxDecoration(gradient: ASColor.secondaryGradient),
              ),
            ),
            body: _screens[_currentIndex],
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: GNav(
                gap: 8,
                activeColor: Colors.white,
                iconSize: 24,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                backgroundColor: Colors.white,
                color: Colors.grey[600],
                tabBackgroundColor: Colors.blue,
                selectedIndex: _currentIndex,
                onTabChange: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                tabs: [
                  GButton(
                    icon: Icons.dashboard_outlined,
                    text: 'Dashboard',
                  ),
                  GButton(
                    icon: Icons.history_outlined,
                    text: 'History',
                  ),
                  GButton(
                    icon: Icons.settings,
                    text: 'Settings',
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  mode = mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
                  _notifier.value = mode;
                });
              },
              child: Icon(Icons.dark_mode_outlined),
            ),
          ),
        );
      },
    );
  }
}
