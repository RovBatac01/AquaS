import 'package:aqua/components/colors.dart';
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
      home: AdminSettingsScreen(),
    );
  }
}

class AdminSettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<AdminSettingsScreen> {
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode 
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.white12 : Colors.black12,
                    width: 1,
                  ),
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
                        Icons.settings_rounded,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: ASColor.getTextColor(context),
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage your account and preferences',
                            style: TextStyle(
                              fontSize: 14,
                              color: ASColor.getTextColor(context).withOpacity(0.7),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            // Enhanced Profile Management Section
            buildEnhancedSettingsCard(
              context: context,
              icon: Icons.person_rounded,
              title: 'Profile Management',
              subtitle: 'Manage your personal information and account security',
              isExpanded: ProfileExpanded,
              onTap: () {
                setState(() {
                  ProfileExpanded = !ProfileExpanded;
                });
              },
            ),
            if (ProfileExpanded) buildEnhancedProfileForm(),

            const SizedBox(height: 16),

            // Enhanced App Appearance Section
            buildEnhancedSettingsCard(
              context: context,
              icon: Icons.palette_rounded,
              title: 'App Appearance',
              subtitle: 'Switch between dark and light themes',
              isExpanded: AppearanceExpanded,
              onTap: () {
                setState(() {
                  AppearanceExpanded = !AppearanceExpanded;
                });
              },
            ),
            if (AppearanceExpanded) buildEnhancedAppearance(),

            const SizedBox(height: 16),

            // Enhanced Help and Support Section
            buildEnhancedSettingsCard(
              context: context,
              icon: Icons.help_rounded,
              title: 'Help and Support',
              subtitle: 'Get assistance and answers to your questions',
              isExpanded: FAQExpanded,
              onTap: () {
                setState(() {
                  FAQExpanded = !FAQExpanded;
                });
              },
            ),
            if (FAQExpanded) buildEnhancedQuestion(),

            const SizedBox(height: 16),

            // Enhanced Session History Section
            buildEnhancedSettingsCard(
              context: context,
              icon: Icons.history_rounded,
              title: 'Session History',
              subtitle: 'Monitor your account activity and login history',
              isExpanded: SessionExpanded,
              onTap: () {
                setState(() {
                  SessionExpanded = !SessionExpanded;
                });
              },
            ),
            if (SessionExpanded) buildEnhancedAccountActivityLog(),

            const SizedBox(height: 24),

            // Enhanced Logout Section
            Container(
              width: double.infinity,
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
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showEnhancedLogoutDialog(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Log Out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.red.withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced UI Components
  Widget buildEnhancedSettingsCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ASColor.getTextColor(context),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: ASColor.getTextColor(context).withOpacity(0.7),
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: ASColor.getTextColor(context).withOpacity(0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildEnhancedProfileForm() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? Colors.white.withOpacity(0.03)
          : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Update Profile Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ASColor.getTextColor(context),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          buildProfileForm(),
        ],
      ),
    );
  }

  Widget buildEnhancedAppearance() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? Colors.white.withOpacity(0.03)
          : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode 
                ? Colors.orange.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              themeProvider.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: themeProvider.isDarkMode ? Colors.orange : Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: ASColor.getTextColor(context),
                  ),
                ),
                Text(
                  'Currently active theme',
                  style: TextStyle(
                    fontSize: 12,
                    color: ASColor.getTextColor(context).withOpacity(0.6),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: themeProvider.toggleTheme,
            activeColor: Colors.blue,
            activeTrackColor: Colors.blue.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget buildEnhancedQuestion() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? Colors.white.withOpacity(0.03)
          : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Support',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                    color: ASColor.getTextColor(context),
                  ),
                ),
                Text(
                  'Get help with your account or report issues',
                  style: TextStyle(
                    fontSize: 12,
                    color: ASColor.getTextColor(context).withOpacity(0.6),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: ASColor.getTextColor(context).withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget buildEnhancedAccountActivityLog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, String>> activityLog = [
      {'action': 'Login', 'timestamp': '2025-05-30 10:42 AM'},
      {'action': 'Logout', 'timestamp': '2025-05-30 11:15 AM'},
      {'action': 'Login', 'timestamp': '2025-05-29 09:08 PM'},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode 
          ? Colors.white.withOpacity(0.03)
          : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ASColor.getTextColor(context),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          ...activityLog.map((entry) {
            final isLogin = entry['action'] == 'Login';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isLogin 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      isLogin ? Icons.login_rounded : Icons.logout_rounded,
                      size: 16,
                      color: isLogin ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry['action']!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                            color: ASColor.getTextColor(context),
                          ),
                        ),
                        Text(
                          entry['timestamp']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Poppins',
                            color: ASColor.getTextColor(context).withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void showEnhancedLogoutDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? ASColor.BGSecond : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: ASColor.getTextColor(context),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out? You\'ll need to sign in again to access your account.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: ASColor.getTextColor(context).withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: ASColor.getTextColor(context),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
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
                'Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to login - you'll need to import the Login screen
              },
            ),
          ],
        );
      },
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

  //Help And Support Design
  Widget Question() {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.only(
            left: 50.0,
            right: 16.0,
            top: 4.0,
            bottom: 4.0,
          ),
          dense: true, // Makes the tile more compact
          leading: Icon(
            Icons.support_agent_outlined,
            size: 20,
            color: ASColor.getTextColor(context),
          ),
          title: Text(
            'Contact Support',
            style: TextStyle(
              fontSize: 14.sp.clamp(12, 16),
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
              color: ASColor.getTextColor(context),
            ),
          ),
          subtitle: Text(
            'If you have any questions, reach us',
            style: TextStyle(
              fontSize: 12.sp.clamp(12, 16),
              color: ASColor.getTextColor(context).withOpacity(0.7),
              fontFamily: 'Poppins',
              height: 1.3,
            ),
          ),
          onTap: () {
            // Optional: Add behavior here
          },
        ),
      ],
    );
  }

  //
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
            icon: Icon(Icons.save, color: ASColor.txt1Color),
            label: Text(
              'Save Profile',
              style: TextStyle(
                color: ASColor.txt1Color,
                fontFamily: 'Poppins',
                fontSize: 16.sp.clamp(14, 18),
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
            icon: Icon(Icons.new_label, color: ASColor.txt1Color),
            label: Text(
              'Confirm New Password',
              style: TextStyle(
                color: ASColor.txt1Color,
                fontFamily: 'Poppins',
                fontSize: 16.sp.clamp(14, 18),
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
