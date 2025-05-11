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
        "confirm_password": password.text
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background blur circles
          Positioned(
            top: -100,
            left: -100,
            child: ClipOval(
              child: Container(
                width: 300,
                height: 400,
                decoration: BoxDecoration(color: Colors.purple),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 70, sigmaY: 50),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -80,
            child: ClipOval(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(color: ASColor.BGfourth),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),

          // Form content
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
                          labelText: 'Username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color:
                                  ASColor
                                      .BGfifth, // Outline color when the field is focused
                              width: 2.0, // Thickness of the outline
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color:
                                  ASColor
                                      .BGfifth, // Outline color when the field is not focused
                              width: 1.5, // Thickness of the outline
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ASColor.txt2Color,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Username';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Email/Phone field
                      TextFormField(
                        controller: email,
                        decoration: InputDecoration(
                          labelText: 'Email/Phone Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color:
                                  ASColor
                                      .BGfifth, // Outline color when the field is focused
                              width: 2.0, // Thickness of the outline
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color:
                                  ASColor
                                      .BGfifth, // Outline color when the field is not focused
                              width: 1.5, // Thickness of the outline
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ASColor.txt2Color,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your Email';
                          }
                          bool isEmail = RegExp(
                            r'^\S+@\S+\.\S+$',
                          ).hasMatch(value);

                          // Regular expression for phone number validation (10-15 digits)
                          bool isPhone = RegExp(r'^\d{11}$').hasMatch(value);

                          if (!isEmail && !isPhone) {
                            return 'Please enter a valid Email or Phone number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 12),

                      // Password field
                      TextFormField(
                        controller: password,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color:
                                  ASColor
                                      .BGfifth, // Outline color when the field is focused
                              width: 2.0, // Thickness of the outline
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color:
                                  ASColor
                                      .BGfifth, // Outline color when the field is not focused
                              width: 1.5, // Thickness of the outline
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ASColor.txt2Color,
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
                          if (hasMinLength && hasUpperCase && hasNumber && hasSpecialChar) {
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
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color:
                                  ASColor
                                      .BGfifth, // Outline color when the field is focused
                              width: 2.0, // Thickness of the outline
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                              color:
                                  ASColor
                                      .BGfifth, // Outline color when the field is not focused
                              width: 1.5, // Thickness of the outline
                            ),
                          ),
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ASColor.txt2Color,
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


                      CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text("I agree to the terms and conditions",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ASColor.txt2Color,
                          fontSize: 14,
                        ),),
                        value: isChecked,
                        onChanged: (bool? newValue) {
                          setState(() {
                            isChecked = newValue ?? false;
                          });
                        },
                      ),

                      // Sign Up button
                      Center(
                        child: ElevatedButton(
                        onPressed: registerUser,
                        style: ElevatedButton.styleFrom(backgroundColor: ASColor.BGfifth),
                        child: const Text('Sign Up'),
                                              ),
                                            ),                      SizedBox(height: 20),


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
