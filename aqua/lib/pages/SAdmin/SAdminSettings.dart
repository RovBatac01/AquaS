import 'package:aqua/components/colors.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/pages/Theme_Provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(SettingsApp());
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
  final TextEditingController phoneNumber = TextEditingController();
  final TextEditingController currentPassword = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController confirm_password = TextEditingController();
  bool _obscurecurrentPassword = true;
  bool _obscurenewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //List Tile for Profile Management Drop Down
            ListTile(
              leading: Icon(Icons.person),
              title: Text(
                'Profile Management',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: ASColor.getTextColor(context)),
              ),
              subtitle: Text(
                'Manage your personal information and account security.',
                style: TextStyle(
                color: ASColor.getTextColor(context),
                fontFamily: 'Poppins',)
              ),
              trailing: Icon(
                ProfileExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () {
                setState(() {
                  ProfileExpanded = !ProfileExpanded;
                });
              },
            ),
            if (ProfileExpanded) buildProfileForm(),

            SizedBox(height: 20),

            //List Tile for Dark Mode and Light Mode Drop Down
            ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text(
                'App Appearance',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: ASColor.getTextColor(context)),
              ),
              subtitle: Text('Switch between dark and light themes.',
              style: TextStyle(
                color: ASColor.getTextColor(context),
                fontFamily: 'Poppins',)),
              trailing: Icon(
                AppearanceExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () {
                setState(() {
                  AppearanceExpanded = !AppearanceExpanded;
                });
              },
            ),
            if (AppearanceExpanded) Appearance(),

            SizedBox(height: 20),

            //List Tile for Session History
            ListTile(
              leading: Icon(Icons.history_rounded),
              title: Text(
                'Session History',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: ASColor.getTextColor(context)),
              ),
              subtitle: Text('You can monitor your account activity',
              style: TextStyle(
                color: ASColor.getTextColor(context),
                fontFamily: 'Poppins',
              ),),
              trailing: Icon(
                SessionExpanded ? Icons.expand_less : Icons.expand_more,
              ),
              onTap: () {
                setState(() {
                  SessionExpanded = !SessionExpanded;
                });
              },
            ),
            if (SessionExpanded) AccountActivityLog(),

            SizedBox(height: 20,),

            //List tile for LogOut
            ListTile(
              leading: Icon(Icons.logout),
              title: Text(
                'Log Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Montserrat',
                  color: ASColor.getTextColor(context),
                ),
              ),
              trailing: Icon(Icons.arrow_forward_ios, size: 15),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        'Confirm Logout',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: ASColor.getTextColor(context)),
                      ),
                      content: Text(
                        'Are you sure you want to log out?',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ASColor.getTextColor(context)),
                      ),
                      actions: [
                        TextButton(
                          child: Text('Cancel',
                          style: TextStyle(
                            color: ASColor.getTextColor(context),
                            fontFamily: 'Poppins',
                          ),),
                          onPressed:
                              () => Navigator.of(context).pop(), // Close dialog
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ASColor.buttonBackground(context),
                          ),
                          child: Text('Logout',
                          style: TextStyle(
                            color: ASColor.txt1Color,
                            fontFamily: 'Poppins',
                          ),),
                          onPressed: () {
                            Navigator.of(context).pop(); // Close dialog first
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
          ],
        ),
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
                  fontSize: 16,
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
              fontSize: 16,
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
                size: 20,
                color: isLogin ? Colors.green : Colors.red,
              ),
              title: Text(
                entry['action']!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                entry['timestamp']!,
                style: TextStyle(
                  fontSize: 12,
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

  // Help and Support design
  //   Widget AccountActivityLog() {
  //   // Mock data: Replace this with real data from your backend
  //   final List<Map<String, String>> activityLog = [
  //     {
  //       'action': 'Login',
  //       'timestamp': '2025-05-30 10:42 AM',
  //     },
  //     {
  //       'action': 'Logout',
  //       'timestamp': '2025-05-30 11:15 AM',
  //     },
  //     {
  //       'action': 'Login',
  //       'timestamp': '2025-05-29 09:08 PM',
  //     },
  //   ];

  //   return Column(
  //     children: activityLog.map((entry) {
  //       bool isLogin = entry['action'] == 'Login';
  //       return ListTile(
  //         contentPadding: const EdgeInsets.only(
  //           left: 50.0,
  //           right: 16.0,
  //           top: 4.0,
  //           bottom: 4.0,
  //         ),
  //         dense: true,
  //         leading: Icon(
  //           isLogin ? Icons.login : Icons.logout,
  //           size: 20,
  //           color: isLogin
  //               ? Colors.green
  //               : Colors.red,
  //         ),
  //         title: Text(
  //           '${entry['action']}',
  //           style: TextStyle(
  //             fontSize: 14,
  //             fontWeight: FontWeight.w500,
  //             fontFamily: 'Poppins',
  //             color: ASColor.getTextColor(context),
  //           ),
  //         ),
  //         subtitle: Text(
  //           '${entry['timestamp']}',
  //           style: TextStyle(
  //             fontSize: 12,
  //             fontFamily: 'Poppins',
  //             color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
  //             height: 1.3,
  //           ),
  //         ),
  //       );
  //     }).toList(),
  //   );
  // }

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
              if (!value.trim().endsWith('@')) {
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
            controller: phoneNumber,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Fill all the text field';
              }
              final phone = value.trim();
              if (phone.length != 11 ||
                  !RegExp(r'^\d{11}[0m').hasMatch(phone)) {
                return 'Enter a valid phone number';
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
            onPressed: () {},
            icon: Icon(Icons.save,
            color: ASColor.txt1Color,),
            label: Text('Save Profile',
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
            title: Text('Change Password'),
            onTap: () {}, // Can add a toggle here for expansion too
          ),

          const SizedBox(height: 10),

          // Current Password TextField
          TextFormField(
            controller: currentPassword,
            obscureText: _obscurecurrentPassword,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Fill all the text field';
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

          TextFormField(
            controller: newPassword,
            obscureText: _obscurenewPassword,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Fill all the text field';
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

          TextFormField(
            controller: confirm_password,
            obscureText: _obscureConfirmPassword,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Fill all the text field';
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

          ElevatedButton.icon(
            onPressed: () {},
            icon: Icon(Icons.new_label,
            color: ASColor.txt1Color,),
            label: Text('Confirm New Password',
            style: TextStyle(
              color: ASColor.txt1Color,
              fontFamily: 'Poppins',
              fontSize: 14.sp.clamp(12, 16),
            ),),
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
