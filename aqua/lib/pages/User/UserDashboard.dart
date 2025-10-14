import 'package:aqua/config/api_config.dart';
import 'package:aqua/NavBar/Settings.dart';
import 'package:aqua/pages/Calendar.dart';
import 'package:aqua/pages/CalibrationRequest.dart';
import 'package:aqua/pages/User/UserSettings.dart';
import 'package:aqua/pages/User/Details.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/NavBar/HomeUi.dart';
import 'package:aqua/NavBar/Statistics.dart';
import 'package:aqua/NavBar/Notification.dart';
import 'package:aqua/pages/Theme_Provider.dart';
import 'package:aqua/pages/User/Request.dart';
import 'package:aqua/pages/User/UserStatistics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
  final TextEditingController _deviceIdController = TextEditingController();
  List<Map<String, dynamic>> userDevices = [];
  bool _hasDeviceAccess = false;
  bool _isCheckingAccess = true;

  final List<Widget> _screens = [
    Center(child: DetailsScreen(key: ValueKey('Home'))),
    Center(child: UserStatistics(key: ValueKey('Stats'))),
    Center(child: NotificationPage(key: ValueKey('Notif'))),
    Center(child: CalendarPage()),
    Center(child: SettingsScreen()),
  ];

  final List<String> _titles = [
    'Home',
    'Statistics',
    'Notification',
    'Calendar',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _checkDeviceAccess();
  }

  /// Check if user has access to any devices
  Future<void> _checkDeviceAccess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      
      if (token == null) {
        setState(() {
          _isCheckingAccess = false;
          _hasDeviceAccess = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.userDeviceAccessEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userDevices = (data['devices'] as List).map((device) => device as Map<String, dynamic>).toList();
          _hasDeviceAccess = userDevices.isNotEmpty;
          _isCheckingAccess = false;
        });
      } else {
        setState(() {
          _hasDeviceAccess = false;
          _isCheckingAccess = false;
        });
      }
    } catch (e) {
      print('Error checking device access: $e');
      setState(() {
        _hasDeviceAccess = false;
        _isCheckingAccess = false;
      });
    }
  }

  //Code for the bottom navigation bar
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Method to submit device access request
  Future<void> _submitDeviceRequest(BuildContext context) async {
    final deviceId = _deviceIdController.text.trim();
    
    if (deviceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a Device ID'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: Colors.blue),
        ),
      );

      // Get user token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');
      
      if (token == null) {
        Navigator.pop(context); // Remove loading
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
        return;
      }

      // Make API request
      final response = await http.post(
        Uri.parse('${ApiConfig.apiBase}/device-request'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'deviceId': deviceId,
          'message': 'Requesting access to monitor water quality data from this device.',
        }),
      );

      Navigator.pop(context); // Remove loading
      Navigator.pop(context); // Remove device dialog

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Show success message
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Request Sent'),
              ],
            ),
            content: Text(
              'Your device access request has been sent successfully! The admin will be notified and you will receive a notification once it\'s processed.',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
        
        // Clear the device ID field
        _deviceIdController.clear();
        
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['error'] ?? 'Failed to submit request'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (error) {
      Navigator.pop(context); // Remove loading if still showing
      Navigator.pop(context); // Remove device dialog if still showing
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: Please check your connection'),
          backgroundColor: Colors.red,
        ),
      );
      print('Device request error: $error');
    }
  }



  // Helper methods for enhanced UI
  IconData _getIconForPage(int index) {
    switch (index) {
      case 0: return Icons.home_rounded;
      case 1: return Icons.analytics_rounded;
      case 2: return Icons.notifications_rounded;
      case 3: return Icons.calendar_month_rounded;
      case 4: return Icons.settings_rounded;
      default: return Icons.home_rounded;
    }
  }

  String _getSubtitleForPage(int index) {
    switch (index) {
      case 0: return 'Water quality overview';
      case 1: return 'Data analytics';
      case 2: return 'System alerts';
      case 3: return 'Schedule management';
      case 4: return 'Account preferences';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    

    // Show popup dialog when the dashboard is first built (user just logged in) and has no device access
    if (!_isCheckingAccess && !_hasDeviceAccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(
          0.9,
        ), // darken and blur background
        builder:
            (context) => Stack(
              children: [
                // Blur the background
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: Colors.transparent),
                ),
                Center(
                  child: AlertDialog(
                    backgroundColor: ASColor.getCardColor(context),
                    title: Text(
                      'Access Required',
                      style: TextStyle(
                        color: ASColor.getTextColor(context),
                        fontFamily: 'Montserrat',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You need a Super Admin approval to view sensor data. Your request for access has been sent. Please wait for approval, or logout .',
                          style: TextStyle(
                            color: ASColor.getTextColor(context),
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 16),
                        if (_hasDeviceAccess) 
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'You now have access to ${userDevices.length} device(s)! Refresh to continue.',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (!_hasDeviceAccess) ...[
                          Container(
                            height: 50,
                            child: TextField(
                            controller: _deviceIdController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  isDarkMode ? Colors.white10 : Colors.black12,
                              hintText: 'Input Device ID',
                              hintStyle: TextStyle(
                                color: ASColor.getTextColor(context),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            obscureText: true,
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ], // End of if (!_hasDeviceAccess)
                      ],
                    ),
                    actions: [
                      if (_hasDeviceAccess)
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _checkDeviceAccess(); // Refresh device access
                            setState(() {}); // Trigger rebuild
                          },
                          child: Text(
                            'Refresh Dashboard',
                            style: TextStyle(
                              color: Colors.green,
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        TextButton(
                          onPressed: () => _submitDeviceRequest(context),
                          child: Text(
                            'Send Request',
                            style: TextStyle(
                              color: ASColor.getTextColor(context),
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: ASColor.getTextColor(context),
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      );
    });
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: _isCheckingAccess 
        ? Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Checking device access...',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: ASColor.getTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode 
                    ? [ASColor.BGSecond, ASColor.BGthird.withOpacity(0.8)]
                    : [ASColor.BGFifth, Colors.white.withOpacity(0.95)],
                ),
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
                            color: isDarkMode 
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDarkMode ? Colors.white12 : Colors.black12,
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
                                          fontSize: (constraints.maxWidth * 0.055).clamp(18.0, 24.0),
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
                                        fontSize: (constraints.maxWidth * 0.035).clamp(12.0, 16.0),
                                        color: ASColor.getTextColor(context).withOpacity(0.7),
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
                                  color: isDarkMode ? Colors.white12 : Colors.black12,
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
                                      _currentIndex = _titles.indexOf('Settings');
                                    });
                                  },
                                  tooltip: 'Settings',
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Content Area
                    Expanded(
                      child: ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (
                            Widget child,
                            Animation<double> animation,
                          ) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: _screens[_currentIndex],
                        ),
                      ),
                    ),
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
              maxHeight: MediaQuery.of(context).size.height * 0.08, // Max 8% of screen height
            ),
            decoration: BoxDecoration(
              color: isDarkMode 
                ? Colors.white.withOpacity(0.05)
                : Colors.white.withOpacity(0.9),
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
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.02, // 2% of container width
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: _buildEnhancedNavItem(Icons.home_rounded, 'Home', 0)),
                      Expanded(child: _buildEnhancedNavItem(Icons.analytics_rounded, 'Statistics', 1)),
                      Expanded(child: _buildEnhancedNavItem(Icons.notifications_rounded, 'Notifications', 2)),
                      Expanded(child: _buildEnhancedNavItem(Icons.calendar_month_rounded, 'Calendar', 3)),
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

  // Enhanced Navigation Item - modern design similar to admin dashboards
  Widget _buildEnhancedNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on available space
        final double iconSize = (constraints.maxWidth * 0.25).clamp(16.0, 22.0);
        final double fontSize = (constraints.maxWidth * 0.12).clamp(8.0, 12.0);
        final double paddingHorizontal = (constraints.maxWidth * 0.08).clamp(2.0, 6.0);
        
        return GestureDetector(
          onTap: () => _onItemTapped(index),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: paddingHorizontal, 
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isSelected 
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
                    color: isSelected 
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon, 
                    color: isSelected 
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
                        color: isSelected 
                          ? Colors.blue 
                          : ASColor.getTextColor(context).withOpacity(0.6),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
