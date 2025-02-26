import 'package:aqua/AccountManagement.dart';
import 'package:aqua/Dashboard.dart';
import 'package:aqua/Home.dart';
import 'package:aqua/Login.dart';
import 'package:flutter/material.dart';
import 'colors.dart';

void main() {
  runApp(MyDrawerAndNavBarApp());
}

class MyDrawerAndNavBarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: MainScreen());
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // List of screens for Bottom Navigation Bar
  final List<Widget> _screens = [
    Dashboard(),
    Accountmanagement(),
    SettingsScreen(),
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
              title: const Text(
                'AQUASENSE',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  // color: ASColor.txt2Color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              // flexibleSpace: Container(
              //   decoration: BoxDecoration(gradient: ASColor.secondaryGradient),
              // ),
            ),

            // Drawer for navigation
            drawer: Drawer(
              child: Column(
                children: [
                  Container(
                    height: 200, // Adjust height as needed
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: ASColor.secondaryGradient,
                    ),
                    child: Center(
                      child: Text(
                        'Menu',
                        style: TextStyle(color: Colors.white, fontSize: 24),
                      ),
                    ),
                  ),
                  // Expanded ListView for menu items
                  Expanded(
                    child: ListView(
                      children: [
                        ListTile(
                          leading: Icon(Icons.dashboard_customize_outlined),
                          title: Text('Dashboard'),
                          onTap: () {
                            setState(() {
                              _currentIndex = 0;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.water_drop),
                          title: Text('Water Set'),
                          onTap: () {
                            setState(() {
                              _currentIndex = 1;
                            });
                            Navigator.pop(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.person),
                          title: Text('Management'),
                          onTap: () {
                            setState(() {
                              _currentIndex = 2;
                            });
                            Navigator.pop(context);
                          },
                        ),

                        ListTile(
                          leading: Icon(Icons.history),
                          title: Text('Dark Mode/ Light Mode'),
                          onTap:
                              () =>
                                  _notifier.value =
                                      mode == ThemeMode.light
                                          ? ThemeMode.dark
                                          : ThemeMode.light,
                        ),
                      ],
                    ),
                  ),
                  // Logout Button at the bottom
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ListTile(
                      leading: Icon(Icons.logout),
                      title: Text('Logout'),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Display the current screen
            body: _screens[_currentIndex],
            // Bottom Navigation Bar for navigation
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.shifting, // Shifting
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                  // backgroundColor: Colors.blue,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.info),
                  label: 'Account Management',
                  // backgroundColor: Colors.green,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                  // backgroundColor: Colors.yellow,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Home Screen
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Home Screen', style: TextStyle(fontSize: 24)),
    );
  }
}

// Settings Screen
class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings Screen', style: TextStyle(fontSize: 24)),
    );
  }
}
