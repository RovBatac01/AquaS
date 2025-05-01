import 'package:flutter/material.dart';
import 'package:aqua/pages/HomeScreen.dart'; // Import your page files
import 'package:aqua/pages/SAdminAccountManagement.dart'; // Import your page files
import 'package:aqua/History.dart'; // Import your page files
import 'package:aqua/pages/Notification.dart'; // Import your page files
import 'package:aqua/pages/Statistics.dart';
import 'package:aqua/pages/Settings.dart';

class BottomNavigationBarWidget extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const BottomNavigationBarWidget({Key? key, required this.themeNotifier})
      : super(key: key);

  @override
  _BottomNavigationBarWidgetState createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(),
      Accountmanagement(),
      Statistics(),
      NotificationPage(),
      SettingsPage(themeNotifier: widget.themeNotifier),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0ecec),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        // Removed Padding from here and added to the Container
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -5), // changes position of shadow
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
          child: Container(
            color: const Color(0xFF0a782f), 
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0), // Added padding here
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, 'Home', 0),
                _buildNavItem(Icons.manage_accounts_outlined, 'Account', 1),
                _buildNavItem(Icons.history_outlined, 'History', 2),
                _buildNavItem(Icons.notifications_outlined, 'Notify', 3),
                _buildNavItem(Icons.settings_outlined, 'Settings', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData iconData, String label, int index) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            color: isSelected ? Colors.blue.shade200 : Colors.white70,
            size: 28, // Increased size for better visibility
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue.shade200 : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
