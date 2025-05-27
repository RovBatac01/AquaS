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
          children: [
            // Dark Mode switch with left alignment
            Padding(
              padding: const EdgeInsets.only(
                left: 10.0,
              ), // consistent left padding
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.onBackground, // Use theme color
                        ),
                      ),
                    ),
                  ),
                  Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20), // spacing between widgets
            // same left padding as above
            Padding(
              padding: const EdgeInsets.only(right: 9.0),
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(
                        context,
                      ).colorScheme.onBackground, // text/icon color
                  backgroundColor:
                      Colors.transparent, // Remove rounded background
                  shape: null, // Remove any shape
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      'Log Out',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.onBackground, // Use theme color
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.logout,
                      size: 20,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
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
