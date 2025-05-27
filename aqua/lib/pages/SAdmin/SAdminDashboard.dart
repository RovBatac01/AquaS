import 'package:aqua/NavBar/HomeUi.dart';
import 'package:aqua/NavBar/Notification.dart';
import 'package:aqua/NavBar/Settings.dart';
import 'package:aqua/pages/SAdmin/SAdminAccountManagement.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/NavBar/Statistics.dart';
import 'package:aqua/pages/SAdmin/SAdminHome.dart';
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
    Center(child: NotificationPage()),
    Center(child: SettingsPage()),
  ];

  final List<String> _titles = [
    'Home',
    'Account Management',
    'Statistics',
    'Notification',
    'Settings',
  ];

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Logout"),
          content: Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: ASColor.getTextColor(context),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog first
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ASColor.BGSecond,
              ),
              child: Text(
                "Confirm",
                style: TextStyle(
                  color: ASColor.getTextColor(context),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        );
      },
    );
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
                  padding: EdgeInsets.only(top: 25, left: 15, bottom: 15),
                  height: 70,
                  decoration: BoxDecoration(
                    color: isDarkMode ? ASColor.BGSecond : ASColor.BGFifth,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        _titles[_currentIndex],
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          color: ASColor.getTextColor(
                            context,
                          ), // theme-adaptive text color
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_currentIndex == 0) ...[],
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
                    _buildNavItem(Icons.person, 'Account', 1),
                    _buildNavItem(Icons.history, 'History', 2),
                    _buildNavItem(Icons.notifications, 'Notifications', 3),
                    _buildNavItem(Icons.settings, 'Settings', 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Move _buildNavItem inside _MainScreenState as a method
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
