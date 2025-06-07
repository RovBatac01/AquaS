import 'dart:ui';
import 'package:aqua/components/colors.dart';
import 'package:aqua/pages/ForgotPassword/ForgotPass.dart';
import 'package:aqua/pages/SAdmin/SAdminDashboard.dart'; // Ensure this points to SuperAdminHomeScreen
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
        Uri.parse("https://aquasense-p36u.onrender.com/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": enteredUsername,
          "password": enteredPassword,
        }),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String? userRole = jsonResponse['role'];
        String? token = jsonResponse['token']; // Get the token
        int? userId = jsonResponse['userId']; // Get the userId (assuming it's an int)

        print('DEBUG: User role received from backend: "$userRole"');
        print('DEBUG: Token received from backend: "$token"'); // Debug print
        print('DEBUG: UserId received from backend: "$userId"'); // Debug print


        if (userRole != null) {
          final normalizedRole = userRole.trim();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Login Successful!"),
              backgroundColor: Colors.green,
            ),
          );

          // --- IMPORTANT: Save the token and userId to SharedPreferences ---
          if (token != null) {
            await _prefs.setString('userToken', token);
          }
          if (userId != null) {
            await _prefs.setInt('userId', userId);
          }
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
                        width: 0.8, // Thin outline
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
                            fillColor:
                                isDarkMode ? Colors.white10 : Colors.black12,
                            hintText: 'Username',
                            hintStyle: TextStyle(
                              color: ASColor.getTextColor(context),),
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
                            fillColor:
                                isDarkMode ? Colors.white10 : Colors.black12,
                            hintText: 'Password',
                            hintStyle: TextStyle(
                              color: ASColor.getTextColor(context), ),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            /// Container holding the CheckboxListTile
                            Expanded(
                              child: Container(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _isChecked,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _isChecked = value ?? false;
                                        });
                                        _saveCredentials();
                                      },
                                      activeColor: ASColor.buttonBackground(context),
                                      
                                      visualDensity:
                                          VisualDensity.compact, // Reduces size
                                      materialTapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap, // Reduces space
                                    ),
                                    Text(
                                      "Remember me",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        color: ASColor.getTextColor(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            /// Forgot Password Button
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Forgot password?",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  color: ASColor.getTextColor(context),
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
                            backgroundColor: ASColor.buttonBackground(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "Login",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: ASColor.txt1Color,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              FontAwesomeIcons.google,
                              color: ASColor.getTextColor(context),
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
                                fontSize: 14,
                                fontFamily: 'Poppins',
                                color: isDarkMode ? ASColor.BGFourth : ASColor.txt2Color,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Signup(),
                                  ),
                                );
                              },
                              child: Text(
                                "Signup",
                                style: TextStyle(color: ASColor.getTextColor(context)
                                    , fontSize: 14, fontFamily: 'Poppins', ),
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
        ],
      ),
    );
  }
}