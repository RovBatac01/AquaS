import 'package:aqua/NavBar/Settings.dart';
import 'package:aqua/pages/Details.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/NavBar/HomeUi.dart';
import 'package:aqua/NavBar/Statistics.dart';
import 'package:aqua/NavBar/Notification.dart';
import 'package:aqua/pages/Theme_Provider.dart';
import 'package:aqua/pages/User/Request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
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
      debugShowCheckedModeBanner: false, // Hides the debug ribbon
      themeMode: themeProvider.themeMode, // 👈 Connect to ThemeProvider
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
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
    Center(child: DetailsScreen()),
    Center(child: Statistics()),
    Center(child: NotificationPage()),
    Center(child: SettingsPage()),
  ];

  final List<String> _titles = [
    'Home',
    'Statistics',
    'Notification',
    'Settings',
  ];

  //Code for the bottom navigation bar
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    // Show popup dialog when the dashboard is first built (user just logged in)
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   showDialog(
    //     context: context,
    //     barrierDismissible: false,
    //     barrierColor: Colors.black.withOpacity(
    //       0.9,
    //     ), // darken and blur background
    //     builder:
    //         (context) => Stack(
    //           children: [
    //             // Blur the background
    //             BackdropFilter(
    //               filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
    //               child: Container(color: Colors.transparent),
    //             ),
    //             Center(
    //               child: AlertDialog(
    //                 backgroundColor: ASColor.getCardColor(context),
    //                 title: Text(
    //                   'Access Required',
    //                   style: TextStyle(
    //                     color: ASColor.getTextColor(context),
    //                     fontFamily: 'Montserrat',
    //                     fontSize: 18,
    //                     fontWeight: FontWeight.bold,
    //                   ),
    //                 ),
    //                 content: Text(
    //                   'You need a Super Admin approval to view sensor data. Your request for access has been sent. Please wait for approval, or logout .',
    //                   style: TextStyle(
    //                     color: ASColor.getTextColor(context),
    //                     fontFamily: 'Poppins',
    //                     fontSize: 14,
    //                   ),
    //                 ),
    //                 actions: [
    //                   TextButton(
    //                     onPressed: () {
    //                       // Send request logic here
    //                       Navigator.of(context).pop();
    //                       // Optionally show a confirmation dialog or snackbar
    //                     },
    //                     child: Text(
    //                       'Send Request',
    //                       style: TextStyle(
    //                         color: ASColor.getTextColor(context),
    //                         fontFamily: 'Poppins',
    //                         fontSize: 14,
    //                       ),
    //                     ),
    //                   ),
    //                   TextButton(
    //                     onPressed: () {
    //                       Navigator.of(context).pop();
    //                       Navigator.pushReplacement(
    //                         context,
    //                         MaterialPageRoute(
    //                           builder: (context) => LoginScreen(),
    //                         ),
    //                       );
    //                     },
    //                     child: Text(
    //                       'Logout',
    //                       style: TextStyle(
    //                         color: ASColor.getTextColor(context),
    //                         fontFamily: 'Poppins',
    //                         fontSize: 14,
    //                       ),
    //                     ),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           ],
    //         ),
    //   );
    // });

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
                          ), // Use theme-adaptive text color
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
                    _buildNavItem(Icons.history, 'History', 1),
                    _buildNavItem(Icons.notifications, 'Notifications', 2),
                    _buildNavItem(Icons.settings, 'Settings', 3),
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
