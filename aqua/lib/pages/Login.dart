import 'dart:ui';
import 'package:aqua/pages/ForgotPassword/ForgotPass.dart';
import 'package:aqua/pages/SAdmin/SAdminDashboard.dart';
import 'package:aqua/pages/Signup.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Admin/AdminDashboard.dart';
import 'User/UserDashboard.dart';
// import 'package:flutter_application_1/signup.dart';

void main() {
  runApp(MaterialApp(home: LoginScreen()));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isChecked = false;
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  late SharedPreferences _prefs;

  bool _obscureText = true;
  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  /// Initialize SharedPreferences
  Future<void> _initPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSavedCredentials();
  }

  /// Load saved username & password
  void _loadSavedCredentials() {
    setState(() {
      username.text = _prefs.getString('username') ?? "";
      password.text = _prefs.getString('password') ?? "";
      _isChecked = _prefs.getBool('rememberMe') ?? false;
    });
  }

  /// Save username & password if "Remember Me" is checked
  void _saveCredentials() {
    if (_isChecked) {
      _prefs.setString('username', username.text);
      _prefs.setString('password', password.text);
      _prefs.setBool('rememberMe', true);
    } else {
      _prefs.remove('username');
      _prefs.remove('password');
      _prefs.setBool('rememberMe', false);
    }
  }

  void _login(
    BuildContext context,
    TextEditingController
    usernameController, // Changed parameter name for clarity
    TextEditingController
    passwordController, // Changed parameter name for clarity
  ) async {
    String enteredUsername =
        usernameController.text; // Use the controller's text
    String enteredPassword = passwordController.text;

    if (enteredUsername.isEmpty || enteredPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enter both username and password."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      var response = await http.post(
        Uri.parse("http://localhost:5000/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": enteredUsername,
          "password": enteredPassword,
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String? userRole = jsonResponse['role'];

        print('DEBUG: User role received from backend: "$userRole"');

        if (userRole != null) {
          final normalizedRole = userRole.trim();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Login Successful!"),
              backgroundColor: Colors.green,
            ),
          );

          // --- NEW: Save the logged-in username to SharedPreferences ---
          await _prefs.setString('loggedInUsername', enteredUsername);
          // You might also save the role if you need it persistently on the dashboard
          // await _prefs.setString('loggedInUserRole', normalizedRole);

          if (normalizedRole == 'Super Admin') {
            // Match the exact role string from backend
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Sadmindashboard()),
            );
          } else if (normalizedRole == 'Admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Admindashboard()),
            );
          } else if (normalizedRole == 'User') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Userdashboard()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Unknown user role '$userRole'. Please contact support.",
                ),
                backgroundColor: Colors.yellow,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Login successful, but no role information found in response.",
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        var jsonResponse = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              jsonResponse['error'] ??
                  "Login failed. Please check credentials.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print("Error during login request: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server error. Please try again. ($error)"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDarkMode
              ? Colors.black
              : Colors.white, // Change background based on theme
      body: Stack(
        children: [
          // Always show blurred violet circles in both light and dark mode
          Positioned(
            top: -100,
            left: -100,
            child: ClipOval(
              child: Container(
                width: 300,
                height: 300,
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
                decoration: BoxDecoration(color: Colors.purple),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black87 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Glad you're back",
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: username,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDarkMode ? Colors.white10 : Colors.black12,
                        hintText: 'Username',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.white54 : Colors.black54,
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
                    SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDarkMode ? Colors.white10 : Colors.black12,
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: isDarkMode ? Colors.white54 : Colors.black54,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                          onPressed: _toggleVisibility,
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
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _isChecked,
                          onChanged: (bool? value) {
                            setState(() {
                              _isChecked = value ?? false;
                            });
                            _saveCredentials();
                          },
                          checkColor: isDarkMode ? Colors.black : Colors.white,
                          activeColor:
                              isDarkMode ? Colors.white : Colors.purple,
                        ),
                        Text(
                          "Remember me",
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            "Forgot password?",
                            style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        _login(context, username, password);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.google,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        SizedBox(width: 16),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don’t have an account ?",
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => Signup()),
                            );
                          },
                          child: Text(
                            "Signup",
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
        ],
      ),
    );
  }
}
