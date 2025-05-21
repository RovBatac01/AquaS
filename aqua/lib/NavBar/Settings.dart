import 'package:aqua/components/colors.dart';
import 'package:aqua/pages/Login.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aqua/pages/Theme_Provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              ],
            ),
            // Logout TextButton at the bottom
            Container(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: ASColor.txt3Color,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    Icon(Icons.logout_outlined,
                    size: 20,
                    color: Colors.black,)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
