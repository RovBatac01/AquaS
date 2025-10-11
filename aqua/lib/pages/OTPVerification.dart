import 'dart:ui';
import 'package:aqua/pages/Login.dart';
import 'package:aqua/components/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OTPVerificationScreen extends StatefulWidget {
  final String email;
  final String username;
  final String phoneNumber;
  final String password;
  
  const OTPVerificationScreen({
    super.key,
    required this.email,
    required this.username,
    required this.phoneNumber,
    required this.password,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResendLoading = false;

  Future<void> _verifyOTP() async {
    if (_isLoading) return;
    
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      _showErrorDialog('Please enter the OTP');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('https://aquasense-p36u.onrender.com/api/verify-signup-otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': otp,
          'username': widget.username,
          'phone': widget.phoneNumber,
          'password': widget.password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _showSuccessDialog('Account verified successfully!');
      } else {
        _showErrorDialog(responseData['message'] ?? 'Invalid OTP. Please try again.');
      }
    } catch (error) {
      _showErrorDialog('Network error. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    if (_isResendLoading) return;

    setState(() {
      _isResendLoading = true;
    });

    try {
      final url = Uri.parse('https://aquasense-p36u.onrender.com/api/resend-signup-otp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.email}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        _showSuccessDialog('OTP resent successfully!');
      } else {
        _showErrorDialog(responseData['message'] ?? 'Failed to resend OTP.');
      }
    } catch (error) {
      _showErrorDialog('Network error. Please try again.');
    } finally {
      setState(() {
        _isResendLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ASColor.Background(context),
        title: Text(
          'Success',
          style: TextStyle(color: ASColor.getTextColor(context)),
        ),
        content: Text(
          message,
          style: TextStyle(color: ASColor.getTextColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
            child: const Text('Login Now'),
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ASColor.getTextColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(24),
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
                    // Title
                    Text(
                      'Verify Your Email',
                      style: TextStyle(
                        color: ASColor.getTextColor(context),
                        fontFamily: 'Montserrat',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We\'ve sent a verification code to',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ASColor.getTextColor(context),
                        fontFamily: 'Poppins',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: ASColor.getTextColor(context),
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // OTP Input
                    TextFormField(
                      controller: _otpController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDarkMode ? Colors.white10 : Colors.black12,
                        hintText: 'Enter 6-digit code',
                        hintStyle: TextStyle(
                          color: ASColor.getTextColor(context),
                          fontFamily: 'Poppins',
                          fontSize: 14.sp,
                        ),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: ASColor.getTextColor(context).withOpacity(0.7),
                        ),
                      ),
                      style: TextStyle(
                        color: ASColor.getTextColor(context),
                        fontFamily: 'Poppins',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ASColor.buttonBackground(context),
                          foregroundColor: ASColor.txt1Color,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : const Text(
                                'Verify Email',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Resend OTP
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyle(
                            color: ASColor.getTextColor(context),
                            fontFamily: 'Poppins',
                            fontSize: 14.sp,
                          ),
                        ),
                        TextButton(
                          onPressed: _isResendLoading ? null : _resendOTP,
                          child: _isResendLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: ASColor.getTextColor(context),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Resend',
                                  style: TextStyle(
                                    color: ASColor.getTextColor(context),
                                    fontFamily: 'Poppins',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
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
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}