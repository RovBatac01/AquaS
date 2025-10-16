import 'dart:convert' show jsonEncode, jsonDecode;
import 'package:aqua/components/colors.dart';
import 'package:aqua/config/api_config.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/pages/Theme_Provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // Make sure this is imported
import 'package:http/http.dart' as http; // Import both post and put

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Wrap your app with ScreenUtilInit
  runApp(
    ScreenUtilInit(
      // IMPORTANT: Replace these with the width and height of your design artboard/frame in logical pixels
      // For example, if your design was made for a 360dp width and 690dp height phone:
      designSize: const Size(360, 690), // <--- YOU MUST SET YOUR DESIGN SIZE HERE
      minTextAdapt: true, // This is now correctly set
      splitScreenMode: true, // Good for multi-window/split-screen support
      builder: (context, child) {
        return SettingsApp(); // Your root app widget, which contains MaterialApp
      },
    ),
  );
}

class SettingsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Settings',
      theme: ThemeData.dark(), // Matches dark UI in your image
      home: SAdminSettingsScreen(),
    );
  }
}

//Profile Management UPDATE
Future<void> updateUser(
    BuildContext context, {
    required String username,
    required String email,
    required String phone,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final int? userId = prefs.getInt('userId');
  final String? userToken = prefs.getString('userToken'); // Get the token

  if (userId == null || userToken == null) { // Check for token too
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("User ID or token not found. Please log in again.")),
    );
    return;
  }

  try {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Updating profile..."),
        duration: Duration(seconds: 1),
      ),
    );

    final uri = Uri.parse(
      'https://aquasense-p36u.onrender.com/api/super-admin/profile', // <--- CHANGED ENDPOINT
    );
    final response = await http.put( // <--- CHANGED TO PUT REQUEST
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $userToken", // <--- ADDED AUTHORIZATION HEADER
      },
      body: jsonEncode({
        // "id": userId, // Backend extracts userId from token, no need to send
        "username": username,
        "email": email,
        "phone": phone, // Ensure 'phone' matches backend field name
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["message"] == 'Profile updated successfully!') { // <--- Adjusted success condition
      // Update local storage with new values from the backend's response
      // It's safer to update with data from the server after a successful update.
      await prefs.setString('loggedInUsername', data['user']['username']);
      await prefs.setString('loggedInEmail', data['user']['email']);
      await prefs.setString('loggedInPhone', data['user']['phone'] ?? ''); // Handle null phone if applicable

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User information updated successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Update failed: ${data['message'] ?? 'Unknown error'}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error updating profile: ${e.toString()}"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class SAdminSettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SAdminSettingsScreen> {
  bool ProfileExpanded = false;
  bool AppearanceExpanded = false;
  bool SessionExpanded = false;
  bool FAQExpanded = false;
  final TextEditingController username = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController currentPassword = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController confirm_password = TextEditingController();
  bool _obscurecurrentPassword = true;
  bool _obscurenewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    username.text = prefs.getString('loggedInUsername') ?? '';
    email.text = prefs.getString('loggedInEmail') ?? '';
    phone.text = prefs.getString('loggedInPhone') ?? '';
  }

  // --- PASSWORD CHANGE FUNCTION ---
  Future<void> _changePassword() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userToken = prefs.getString('userToken');

    if (userToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Authentication token not found. Please log in again.")),
      );
      return;
    }

    // Frontend validation for passwords
    if (currentPassword.text.isEmpty || newPassword.text.isEmpty || confirm_password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill all password fields."), backgroundColor: Colors.red),
      );
      return;
    }

    if (newPassword.text != confirm_password.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("New password and confirm password do not match."), backgroundColor: Colors.red),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Changing password..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final uri = Uri.parse(
        'https://aquasense-p36u.onrender.com/api/super-admin/change-password',
      );
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $userToken",
        },
        body: jsonEncode({
          "currentPassword": currentPassword.text,
          "newPassword": newPassword.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["message"] == 'Password changed successfully!') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password changed successfully!")),
        );
        // Clear password fields on success
        currentPassword.clear();
        newPassword.clear();
        confirm_password.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Password change failed: ${data['message'] ?? 'Unknown error'}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error changing password: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // --- END OF PASSWORD CHANGE FUNCTION ---


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
              ? [ASColor.BGSecond, ASColor.BGthird.withOpacity(0.8)]
              : [ASColor.BGFifth, Colors.white.withOpacity(0.95)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: ASColor.getTextColor(context),
                  fontFamily: 'Montserrat',
                ),
              ),
              Text(
                'Manage your account and preferences',
                style: TextStyle(
                  fontSize: 16,
                  color: ASColor.getTextColor(context).withOpacity(0.6),
                  fontFamily: 'Poppins',
                ),
              ),
              
              const SizedBox(height: 24),

              // Enhanced Profile Management Section
              _buildEnhancedSettingsCard(
                icon: Icons.person_rounded,
                title: 'Profile Management',
                subtitle: 'Manage your personal information and security',
                isExpanded: ProfileExpanded,
                onTap: () {
                  setState(() {
                    ProfileExpanded = !ProfileExpanded;
                  });
                },
                child: ProfileExpanded ? buildProfileForm() : null,
                color: Colors.blue,
                isDarkMode: isDarkMode,
              ),

              const SizedBox(height: 16),

              // Enhanced Appearance Section
              _buildEnhancedSettingsCard(
                icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                title: 'App Appearance',
                subtitle: 'Switch between dark and light themes',
                isExpanded: AppearanceExpanded,
                onTap: () {
                  setState(() {
                    AppearanceExpanded = !AppearanceExpanded;
                  });
                },
                child: AppearanceExpanded ? Appearance() : null,
                color: Colors.purple,
                isDarkMode: isDarkMode,
              ),

              const SizedBox(height: 16),

              // Enhanced Logout Section
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode 
                    ? Colors.white.withOpacity(0.05)
                    : Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    'Sign Out',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Montserrat',
                      fontSize: 16,
                      color: ASColor.getTextColor(context),
                    ),
                  ),
                  subtitle: Text(
                    'Sign out from your account',
                    style: TextStyle(
                      color: ASColor.getTextColor(context).withOpacity(0.6),
                      fontFamily: 'Poppins',
                      fontSize: 14,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: ASColor.getTextColor(context).withOpacity(0.4),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          backgroundColor: ASColor.getCardColor(context),
                          title: Text(
                            'Sign Out',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w600,
                              color: ASColor.getTextColor(context),
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to sign out of your account?',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: ASColor.getTextColor(context),
                            ),
                          ),
                          actions: [
                            TextButton(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: ASColor.getTextColor(context).withOpacity(0.6),
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Sign Out',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () async {
                                // Get user token before clearing session
                                final prefs = await SharedPreferences.getInstance();
                                final String? userToken = prefs.getString('userToken');

                                // Notify server about logout with authentication
                                if (userToken != null) {
                                  try {
                                    final response = await http.post(
                                      Uri.parse(ApiConfig.logoutEndpoint),
                                      headers: {
                                        "Content-Type": "application/json",
                                        "Authorization": "Bearer $userToken",
                                      },
                                    );
                                    
                                    if (response.statusCode == 200) {
                                      print("✅ Logout successful on server");
                                    } else {
                                      print("⚠️ Logout response: ${response.statusCode} - ${response.body}");
                                    }
                                  } catch (e) {
                                    print("❌ Logout request failed: $e");
                                  }
                                }

                                // Clear session data
                                await prefs.remove('userToken');
                                await prefs.remove('userId');
                                await prefs.remove('loggedInUsername');
                                await prefs.remove('loggedInEmail');
                                await prefs.remove('loggedInPhone');

                                // Navigate to login screen
                                Navigator.of(context).pop(); // Close dialog
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => LoginScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSettingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget? child,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode 
          ? Colors.white.withOpacity(0.05)
          : Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.black12,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              color: ASColor.getTextColor(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: ASColor.getTextColor(context).withOpacity(0.6),
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ASColor.getTextColor(context).withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (child != null)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: isExpanded ? null : 0,
              child: isExpanded 
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: child,
                  )
                : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  //Light Mode and Dark Mode Design
  Widget Appearance() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: EdgeInsets.only(left: 20, top: 10),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                style: TextStyle(
                  fontSize: 16, // Consider using 16.sp here
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.onBackground,
                ),
              ),
            ),
          ),
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: themeProvider.toggleTheme,
            activeColor: ASColor.buttonBackground(
              context,
            ), // Thumb color when ON
            activeTrackColor: ASColor.BGFourth, // Track color when ON
            inactiveThumbColor: ASColor.BGFourth, // Thumb color when OFF
            inactiveTrackColor: ASColor.buttonBackground(
              context,
            ), // Track color when OFF
          ),
        ],
      ),
    );
  }

  Widget AccountActivityLog() {
    // Mock data – replace this with your actual login/logout history
    final List<Map<String, String>> activityLog = [
      {'action': 'Login', 'timestamp': '2025-05-30 10:42 AM'},
      {'action': 'Logout', 'timestamp': '2025-05-30 11:15 AM'},
      {'action': 'Login', 'timestamp': '2025-05-29 09:08 PM'},
      {'action': 'Login', 'timestamp': '2025-05-30 10:42 AM'},
      {'action': 'Login', 'timestamp': '2025-05-30 10:42 AM'},
      {'action': 'Login', 'timestamp': '2025-05-30 10:42 AM'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ASColor.Background(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Activity',
            style: TextStyle(
              fontSize: 16, // Consider using 16.sp here
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...activityLog.map((entry) {
            final isLogin = entry['action'] == 'Login';
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              dense: true,
              leading: Icon(
                isLogin ? Icons.login : Icons.logout,
                size: 20, // Consider using 20.sp here
                color: isLogin ? Colors.green : Colors.red,
              ),
              title: Text(
                entry['action']!,
                style: TextStyle(
                  fontSize: 14, // Consider using 14.sp here
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                entry['timestamp']!,
                style: TextStyle(
                  fontSize: 12, // Consider using 12.sp here
                  fontFamily: 'Poppins',
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  //Profile Management Design
  Widget buildProfileForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),

          //Username TextField
          TextFormField(
            controller: username,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Fill all the text field';
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: isDarkMode ? Colors.white10 : Colors.black12,
              hintText: 'Username',
              hintStyle: TextStyle(
                color: ASColor.getTextColor(context).withOpacity(0.5),
                fontFamily: 'Poppins',
                fontSize: 14.sp.clamp(12, 16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(
              color: ASColor.getTextColor(context),
              fontFamily: 'Poppins',
              fontSize: 14.sp.clamp(12, 16),
            ),
          ),

          const SizedBox(height: 10),

          // Email field
          TextFormField(
            controller: email,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Fill all the text field';
              }
              // This email validation needs to be more robust.
              // A simple '@' check isn't enough. Consider a regex like:
              // if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              //   return 'Enter a valid email address';
              // }
              if (!value.trim().contains('@')) { // Changed to contains '@'
                return 'Enter a valid email address';
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: isDarkMode ? Colors.white10 : Colors.black12,
              hintText: 'Email',
              hintStyle: TextStyle(
                color: ASColor.getTextColor(context).withOpacity(0.5),
                fontFamily: 'Poppins',
                fontSize: 14.sp.clamp(12, 16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(
              color: ASColor.getTextColor(context),
              fontFamily: 'Poppins',
              fontSize: 14.sp.clamp(12, 16),
            ),
          ),

          const SizedBox(height: 10),

          TextFormField(
            controller: phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Fill all the text field';
              }
              final phone = value.trim();
              if (phone.length != 11 ||
                  !RegExp(r'^\d{11}$').hasMatch(phone)) { // Corrected regex to match 11 digits
                return 'Enter a valid 11-digit phone number';
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: isDarkMode ? Colors.white10 : Colors.black12,
              hintText: 'Phone Number',
              hintStyle: TextStyle(
                color: ASColor.getTextColor(context).withOpacity(0.5),
                fontFamily: 'Poppins',
                fontSize: 14.sp.clamp(12, 16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            style: TextStyle(
              color: ASColor.getTextColor(context),
              fontFamily: 'Poppins',
              fontSize: 14.sp.clamp(12, 16),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: () {
              updateUser(
                context,
                username: username.text.trim(),
                email: email.text.trim(),
                phone: phone.text.trim(),
              );
            },
            icon: Icon(Icons.save, color: ASColor.txt1Color),
            label: Text(
              'Save Profile',
              style: TextStyle(
                color: ASColor.txt1Color,
                fontFamily: 'Poppins',
                fontSize: 14.sp.clamp(12, 16),
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.fromHeight(50),
              backgroundColor: ASColor.buttonBackground(context),
            ),
          ),

          const SizedBox(height: 20),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.lock),
            title: Text(
              'Change Password',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: ASColor.getTextColor(context),
              ),
            ),
            onTap: () {
              // You might want to expand a section here for password fields
              // if you don't want them always visible.
            },
          ),

          const SizedBox(height: 10),

          // Current Password TextField
          TextFormField(
            controller: currentPassword,
            obscureText: _obscurecurrentPassword,
            // For password validation, I've used the original logic,
            // but ensure it's appropriate for your backend's requirements.
            // Note: The example backend only checks length, not complexity.
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Current password is required.';
              }
              // The backend for change-password only checks length, not complexity
              // if (value.length < 8) {
              //   return 'Current password must be at least 8 characters long.';
              // }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: isDarkMode ? Colors.white10 : Colors.black12,
              hintText: 'Current Password',
              hintStyle: TextStyle(
                color: ASColor.getTextColor(context).withOpacity(0.5),
                fontFamily: 'Poppins',
                fontSize: 14.sp.clamp(12, 16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurecurrentPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: ASColor.getTextColor(context).withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _obscurecurrentPassword = !_obscurecurrentPassword;
                  });
                },
              ),
            ),
            style: TextStyle(
              color: ASColor.getTextColor(context),
              fontFamily: 'Poppins',
              fontSize: 14.sp.clamp(12, 16),
            ),
          ),

          const SizedBox(height: 10),

          // New Password TextField
          TextFormField(
            controller: newPassword,
            obscureText: _obscurenewPassword,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'New password is required.';
              }
              final pwd = value.trim();
              List<String> errors = [];
              if (pwd.length < 8) {
                errors.add('• At least 8 characters');
              }
              if (!RegExp(r'[A-Z]').hasMatch(pwd)) {
                errors.add('• At least one capital letter (A-Z)');
              }
              if (!RegExp(r'[0-9]').hasMatch(pwd)) {
                errors.add('• At least one number (0-9)');
              }
              if (!pwd.contains('@') && !pwd.contains('_')) {
                errors.add('• At least one symbol: @ or _');
              }
              if (errors.isNotEmpty) {
                return errors.join('\n');
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: isDarkMode ? Colors.white10 : Colors.black12,
              hintText: 'New Password',
              hintStyle: TextStyle(
                color: ASColor.getTextColor(context).withOpacity(0.5),
                fontFamily: 'Poppins',
                fontSize: 14.sp.clamp(12, 16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurenewPassword ? Icons.visibility_off : Icons.visibility,
                  color: ASColor.getTextColor(context).withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _obscurenewPassword = !_obscurenewPassword;
                  });
                },
              ),
            ),
            style: TextStyle(
              color: ASColor.getTextColor(context),
              fontFamily: 'Poppins',
              fontSize: 14.sp.clamp(12, 16),
            ),
          ),

          SizedBox(height: 10),

          // Confirm New Password TextField
          TextFormField(
            controller: confirm_password,
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Confirm password is required.';
              }
              if (value != newPassword.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: isDarkMode ? Colors.white10 : Colors.black12,
              hintText: 'Confirm Password',
              hintStyle: TextStyle(
                color: ASColor.getTextColor(context).withOpacity(0.5),
                fontFamily: 'Poppins',
                fontSize: 14.sp.clamp(12, 16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: ASColor.getTextColor(context).withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            style: TextStyle(
              color: ASColor.getTextColor(context),
              fontFamily: 'Poppins',
              fontSize: 14.sp.clamp(12, 16),
            ),
          ),

          SizedBox(height: 20),

          // Confirm New Password Button (calls _changePassword)
          ElevatedButton.icon(
            onPressed: () {
              _changePassword(); // <--- This will now call your new password change logic
            },
            icon: Icon(Icons.new_label, color: ASColor.txt1Color),
            label: Text(
              'Confirm New Password',
              style: TextStyle(
                color: ASColor.txt1Color,
                fontFamily: 'Poppins',
                fontSize: 14.sp.clamp(12, 16),
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: Size.fromHeight(50),
              backgroundColor: ASColor.buttonBackground(context),
            ),
          ),
        ],
      ),
    );
  }
}