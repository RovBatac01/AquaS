import 'package:aqua/pages/Admin/AdminHome.dart';
import 'package:aqua/pages/Admin/AdminSettings.dart';
import 'package:aqua/pages/Admin/AdminNotification.dart';
import 'package:aqua/pages/Admin/AdminStatistics.dart';
import 'package:aqua/pages/Calendar.dart';
import 'package:aqua/NavBar/Statistics.dart';
import 'package:aqua/pages/Theme_Provider.dart';
import 'package:flutter/material.dart';
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
    Center(child: AdminStatistics()),
    Center(child: AdminNotification()),
    Center(child: CalendarPage()),
    Center(child: AdminSettingsScreen()),
  ];

  final List<String> _titles = [
    'Home',
    'Statistics',
    'Notification',
    'Calendar',
    'Settings',
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                color: isDarkMode ? null : ASColor.BGfirst,
                gradient:
                    isDarkMode
                        ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            ASColor.BGSecond,
                            ASColor.BGthird.withOpacity(0.8),
                          ],
                        )
                        : null,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Enhanced Header
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Container(
                          width: constraints.maxWidth,
                          margin: EdgeInsets.all(
                            (constraints.maxWidth * 0.04).clamp(12.0, 20.0),
                          ),
                          padding: EdgeInsets.all(
                            (constraints.maxWidth * 0.05).clamp(16.0, 24.0),
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDarkMode
                                    ? Colors.white.withOpacity(0.05)
                                    : ASColor.BGfirst,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  isDarkMode ? Colors.white12 : Colors.black12,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getIconForPage(_currentIndex),
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _titles[_currentIndex],
                                        style: TextStyle(
                                          fontSize: (constraints.maxWidth *
                                                  0.055)
                                              .clamp(18.0, 24.0),
                                          fontWeight: FontWeight.bold,
                                          color: ASColor.getTextColor(context),
                                          fontFamily: 'Montserrat',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getSubtitleForPage(_currentIndex),
                                      style: TextStyle(
                                        fontSize: (constraints.maxWidth * 0.035)
                                            .clamp(12.0, 16.0),
                                        color: ASColor.getTextColor(
                                          context,
                                        ).withOpacity(0.7),
                                        fontFamily: 'Poppins',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? Colors.white12
                                          : Colors.black12,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.settings_rounded,
                                    color: ASColor.getTextColor(context),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _currentIndex = _titles.indexOf(
                                        'Settings',
                                      );
                                    });
                                  },
                                  tooltip: 'Settings',
                                  constraints: BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                    maxWidth: 48,
                                    maxHeight: 48,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Content Area
                    Expanded(child: ClipRect(child: _screens[_currentIndex])),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            margin: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width * 0.03, // 3% of screen width
              0,
              MediaQuery.of(context).size.width * 0.03,
              MediaQuery.of(context).size.width * 0.03,
            ),
            constraints: BoxConstraints(
              minHeight: 60,
              maxHeight: (MediaQuery.of(context).size.height * 0.08).clamp(
                60.0,
                80.0,
              ), // Ensure max is at least 60
            ),
            decoration: BoxDecoration(
              color:
                  isDarkMode ? Colors.white.withOpacity(0.05) : ASColor.BGfirst,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.white12 : Colors.black12,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Ensure minimum usable height
                final availableHeight = constraints.maxHeight.clamp(
                  60.0,
                  double.infinity,
                );

                return Container(
                  height: availableHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: (constraints.maxWidth * 0.02).clamp(
                      4.0,
                      12.0,
                    ), // 2% of container width with bounds
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildEnhancedNavItem(
                          Icons.home_rounded,
                          'Home',
                          0,
                        ),
                      ),
                      Expanded(
                        child: _buildEnhancedNavItem(
                          Icons.analytics_rounded,
                          'Statistics',
                          1,
                        ),
                      ),
                      Expanded(
                        child: _buildEnhancedNavItem(
                          Icons.notifications_rounded,
                          'Notifications',
                          2,
                        ),
                      ),
                      Expanded(
                        child: _buildEnhancedNavItem(
                          Icons.calendar_month_rounded,
                          'Calendar',
                          3,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForPage(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.analytics_rounded;
      case 2:
        return Icons.notifications_rounded;
      case 3:
        return Icons.calendar_month_rounded;
      case 4:
        return Icons.settings_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  String _getSubtitleForPage(int index) {
    switch (index) {
      case 0:
        return 'Dashboard overview';
      case 1:
        return 'Data analytics';
      case 2:
        return 'System alerts';
      case 3:
        return 'Schedule management';
      case 4:
        return 'Account preferences';
      default:
        return '';
    }
  }

  Widget _buildEnhancedNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on available space with safety bounds
        final double iconSize = (constraints.maxWidth * 0.25).clamp(16.0, 24.0);
        final double fontSize = (constraints.maxWidth * 0.12).clamp(8.0, 12.0);
        final double paddingHorizontal = (constraints.maxWidth * 0.08).clamp(
          2.0,
          8.0,
        );

        return GestureDetector(
          onTap: () => _onItemTapped(index),
          child: Container(
            width: double.infinity,
            height: constraints.maxHeight.clamp(
              48.0,
              double.infinity,
            ), // Ensure minimum height
            padding: EdgeInsets.symmetric(
              horizontal: paddingHorizontal,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color:
                  isSelected
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color:
                        isSelected
                            ? Colors.blue
                            : ASColor.getTextColor(context).withOpacity(0.6),
                    size: iconSize,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        color:
                            isSelected
                                ? Colors.blue
                                : ASColor.getTextColor(
                                  context,
                                ).withOpacity(0.6),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
