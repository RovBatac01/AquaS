// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import 'package:aqua/Login.dart';
import 'package:aqua/colors.dart';

class SettingsPage extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const SettingsPage({Key? key, required this.themeNotifier}) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: PreferredSize(
  preferredSize: Size.fromHeight(90.0), // Adjust this value for the desired height
  child: ClipRRect(
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(30.0), // Adjust these values for the desired radius
      bottomRight: Radius.circular(30.0),
    ),
    child: AppBar(
      title: const Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 1,
          ),
        ),
      ),
      centerTitle: false,
      backgroundColor: Color(0xFF0a782f),
    ),
  ),
),
backgroundColor: const Color(0xfff0ecec),
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Logout'),
            onTap: () => _showLogoutDialog(context),
          ),
          ListTile(
            leading: Icon(Icons.dark_mode_outlined),
            title: Text('Dark Mode'),
            trailing: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, child) {
                return Switch(
                  value: mode == ThemeMode.dark,
                  onChanged: (bool value) {
                    themeNotifier.value =
                        value ? ThemeMode.dark : ThemeMode.light;
                  },
                );
              },
            ),
          ),
          // Add other settings options here in future updates
        ],
      ),
    );
  }
}