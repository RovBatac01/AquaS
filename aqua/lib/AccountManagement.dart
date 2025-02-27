import 'package:aqua/colors.dart';
import 'package:flutter/material.dart';

class Accountmanagement extends StatefulWidget {
  const Accountmanagement({super.key});

  @override
  State<Accountmanagement> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Accountmanagement> {
  String selectedRole = 'Admin';

  final _formKey = GlobalKey<FormState>();

  final TextEditingController username = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirm_password = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                // Search Field with Icon
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: Icon(Icons.search), // Search icon
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10), // Space between search and dropdown
                // Dropdown for Admin/User Selection
                DropdownButton<String>(
                  value: selectedRole,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRole = newValue!;
                    });
                  },
                  items:
                      ['Admin', 'User'].map<DropdownMenuItem<String>>((
                        String value,
                      ) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: 20),
            child: Column(
              children: [
                Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.transparent, // Keep background transparent
                    border: Border.all(
                      color: ASColor.BGfourth, // Change to desired border color
                      width: 2.0, // Border thickness
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SingleChildScrollView(child: Column(children: [
                      ],
                    )),
                ),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ), // Optional: Rounded corners
                    child: Container(
                      width:
                          MediaQuery.of(context).size.width *
                          0.8, // Adjust width
                      padding: EdgeInsets.all(20), // Padding inside dialog
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min, // Prevent excessive height
                          children: [
                            Text(
                              'Create Admin',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 20,
                              ),
                            ),
                            SizedBox(height: 20),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: username,
                                    decoration: InputDecoration(
                                      labelText: 'Username',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              ASColor
                                                  .BGfifth, // Outline color when the field is focused
                                          width:
                                              2.0, // Thickness of the outline
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        borderSide: BorderSide(
                                          color: ASColor.BGfifth,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(fontFamily: 'Poppins'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your Username';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 15),

                                  TextFormField(
                                    controller: email,
                                    decoration: InputDecoration(
                                      labelText: 'Email/Phone Number',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              ASColor
                                                  .BGfifth, // Outline color when the field is focused
                                          width:
                                              2.0, // Thickness of the outline
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              ASColor
                                                  .BGfifth, // Outline color when the field is not focused
                                          width:
                                              1.5, // Thickness of the outline
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(fontFamily: 'Poppins'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your Email';
                                      }
                                      bool isEmail = RegExp(
                                        r'^\S+@\S+\.\S+$',
                                      ).hasMatch(value);

                                      // Regular expression for phone number validation (10-15 digits)
                                      bool isPhone = RegExp(
                                        r'^\d{10,15}$',
                                      ).hasMatch(value);

                                      if (!isEmail && !isPhone) {
                                        return 'Please enter a valid Email or Phone number';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 15),

                                  TextFormField(
                                    controller: password,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              ASColor
                                                  .BGfifth, // Outline color when the field is focused
                                          width:
                                              2.0, // Thickness of the outline
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              ASColor
                                                  .BGfifth, // Outline color when the field is not focused
                                          width:
                                              1.5, // Thickness of the outline
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(fontFamily: 'Poppins'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your Password';
                                      }

                                      bool hasMinLength = value.length >= 8;
                                      bool hasUpperCase = RegExp(
                                        r'[A-Z]',
                                      ).hasMatch(value);
                                      bool hasNumber = RegExp(
                                        r'[0-9]',
                                      ).hasMatch(value);
                                      bool hasSpecialChar = RegExp(
                                        r'[@_]',
                                      ).hasMatch(value);

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
                                        errors.add(
                                          '• At least one uppercase letter',
                                        );
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

                                  SizedBox(height: 15),

                                  TextFormField(
                                    controller: confirm_password,
                                    decoration: InputDecoration(
                                      labelText: 'Confirm Password',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              ASColor
                                                  .BGfifth, // Outline color when the field is focused
                                          width:
                                              2.0, // Thickness of the outline
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                        borderSide: BorderSide(
                                          color:
                                              ASColor
                                                  .BGfifth, // Outline color when the field is not focused
                                          width:
                                              1.5, // Thickness of the outline
                                        ),
                                      ),
                                    ),
                                    style: TextStyle(fontFamily: 'Poppins'),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please confirm the passowrd';
                                      } else if (value != password.text) {
                                        return 'It is not match to the password';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 15),

                                  DropdownButtonFormField<String>(
                                    value: selectedRole,
                                    decoration: InputDecoration(
                                      labelText: 'Role',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          8.0,
                                        ),
                                      ),
                                    ),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedRole = newValue!;
                                      });
                                    },
                                    items:
                                        [
                                          'Admin',
                                          'User',
                                        ].map<DropdownMenuItem<String>>((
                                          String value,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                    validator:
                                        (value) =>
                                            value == null
                                                ? 'Please select a role'
                                                : null,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("Cancel"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('Form Submitted'),
                                            content: Text(
                                              'Username: ${username.text}\n'
                                              'Email/phone: ${email.text}\n'
                                              'Password: ${password.text}\n',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('OK'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }
                                  },
                                  child: Text('Register'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },

            child: Icon(Icons.add), // Floating action button icon
          ),
        ],
      ),
    );
  }
}
