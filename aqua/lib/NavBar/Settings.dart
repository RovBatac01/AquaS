import 'package:aqua/components/colors.dart';
import 'package:aqua/pages/Login.dart'; // Make sure this path is correct for your LoginScreen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aqua/pages/Theme_Provider.dart'; // Make sure this path is correct
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // Logout function
  Future<void> _logout(BuildContext context) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userToken'); // Clear the stored JWT
      await prefs.remove('userId'); // Clear the stored userId (if you store it)
      // You might have other user-specific data to clear here (e.g., username)

      // Navigate to the LoginScreen and prevent going back to previous pages
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      print('User logged out successfully.');
    } catch (e) {
      print('Error during logout: $e');
      // Handle potential errors during logout
    }
  }

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
                          color: Theme.of(context).colorScheme.onBackground, // Use theme color
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

            // same left padding as above
            // Padding(
            //   padding: const EdgeInsets.only(right: 9.0),
            //   child: TextButton(
            //     style: TextButton.styleFrom(
            //       foregroundColor:
            //           Theme.of(context).colorScheme.onBackground, // text/icon color
            //       backgroundColor:
            //           Colors.transparent, // Remove rounded background
            //       shape: null, // Remove any shape
            //     ),
            //     onPressed: () {
            //       _logout(context); // Call the logout function here
            //     },
            //     child: Row(
            //       children: [
            //         Text(
            //           'Log Out',
            //           style: TextStyle(
            //             fontSize: 16,
            //             color: Theme.of(context).colorScheme.onBackground, // Use theme color
            //             fontFamily: 'Poppins',
            //           ),
            //         ),
            //         const Spacer(),
            //         Icon(
            //           Icons.logout,
            //           size: 20,
            //           color: Theme.of(context).colorScheme.onBackground,
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}
