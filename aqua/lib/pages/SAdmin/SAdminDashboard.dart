import 'package:aqua/NavBar/HomeUi.dart';
import 'package:aqua/NavBar/Notification.dart';
import 'package:aqua/pages/SAdmin/SAdminAccountManagement.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/NavBar/Statistics.dart';
import 'package:aqua/pages/SAdmin/SAdminHome.dart';
import 'package:flutter/material.dart';
import '../../components/colors.dart'; // Ensure this file contains your custom colors
// import 'package:google_nav_bar/google_nav_bar.dart';

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
  int _currentIndex = 0;

  final List<Widget> _screens = [
    Center(child: SuperAdminHomeScreen()),
    Center(child: Sadminaccountmanagement()),
    Center(child: Statistics()),
    Center(child: NotificationPage()),
  ];

  final List<String> _titles = ['Home','Account Management', 'Statistics', 'Notification'];

  final ValueNotifier<ThemeMode> _notifier = ValueNotifier(
    ThemeMode.light,
  ); // This Code is for the default mode of the dashboard change the light to dark if you want the default is Dark Mode


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
              child: Text("Cancel",
                  style: TextStyle(
                    color: ASColor.txt3Color,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w300)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog first
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: ASColor.BGsecond),
              child: Text("Confirm",
                  style: TextStyle(
                    color: ASColor.txt3Color,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w300)),
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
                color:
                    mode == ThemeMode.light
                        ? ASColor.BGSixth // Single color for light mode
                        : ASColor.BGthird, // Single color for dark mode
              ),
              title: Row(
                children: [
                  SizedBox(width: 10),
                  Text(
                    _titles[_currentIndex],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      color: isDarkMode ? ASColor.txt2Color : ASColor.txt2Color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_currentIndex == 0) ...[
                    
                  ],
                ],
              ),
            ),

            body: _screens[_currentIndex],
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 0, 0, 0), // Green background
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: BottomNavigationBar(
                  backgroundColor: Color(0xFF00A650), // Match container
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white.withOpacity(0.7),
                  selectedFontSize: 12,
                  unselectedFontSize: 12,
                  elevation: 0,
                  currentIndex: _currentIndex,
                  onTap: _onItemTapped,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_2_outlined),
                      label: 'Account',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.history),
                      label: 'History',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.notifications),
                      label: 'Notifications',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
            // bottomNavigationBar: Container(
            //   decoration: BoxDecoration(
            //     gradient:
            //         isDarkMode
            //             ? ASColor
            //                 .firstGradient // Dark Mode Background
            //             : ASColor.secondGradient, // Light Mode Background
            //   ),
            //   child: Padding(
            //     padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            //     child: SingleChildScrollView(
            //       scrollDirection:Axis.horizontal, // Enables horizontal scrolling
            //       child: SizedBox(
            //         width:
            //             MediaQuery.of(
            //               context,
            //             ).size.width, // Adapts to screen width
            //         child: GNav(
            //           gap: 8,
            //           activeColor:
            //               isDarkMode
            //                   ? ASColor.BGfifth
            //                   : ASColor.BGthird, // Icon Color
            //           iconSize: 24,
            //           padding: EdgeInsets.symmetric(
            //             horizontal: 20,
            //             vertical: 12,
            //           ),
            //           backgroundColor: Colors.transparent,
            //           color: isDarkMode ? ASColor.BGthird : Colors.white,
            //           tabBackgroundGradient:
            //               isDarkMode
            //                   ? ASColor.secondGradient
            //                   : ASColor.firstGradient,
            //           textStyle: TextStyle(
            //             color: isDarkMode ? ASColor.BGfifth : ASColor.txt3Color,
            //             fontWeight: FontWeight.bold,
            //           ),
            //           selectedIndex: _currentIndex,
            //           onTabChange: (index) {
            //             setState(() {
            //               _currentIndex = index;
            //             });
            //           },
            //           tabs: [
            //             GButton(icon: Icons.home_outlined, text: 'Home',),
            //             GButton(icon: Icons.manage_accounts, text: 'View Account',),
            //             GButton(icon: Icons.stacked_bar_chart_outlined, text: 'Statistics'),
            //             GButton(icon: Icons.notifications_active_outlined, text: 'Notifications'),
            //           ],
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
            // floatingActionButton: FloatingActionButton(
            //   onPressed: () {
            //     setState(() {
            //       _notifier.value =
            //           mode == ThemeMode.light
            //               ? ThemeMode.dark
            //               : ThemeMode.light;
            //     });
            //   },
            //   child: Icon(Icons.dark_mode_outlined),
            // ),
          ),
        );
      },
    );
  }
}
