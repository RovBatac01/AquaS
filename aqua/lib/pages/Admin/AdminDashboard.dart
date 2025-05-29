import 'package:aqua/NavBar/Settings.dart';
import 'package:aqua/pages/Admin/AdminHome.dart';
import 'package:aqua/pages/Calendar.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/NavBar/HomeUi.dart';
import 'package:aqua/NavBar/Notification.dart';
import 'package:aqua/NavBar/Statistics.dart';
import 'package:aqua/pages/Theme_Provider.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import '../../components/colors.dart'; // Ensure this file contains your custom colors

void main() {
  runApp(MyDrawerAndNavBarApp());
}

class MyDrawerAndNavBarApp extends StatelessWidget {
  const MyDrawerAndNavBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // 👈

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode, // 👈 Connect to ThemeProvider
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Admindashboard(),
    );
  }
}

class Admindashboard extends StatefulWidget {
  const Admindashboard({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<Admindashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    Center(child: AdminHomeScreen()),
    Center(child: Statistics()),
    Center(child: NotificationPage()),
    Center(child: CalendarPage()),
    Center(child: SettingsPage()),
  ];

  final List<String> _titles = [
    'Home',
    'Statistics',
    'Notification',
    'Calendar',
    'Settings'
  ];

  //Code for the bottom navigation bar
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: Scaffold(
        body: Stack(
          children: [
            // Add spacing at the top (e.g., status bar height or more)
            Column(
              children: [
                Container(
                  padding: EdgeInsets.only(
                    top: 25,
                    left: 15,
                    right: 15,
                  ),
                  height: 70,
                  decoration: BoxDecoration(
                    color: isDarkMode ? ASColor.BGSecond : ASColor.BGFifth,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _titles[_currentIndex],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          color: ASColor.getTextColor(context),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.settings,
                          color: ASColor.getTextColor(context),
                        ),
                        onPressed: () {
                          setState(() {
                            _currentIndex = _titles.indexOf('Settings');
                          });
                        },
                        tooltip: 'Settings',
                      ),
                    ],
                  ),
                ),
                // Remaining body content
                Expanded(child: _screens[_currentIndex]),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? ASColor.BGSecond : ASColor.BGFifth,
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 80, // <-- Total height of nav bar
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home, 'Home', 0),
                    _buildNavItem(Icons.history, 'History', 1),
                    _buildNavItem(Icons.notifications, 'Notifications', 2),
                    _buildNavItem(Icons.calendar_month_outlined, 'Calendar', 3),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    final color =
        isSelected
            ? ASColor.getTextColor(context)
            : ASColor.getTextColor(context).withOpacity(0.6);

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
