import 'dart:ui';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/components/colors.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: AddAccount()));
}

class AddAccount extends StatefulWidget {
  const AddAccount({super.key});

  @override
  State<AddAccount> createState() => _SignupState();
}

class _SignupState extends State<AddAccount> {
  // Form key for validation and submission
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController username = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirm_password = TextEditingController();
  bool isChecked = false;

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse('https://aquas-production.up.railway.app/register'); // Backend URL
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.text.trim(),
        'email': email.text.trim(),
        'password': password.text,
        "confirm_password": password.text,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      print(responseData['message']); // Success message
    } else {
      print('Error: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: ASColor.Background(context),
      body: Stack(
        children: [
          // Always show blurred violet circles in both light and dark mod
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back, color: ASColor.getTextColor(context)),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (isDarkMode ? ASColor.BGthird : ASColor.BGFifth)
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                        width: 0.8, // Thin outline
                      ),
                    ),
                    child: Form(
                      key: _formKey, // Attach the form key
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Create Admin',
                              style: TextStyle(
                                color: ASColor.getTextColor(context),
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Just some details to get you in!",
                              style: TextStyle(
                                color: ASColor.getTextColor(
                                  context,
                                ).withOpacity(0.7),
                                fontSize: 14,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          // Username field
                          TextFormField(
                            controller: username,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  isDarkMode ? Colors.white10 : Colors.black12,
                              labelText: 'Username',
                              labelStyle: TextStyle(
                                color: ASColor.getTextColor(
                                  context,
                                ).withOpacity(0.7),
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(
                                Iconsax.user,
                                color: ASColor.getTextColor(
                                  context,
                                ).withOpacity(0.7),
                              ),
                            ),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: ASColor.getTextColor(context),
                              fontSize: 14,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Username';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          // Email/Phone field
                          TextFormField(
                            controller: email,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  isDarkMode ? Colors.white10 : Colors.black12,
                              labelText: 'Email/Phone Number',
                              labelStyle: TextStyle(
                                color: ASColor.getTextColor(
                                  context,
                                ).withOpacity(0.7),
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(
                                Icons.email,
                                color: ASColor.getTextColor(
                                  context,
                                ).withOpacity(0.7),
                              ),
                            ),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: ASColor.getTextColor(context),
                              fontSize: 14,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Email';
                              }
                              bool isEmail = RegExp(
                                r'^\S+@\S+\.\S+[0m',
                              ).hasMatch(value);
                              bool isPhone = RegExp(
                                r'^\d{11}[0m',
                              ).hasMatch(value);
                              if (!isEmail && !isPhone) {
                                return 'Please enter a valid Email or Phone number';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          // Password field
                          TextFormField(
                            controller: password,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  isDarkMode ? Colors.white10 : Colors.black12,
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                color: ASColor.getTextColor(
                                  context,
                                ).withOpacity(0.7),
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(
                                Iconsax.lock,
                                color: ASColor.getTextColor(
                                  context,
                                ).withOpacity(0.7),
                              ),
                            ),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: ASColor.getTextColor(context),
                              fontSize: 14,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Password';
                              }
                              bool hasMinLength = value.length >= 8;
                              bool hasUpperCase = RegExp(
                                r'[A-Z]',
                              ).hasMatch(value);
                              bool hasNumber = RegExp(r'[0-9]').hasMatch(value);
                              bool hasSpecialChar = RegExp(
                                r'[@_]',
                              ).hasMatch(value);
                              if (hasMinLength &&
                                  hasUpperCase &&
                                  hasNumber &&
                                  hasSpecialChar) {
                                return null;
                              }
                              List<String> errors = [];
                              if (value.length < 8) {
                                errors.add('• At least 8 characters');
                              }
                              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                errors.add('• At least one uppercase letter');
                              }
                              if (!RegExp(r'[0-9]').hasMatch(value)) {
                                errors.add('• At least one number');
                              }
                              if (!RegExp(r'[@_]').hasMatch(value)) {
                                errors.add(
                                  '• At least one special character (@ or _)',
                                );
                              }
                              if (errors.isNotEmpty) {
                                return errors.join('\n');
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          // Confirm Password field
                          TextFormField(
                            controller: confirm_password,
                            obscureText: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  isDarkMode ? Colors.white10 : Colors.black12,
                              labelText: 'Confirm Password',
                              labelStyle: TextStyle(
                                color: ASColor.getTextColor(
                                  context,
                                ).withOpacity(0.7),
                                fontFamily: 'Poppins',
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: Icon(
                                Iconsax.lock,
                                color: ASColor.getTextColor(
                                  context,
                                ).withOpacity(0.7),
                              ),
                            ),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: ASColor.getTextColor(context),
                              fontSize: 14,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm the password';
                              } else if (value != password.text) {
                                return 'It does not match the password';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: registerUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ASColor.buttonBackground(context),
                                foregroundColor: Colors.white,
                                textStyle: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text(
                                'Add Account',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
