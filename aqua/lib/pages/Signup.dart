import 'dart:ui';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/components/colors.dart';
import 'package:flutter/material.dart';
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

    final url = Uri.parse('http://localhost:5000/register'); // Backend URL
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

  bool termsAccepted = false; // Variable to track if terms are accepted

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ASColor.Background(context),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Form(
                  key: _formKey, // Attach the form key
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: Colors.white,
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
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      SizedBox(height: 20),

                      // Username field
                      TextFormField(
                        controller: username,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white10,
                          labelText: 'Username',
                          labelStyle: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Poppins',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ASColor.getTextColor(context),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Username';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Email field
                      TextFormField(
                        controller: email,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white10,
                          labelText: 'Email',
                          labelStyle: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Poppins',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ASColor.getTextColor(context),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Email';
                          }
                          bool isEmail = RegExp(
                            r'^\S+@\S+\.\S+$',
                          ).hasMatch(value);
                          if (!isEmail) {
                            return 'Please enter a valid Email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Phone Number field
                      TextFormField(
                        controller: phoneNumber,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white10,
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Poppins',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ASColor.getTextColor(context),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Phone Number';
                          }
                          // Regular expression for phone number validation (11 digits)
                          bool isPhone = RegExp(r'^\d{11}$').hasMatch(value);
                          if (!isPhone) {
                            return 'Please enter a valid Phone number (11 digits)';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Password field
                      TextFormField(
                        controller: password,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white10,
                          labelText: 'Password',
                          labelStyle: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Poppins',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ASColor.getTextColor(context),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Password';
                          }

                          bool hasMinLength = value.length >= 8;
                          bool hasUpperCase = RegExp(r'[A-Z]').hasMatch(value);
                          bool hasNumber = RegExp(r'[0-9]').hasMatch(value);
                          bool hasSpecialChar = RegExp(r'[@_]').hasMatch(value);

                          // Check if ALL conditions are met
                          if (hasMinLength &&
                              hasUpperCase &&
                              hasNumber &&
                              hasSpecialChar) {
                            return null; // Password is valid
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

                          // If there are errors, join them into a single string
                          if (errors.isNotEmpty) {
                            return errors.join('\n');
                          }

                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Confirm Password field
                      TextFormField(
                        controller: confirm_password,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white10,
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(
                            color: Colors.white54,
                            fontFamily: 'Poppins',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ASColor.getTextColor(context),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm the passowrd';
                          } else if (value != password.text) {
                            return 'It is not match to the password';
                          }
                          return null;
                        },
                      ),

                      Row(
                        children: [
                          Checkbox(
                            value: isChecked,
                            onChanged: (bool? newValue) {
                              setState(() {
                                isChecked = newValue ?? false;
                              });
                            },
                          ),
                          Flexible(
                            child: TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  barrierDismissible:
                                      false, // Prevent closing by tapping outside
                                  builder: (BuildContext context) {
                                    bool localAccepted = false;

                                    return StatefulBuilder(
                                      builder: (context, setState) {
                                        return Dialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: SizedBox(
                                            height:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.75,
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                    16.0,
                                                  ),
                                                  child: Text(
                                                    'Terms and Conditions',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 18,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                const Divider(height: 1),
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16.0,
                                                        ),
                                                    child: Text(
                                                      '''1. Acceptance of Terms

By creating an account or using our services, you acknowledge that you have read, understood, and agree to be bound by these Terms.

2. User Accounts

You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.

3. Use of Services

You agree to use our services only for lawful purposes and in a manner that does not infringe the rights of or restrict or inhibit anyone else's use and enjoyment of our services.

4. Privacy Policy

Your use of our services is also governed by our Privacy Policy, which is incorporated into these Terms by reference. Please review our Privacy Policy to understand our practices regarding your personal information.

5. Intellectual Property

The content, trademarks, service marks, and logos on our services are owned by or licensed to us and are subject to copyright and other intellectual property rights.

6. Disclaimer of Warranties

Our services are provided on an "as is" and "as available" basis without any warranties of any kind, express or implied.

7. Limitation of Liability

To the fullest extent permitted by applicable law, we shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising out of or relating to your use of our services.

8. Governing Law

These Terms shall be governed by and construed in accordance with the laws of [Your Country/State], without regard to its conflict of law provisions.

9. Changes to Terms

We reserve the right to modify or revise these Terms at any time. Your continued use of our services after any such changes constitutes your acceptance of the new Terms.

10. Contact Us

If you have any questions about these Terms, please contact us at [Your Contact Information].
''',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontFamily: 'Poppins',
                                                        color: Colors.black87,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16.0,
                                                      ),
                                                  child: CheckboxListTile(
                                                    contentPadding:
                                                        EdgeInsets.zero,
                                                    controlAffinity:
                                                        ListTileControlAffinity
                                                            .leading,
                                                    title: Text(
                                                      "I have read and agree to the terms and conditions",
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                    value: localAccepted,
                                                    onChanged: (bool? value) {
                                                      setState(() {
                                                        localAccepted =
                                                            value ?? false;
                                                      });
                                                    },
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      localAccepted
                                                          ? () {
                                                            Navigator.of(
                                                              context,
                                                            ).pop();
                                                          }
                                                          : null, // Disable if not accepted
                                                  child: Text(
                                                    "Close",
                                                    style: TextStyle(
                                                      color:
                                                          localAccepted
                                                              ? Colors.blue
                                                              : Colors.grey,
                                                      fontSize: 14,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                );
                              },

                              style: ButtonStyle(
                                overlayColor: MaterialStateProperty.all(
                                  Colors.transparent,
                                ), // No ripple
                                splashFactory:
                                    NoSplash
                                        .splashFactory, // Optional: remove all splash behavior
                                padding: MaterialStateProperty.all(
                                  EdgeInsets.zero,
                                ), // Optional: remove default padding
                              ),
                              child: Text(
                                "I agree to the terms and conditions",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: ASColor.getTextColor(context),
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Sign Up button
                      Center(
                        child: ElevatedButton(
                          onPressed: isChecked ? registerUser : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              // color is handled by foregroundColor above
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
                            style: TextStyle(color: Colors.white70),
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
                              style: TextStyle(color: Colors.purple),
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
        ],
      ),
    );
  }
}
