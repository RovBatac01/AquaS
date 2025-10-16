import 'dart:ui';
import 'package:aqua/config/api_config.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/pages/OTPVerification.dart';
import 'package:aqua/components/colors.dart';
import 'package:aqua/terms_and_conditions_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: Signup()));
}

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  // Form key for validation and submission
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController username = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phoneNumber = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirm_password = TextEditingController();
  bool isChecked = false;

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Center(
            child: CircularProgressIndicator(
              color: ASColor.buttonBackground(context),
            ),
          ),
    );

    try {
      final url = Uri.parse(ApiConfig.signupEndpoint);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.text.trim(),
          'email': email.text.trim(),
          'phone': phoneNumber.text.trim(),
          'password': password.text,
          'confirm_password': confirm_password.text,
        }),
      );

      Navigator.pop(context); // Remove loading dialog

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Navigate to OTP verification screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => OTPVerificationScreen(
                  email: email.text.trim(),
                  username: username.text.trim(),
                  phoneNumber: phoneNumber.text.trim(),
                  password: password.text,
                ),
          ),
        );
      } else {
        _showErrorDialog(
          responseData['message'] ?? 'Registration failed. Please try again.',
        );
      }
    } catch (error) {
      Navigator.pop(context); // Remove loading dialog
      _showErrorDialog(
        'Network error. Please check your connection and try again.',
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: ASColor.Background(context),
            title: Text(
              'Error',
              style: TextStyle(color: ASColor.getTextColor(context)),
            ),
            content: Text(
              message,
              style: TextStyle(color: ASColor.getTextColor(context)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  bool termsAccepted = false; // Variable to track if terms are accepted
  // Password field
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: ASColor.Background(context),
      body: Stack(
        children: [
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
                        width: 0.8,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: ASColor.getTextColor(context),
                                  fontFamily: 'Monsterat',
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Just some details to get you in!",
                                style: TextStyle(
                                  color: ASColor.getTextColor(context),
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Username field
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
                                fillColor:
                                    isDarkMode
                                        ? Colors.white10
                                        : Colors.black12,
                                hintText: 'Username',
                                hintStyle: TextStyle(
                                  color: ASColor.getTextColor(context),
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(
                                color: ASColor.getTextColor(context),
                                fontFamily: 'Poppins',
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 12),

                            // Email field
                            TextFormField(
                              controller: email,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Fill all the text field';
                                }
                                if (!RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                ).hasMatch(value.trim())) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    isDarkMode
                                        ? Colors.white10
                                        : Colors.black12,
                                hintText: 'Email',
                                hintStyle: TextStyle(
                                  color: ASColor.getTextColor(context),
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(
                                color: ASColor.getTextColor(context),
                                fontFamily: 'Poppins',
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 12),

                            // Phone Number field
                            TextFormField(
                              controller: phoneNumber,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Fill all the text field';
                                }
                                final phone = value.trim();
                                if (phone.length != 11 ||
                                    !RegExp(r'^\d{11}$').hasMatch(phone)) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    isDarkMode
                                        ? Colors.white10
                                        : Colors.black12,
                                hintText: 'Phone Number',
                                hintStyle: TextStyle(
                                  color: ASColor.getTextColor(context),
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              style: TextStyle(
                                color: ASColor.getTextColor(context),
                                fontFamily: 'Poppins',
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 12),

                            // Password field
                            TextFormField(
                              controller: password,
                              obscureText: _obscurePassword,
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
                                  errors.add(
                                    '• At least one capital letter (A-Z)',
                                  );
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
                                fillColor:
                                    isDarkMode
                                        ? Colors.white10
                                        : Colors.black12,
                                hintText: 'Password',
                                hintStyle: TextStyle(
                                  color: ASColor.getTextColor(context),
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: ASColor.getTextColor(
                                      context,
                                    ).withOpacity(0.7),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              style: TextStyle(
                                color: ASColor.getTextColor(context),
                                fontFamily: 'Poppins',
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 12),

                            // Confirm Password field
                            TextFormField(
                              controller: confirm_password,
                              obscureText: _obscureConfirmPassword,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Fill all the text field';
                                }
                                if (value != password.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    isDarkMode
                                        ? Colors.white10
                                        : Colors.black12,
                                hintText: 'Confirm Password',
                                hintStyle: TextStyle(
                                  color: ASColor.getTextColor(context),
                                  fontFamily: 'Poppins',
                                  fontSize: 14.sp,
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
                                    color: ASColor.getTextColor(
                                      context,
                                    ).withOpacity(0.7),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              style: TextStyle(
                                color: ASColor.getTextColor(context),
                                fontFamily: 'Poppins',
                                fontSize: 14.sp,
                              ),
                            ),

                            SizedBox(height: 10),

                            Row(
                              children: [
                                Checkbox(
                                  value: isChecked,
                                  onChanged: (bool? newValue) {
                                    setState(() {
                                      isChecked = newValue ?? false;
                                    });
                                  },
                                  activeColor: ASColor.buttonBackground(
                                    context,
                                  ),
                                ),
                                Flexible(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        color: ASColor.getTextColor(context),
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(text: "I agree to the "),
                                        WidgetSpan(
                                          child: GestureDetector(
                                            onTap: () {
                                              TermsAndConditionsDialog.show(
                                                context,
                                              );
                                            },
                                            child: Text(
                                              "terms and conditions",
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                color: Colors.blue,
                                                fontSize: 14,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            SizedBox(height: 10),
                            // Sign Up button
                            Center(
                              child: ElevatedButton(
                                onPressed:
                                    isChecked
                                        ? () {
                                          if (_formKey.currentState!
                                              .validate()) {
                                            registerUser();
                                          }
                                        }
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ASColor.buttonBackground(
                                    context,
                                  ),
                                  foregroundColor: ASColor.getTextColor(
                                    context,
                                  ),
                                ),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: ASColor.txt1Color,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(
                                    color: ASColor.getTextColor(context),
                                    fontFamily: 'Poppins',
                                    fontSize: 14.sp,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginScreen(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Login",
                                    style: TextStyle(
                                      color: ASColor.getTextColor(context),
                                      fontFamily: 'Poppins',
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
