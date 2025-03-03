import 'package:aqua/AccountManagement.dart';
import 'package:aqua/Dashboard.dart';
import 'package:aqua/History.dart';
import 'package:aqua/Login.dart';
import 'package:aqua/Report.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'colors.dart'; // Ensure this file contains your custom colors

void main() {
  runApp(MyDrawerAndNavBarApp());
}

class MyDrawerAndNavBarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Admindashboard(),
    );
  }
}

class Admindashboard extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<Admindashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    Dashboard(), 
    Accountmanagement(),
    HistoricalData(), 
    Report()
    ];

  final ValueNotifier<ThemeMode> _notifier = ValueNotifier(ThemeMode.dark);// This Code is for the default mode of the dashboard change the light to dark if you want the default is Dark Mode

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _notifier,
      builder: (_, mode, __) {
        // Define colors based on the theme mode
        final bool isDarkMode = mode == ThemeMode.dark;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: Scaffold(
            appBar: AppBar(
              centerTitle: true, 
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient:
                      mode == ThemeMode.light
                          ? ASColor
                              .secondaryGradient 
                          : ASColor.primaryGradient, 
                ), 
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.water_drop,
                    color: isDarkMode 
                      ? ASColor.BGfirst // Color of The Icon for Dark Mode
                      : ASColor.txt2Color, // Color of The Icon for Light Mode
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'AQUASENSE',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 25,
                      color: isDarkMode ? ASColor.BGfirst : ASColor.txt2Color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

            
                  Spacer(),

            
                  IconButton(
                    icon: Icon(
                      Icons.logout,
                      color: isDarkMode ? ASColor.BGfirst : ASColor.txt2Color,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            body: _screens[_currentIndex],
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                gradient:
                    isDarkMode
                        ? ASColor.primaryGradient //Background Color of NavBar for Dark Mode
                        : ASColor.secondaryGradient, //Background Color of NavBar for Dark Mode
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: GNav(
                  gap: 8,
                  activeColor: 
                    isDarkMode 
                      ? ASColor.BGfifth  // Icon Color for Dark Mode
                      : ASColor.BGthird, // Icon Color for Light Mode
                  iconSize: 24,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.transparent,
                  color: isDarkMode ? ASColor.BGthird : Colors.white,
                  tabBackgroundGradient:
                      isDarkMode
                          ? ASColor.secondaryGradient
                          : ASColor.primaryGradient,

                  textStyle: TextStyle(
                    color:
                        isDarkMode
                            ? ASColor.BGfifth // Text Color for Dark Mode
                            : ASColor.txt3Color, //Text Color for Light Mode
                    fontWeight: FontWeight.bold,
                  ),

                  selectedIndex: _currentIndex,
                  onTabChange: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  tabs: [
                    GButton(icon: Icons.dashboard_outlined, text: 'Dashboard'),
                    GButton(icon: Icons.manage_accounts, text: 'Account Management'),
                    GButton(icon: Icons.history_outlined, text: 'History'),
                    GButton(icon: Icons.report, text: 'Report'),
                  ],
                ),
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _notifier.value =
                      mode == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
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
