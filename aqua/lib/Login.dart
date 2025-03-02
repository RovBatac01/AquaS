import 'dart:ui';
import 'package:aqua/AdminDashboard.dart';
import 'package:aqua/Signup.dart';
import 'package:aqua/UserDashboard.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final String fixedUsername = "admin";
  final String fixedPassword = "123";
  late SharedPreferences _prefs;

  //------------------------------Function for the password toggle visibility

  bool _obscureText = true;
  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
  //-------------------------------------------------------------------------

  //-------------------------------Function for Remember me

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

  //Need to be change when connecting to Database
  void _login() {
    String enteredUsername = username.text;
    String enteredPassword = password.text;

    if (enteredUsername == fixedUsername && enteredPassword == fixedPassword) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Userdashboard()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login Successful!"),
          backgroundColor: Colors.green,
        ),
      );
      // // Navigate to another screen if needed
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid Username or Password"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
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
                        "Glad you're back",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    SizedBox(height: 20),

                    //Username and Password-------------------------------------
                    TextField(
                      controller: username,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white10,
                        hintText: 'Username',
                        hintStyle: TextStyle(color: Colors.white54),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white10,
                        hintText: 'Password',
                        hintStyle: TextStyle(color: Colors.white54),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed: _toggleVisibility,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    //Username and Password-------------------------------------


                    SizedBox(height: 12),

                    //Remember me and forgot password---------------------------
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
                        ),
                        Text(
                          "Remember me",
                          style: TextStyle(color: Colors.white70),
                        ),
                        Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "Forgot password?",
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _login,
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
                        Icon(FontAwesomeIcons.google, color: Colors.white),
                        SizedBox(width: 16),
                      ],
                    ),

                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don’t have an account ?",
                          style: TextStyle(color: Colors.white70),
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
