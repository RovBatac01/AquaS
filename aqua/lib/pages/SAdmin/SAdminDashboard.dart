import 'package:aqua/NavBar/HomeUi.dart';
import 'package:aqua/NavBar/Notification.dart';
import 'package:aqua/NavBar/Settings.dart';
import 'package:aqua/pages/Calendar.dart';
import 'package:aqua/pages/User/UserSettings.dart';
import 'package:aqua/pages/SAdmin/SAdminAccountManagement.dart';

import 'package:aqua/NavBar/Statistics.dart';
import 'package:aqua/pages/SAdmin/SAdminHome.dart';
import 'package:aqua/pages/SAdmin/SAdminNotification.dart';
import 'package:aqua/pages/SAdmin/SAdminSettings.dart';
import 'package:aqua/pages/Theme_Provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/colors.dart'; // Ensure this file contains your custom colors
// import 'package:google_nav_bar/google_nav_bar.dart';

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
      home: Sadmindashboard(),
    );
  }
}

class Sadmindashboard extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<Sadmindashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    Center(child: SuperAdminHomeScreen()),
    Center(child: Sadminaccountmanagement()),
    Center(child: Statistics()),
    Center(child: SAdminNotification()),
    Center(child: CalendarPage()),
    Center(child: SAdminSettingsScreen()),
  ];

  final List<String> _titles = [
    'Home',
    'Account Management',
    'Historical Data',
    'Notification',
    'Calendar',
    'Settings',
  ];

  String _getSubtitle(int index) {
    switch (index) {
      case 0:
        return 'System overview and monitoring';
      case 1:
        return 'Manage user accounts';
      case 2:
        return 'Analytics and reports';
      case 3:
        return 'System alerts and notifications';
      case 4:
        return 'Schedule and events';
      case 5:
        return 'System configuration';
      default:
        return '';
    }
  }



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
                    top: 30,
                    left: 20,
                    right: 20,
                    bottom: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode 
                        ? [ASColor.BGSecond, ASColor.BGthird.withOpacity(0.8)]
                        : [ASColor.BGFifth, Colors.white.withOpacity(0.95)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titles[_currentIndex],
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 24,
                                color: ASColor.getTextColor(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _getSubtitle(_currentIndex),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: ASColor.getTextColor(context).withOpacity(0.6),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.settings_rounded,
                              color: Colors.green,
                              size: 24,
                            ),
                            onPressed: () {
                              setState(() {
                                _currentIndex = _titles.indexOf('Settings');
                              });
                            },
                            tooltip: 'Settings',
                          ),
                        ),
                      ],
                    ),
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Container(
              height: 75,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(child: _buildEnhancedNavItem(Icons.home_rounded, 'Home', 0)),
                  Expanded(child: _buildEnhancedNavItem(Icons.people_rounded, 'Users', 1)),
                  Expanded(child: _buildEnhancedNavItem(Icons.analytics_rounded, 'Stats', 2)),
                  Expanded(child: _buildEnhancedNavItem(Icons.notifications_rounded, 'Alerts', 3)),
                  Expanded(child: _buildEnhancedNavItem(Icons.calendar_month_rounded, 'Calendar', 4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced Navigation Item
  Widget _buildEnhancedNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected 
            ? Colors.green.withOpacity(0.12)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected 
                  ? Colors.green
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected 
                  ? Colors.white
                  : ASColor.getTextColor(context).withOpacity(0.6),
                size: 20,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                    ? Colors.green
                    : ASColor.getTextColor(context).withOpacity(0.6),
                  fontFamily: 'Poppins',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
