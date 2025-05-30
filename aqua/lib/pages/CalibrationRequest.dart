import 'dart:ui';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/components/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    MaterialApp(debugShowCheckedModeBanner: false, home: CalibrationRequest()),
  );
}

class CalibrationRequest extends StatefulWidget {
  const CalibrationRequest({super.key});

  @override
  State<CalibrationRequest> createState() => _SignupState();
}

class _SignupState extends State<CalibrationRequest> {
  // Form key for validation and submission
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController username = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phoneNumber = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirm_password = TextEditingController();
  bool isChecked = false;
  DateTime? _selectedDate;
  String? _selectedCourse;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse('https://aquasense-p36u.onrender.com/register'); // Backend URL
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
              padding: EdgeInsets.all(24), // Increased padding on all sides
              child: SizedBox(
                height:
                    MediaQuery.of(context).size.height *
                    0.8, // 80% of screen height
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
                                  'Send Request',
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
                                  "There's a problem with your sensor? Don't worry, you can send a request to us.",
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
                                  hintText: 'Sensor ID',
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
                                  if (!value.trim().endsWith('@')) {
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
                                      !RegExp(r'^\d{11}[0m').hasMatch(phone)) {
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

                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Reason of Request',
                                  filled: true,
                                  border: OutlineInputBorder(),
                                ),
                                value: _selectedCourse,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedCourse = newValue;
                                  });
                                },
                                items:
                                    [
                                      'Sensor Calibration',
                                      'Water Discoloration',
                                    ].map((String course) {
                                      return DropdownMenuItem<String>(
                                        value: course,
                                        child: Text(course),
                                      );
                                    }).toList(),
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select your course';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 20),

                              Row(
                                children: [
                                  Text(
                                    'Date: ${_selectedDate != null ? _selectedDate!.toLocal().toString().split(' ')[0] : 'Not selected'}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.calendar_today),
                                    onPressed: _pickDate,
                                    color: ASColor.buttonBackground(context),
                                  ),
                                ],
                              ),
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
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                  child: const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
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
          ),
        ],
      ),
    );
  }
}
