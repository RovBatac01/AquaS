import 'dart:ui';
import 'package:aqua/components/colors.dart';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/pages/Signup.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For making HTTP requests
import 'dart:convert'; // For JSON encoding/decoding
import 'package:aqua/pages/Login.dart';

void main() {
  runApp(const ForgotPassword());
}

class ForgotPassword extends StatelessWidget {
  const ForgotPassword({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forgot Password',
      debugShowCheckedModeBanner: false,
      home: const ForgotPasswordScreen(),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurenewPassword = true;
  bool _obscureConfirmPassword = true;

  // State variables to track the current stage
  bool _isOTPSent = false;
  bool _isOTPVerified = false;
  String _userEmail = ''; // Store the email for later use
  bool _isLoading = false; // Track loading state to prevent multiple requests

  // Function to send OTP
  Future<void> _sendOTP(BuildContext context) async {
    if (_isLoading) return; // Prevent multiple requests
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showErrorDialog(context, 'Please enter a valid email address.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Replace with your actual API endpoint
    final url = Uri.parse(
      'https://aquasense-p36u.onrender.com/api/forgot-password',
    );
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        }, // Important for sending JSON
        body: json.encode({'email': email}), // Encode the email as JSON
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // OTP sent successfully
          setState(() {
            _isOTPSent = true;
            _userEmail = email; // Store the email
          });
          _showSuccessDialog(
            context,
            responseData['message'] ?? 'OTP sent to your email!',
          );
        } else {
          // Handle error from the API
          _showErrorDialog(
            context,
            responseData['message'] ??
                'Failed to send OTP. Please check your email address.',
          );
        }
      } else {
        // Handle HTTP error
        _showErrorDialog(
          context,
          'Failed to connect to the server. Status code: ${response.statusCode}',
        );
      }
    } catch (error) {
      // Handle network error
      _showErrorDialog(context, 'Error: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to verify OTP
  Future<void> _verifyOTP(BuildContext context) async {
    if (_isLoading) return; // Prevent multiple requests
    setState(() {
      _isLoading = true;
    });
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showErrorDialog(context, 'Please enter the OTP.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Replace with your actual API endpoint
    final url = Uri.parse('https://aquasense-p36u.onrender.com/api/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _userEmail, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // OTP verified successfully
          setState(() {
            _isOTPVerified = true;
          });
          _showSuccessDialog(
            context,
            responseData['message'] ?? 'OTP verified successfully!',
          );
        } else {
          // Handle error from the API
          _showErrorDialog(
            context,
            responseData['message'] ?? 'Invalid OTP. Please try again.',
          );
        }
      } else {
        // Handle HTTP error
        _showErrorDialog(
          context,
          'Failed to connect to the server. Status code: ${response.statusCode}',
        );
      }
    } catch (error) {
      // Handle network error
      _showErrorDialog(context, 'Error: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to change password
  Future<void> _changePassword(BuildContext context) async {
    if (_isLoading) return; // Prevent multiple requests
    setState(() {
      _isLoading = true;
    });
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog(
        context,
        'Please enter both new password and confirm password.',
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (newPassword != confirmPassword) {
      _showErrorDialog(context, 'Passwords do not match.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Replace with your actual API endpoint
    final url = Uri.parse(
      'https://aquasense-p36u.onrender.com/api/change-password',
    );
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _userEmail, 'new_password': newPassword}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          // Password changed successfully
          _showSuccessDialog(
            context,
            responseData['message'] ?? 'Password changed successfully!',
          );
          // Navigate to login screen after successful password change.
          Navigator.of(context).pushReplacement(
            // Use pushReplacement
            MaterialPageRoute(
              builder:
                  (context) =>
                      const LoginScreen(), // Replace LoginScreen() with your actual login page widget
            ),
          );
        } else {
          // Handle error from the API
          _showErrorDialog(
            context,
            responseData['message'] ?? 'Failed to change password.',
          );
        }
      } else {
        // Handle HTTP error
        _showErrorDialog(
          context,
          'Failed to connect to the server. Status code: ${response.statusCode}',
        );
      }
    } catch (error) {
      // Handle network error
      _showErrorDialog(context, 'Error: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper function to show an error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // Helper function to show a success dialog
  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        // This is the next page once you click on forgot password
                        Text(
                          'Forgot Password',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: ASColor.getTextColor(context),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Conditional rendering of UI based on the current stage
                        if (!_isOTPSent) ...[
                          // Show email input
                          Text(
                            'Enter your email to receive an OTP',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: ASColor.getTextColor(context),
                              fontFamily: 'poppins',
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  isDarkMode ? Colors.white10 : Colors.black12,
                              hintText: 'Email',
                              hintStyle: TextStyle(
                                color: ASColor.getTextColor(context),
                              ),
                              prefixIcon: Icon(
                                Icons.email,
                                color: ASColor.getTextColor(context),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _sendOTP(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ASColor.buttonBackground(
                                  context,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : Text(
                                        'Send OTP',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: ASColor.txt1Color,
                                          fontFamily: 'poppins',
                                        ),
                                      ),
                            ),
                          ),
                        ],


                        // Once you input the email and send OTP this is the next page that will be shown
                        if (_isOTPSent && !_isOTPVerified) ...[
                          // Show OTP input
                          Text(
                            'Enter the OTP sent to your email',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: ASColor.getTextColor(context),
                              fontFamily: 'poppins',
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _otpController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  isDarkMode ? Colors.white10 : Colors.black12,
                              hintText: 'Enter OTP',
                              prefixIcon: Icon(
                                Icons.lock,
                                color: ASColor.getTextColor(context),
                              ),
                              hintStyle: TextStyle(
                                color: ASColor.getTextColor(context),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _verifyOTP(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ASColor.buttonBackground(
                                  context,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text(
                                        'Verify OTP',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontFamily: 'poppins',
                                        ),
                                      ),
                            ),
                          ),
                        ],


                        //After OTP is verified this is the next page that will be shown
                        if (_isOTPVerified) ...[
                          // Show new password inputs
                          Text(
                            'Enter your new password',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: ASColor.getTextColor(context),
                              fontFamily: 'poppins',
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: _obscurenewPassword,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  isDarkMode ? Colors.white10 : Colors.black12,
                              hintText: 'New Password',
                              hintStyle: TextStyle(
                                color: ASColor.getTextColor(context),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurenewPassword = !_obscurenewPassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurenewPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: ASColor.getTextColor(context),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor:
                                  isDarkMode ? Colors.white10 : Colors.black12,
                              hintText: 'Confirm Password',
                              hintStyle: TextStyle(
                                color: ASColor.getTextColor(context),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: ASColor.getTextColor(context),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _changePassword(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ASColor.buttonBackground(
                                  context,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text(
                                        'Change Password',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontFamily: 'poppins',
                                        ),
                                      ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back, color: ASColor.getTextColor(context)),
          ),
        ],
      ),
    );
  }
}
