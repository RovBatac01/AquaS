import 'package:flutter/material.dart';
import 'package:aqua/colors.dart'; // Import your custom colors if needed.  I'll assume you have colors defined.

class Accountmanagement extends StatefulWidget {
  const Accountmanagement({super.key});

  @override
  State<Accountmanagement> createState() => _AccountmanagementState();
}

class _AccountmanagementState extends State<Accountmanagement> {
  String selectedRole = 'Admin';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController username = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirm_password = TextEditingController();

  List<Map<String, String>> users = [
    {"name": "John Doe", "role": "Admin"},
    {"name": "Jane Smith", "role": "User"},
    {"name": "Alice Johnson", "role": "Moderator"},
  ];

  void _editUser(int index) {
    TextEditingController nameController = TextEditingController(
      text: users[index]["name"],
    );
    TextEditingController roleController = TextEditingController(
      text: users[index]["role"],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder( // Consistent border radius
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: const Text("Edit User", style: TextStyle(fontFamily: 'Poppins')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)), // consistent input border
                    )),
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: roleController.text,
                decoration: const InputDecoration(
                    labelText: "Role",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)), // consistent input border
                    )),
                items: ['Admin', 'User', 'Moderator']
                    .map((role) =>
                        DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                onChanged: (String? newValue) {
                  roleController.text = newValue!;
                },
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  users[index]["name"] = nameController.text;
                  users[index]["role"] = roleController.text;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder( // consistent button shape
                    borderRadius: BorderRadius.circular(4.0),
                  )),
              child: const Text("Save", style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        );
      },
    );
  }

  void _deleteUser(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder( // consistent dialog shape
            borderRadius: BorderRadius.circular(12.0),
          ),
          title: const Text("Confirm Deletion",
              style: TextStyle(fontFamily: 'Poppins')),
          content: Text(
            "Are you sure you want to delete ${users[index]['name']}?",
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(fontFamily: 'Poppins')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  users.removeAt(index);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder( // consistent button shape
                    borderRadius: BorderRadius.circular(4.0),
                  )),
              child: const Text("Delete", style: TextStyle(fontFamily: 'Poppins')),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
appBar: PreferredSize(
  preferredSize: Size.fromHeight(90.0), // Adjust this value for the desired height
  child: ClipRRect(
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(30.0), // Adjust these values for the desired radius
      bottomRight: Radius.circular(30.0),
    ),
    child: AppBar(
      title: const Padding(
        padding: EdgeInsets.only(left: 10.0),
        child: Text(
          'Account Management',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
            letterSpacing: 1,
          ),
        ),
      ),
      centerTitle: false,
      backgroundColor: Color(0xFF0a782f),
    ),
  ),
),
      backgroundColor: const Color(0xfff0ecec),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( //Wrap the column in SingleChildScrollView
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: OutlineInputBorder( // Added focused border
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
                        ),
                      ),
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(16.0),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Text(
                                      'Create New User',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildTextField(username, 'Username'),
                                    const SizedBox(height: 15),
                                    _buildTextField(email, 'Email/Phone Number'),
                                    const SizedBox(height: 15),
                                    _buildTextField(password, 'Password', obscureText: true),
                                    const SizedBox(height: 15),
                                    _buildTextField(confirm_password, 'Confirm Password',
                                        obscureText: true),
                                    const SizedBox(height: 20),
                                    DropdownButtonFormField<String>( // Added DropdownButtonFormField
                                      value: selectedRole,
                                      decoration: const InputDecoration(
                                          labelText: "Role",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(8.0)), // consistent input border
                                          )),
                                      items: ['Admin', 'User', 'Moderator']
                                          .map((role) =>
                                          DropdownMenuItem(value: role, child: Text(role)))
                                          .toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedRole = newValue!;
                                        });
                                      },
                                      style: const TextStyle(fontFamily: 'Poppins'),
                                    ),
                                    const SizedBox(height: 20),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState!.validate()) {
                                            // Perform create user action
                                            setState(() {
                                              users.add({
                                                "name": username.text,
                                                "role": selectedRole, // Use selectedRole here
                                              });
                                            });
                                            // Clear the form
                                            username.clear();
                                            email.clear();
                                            password.clear();
                                            confirm_password.clear();
                                            Navigator.pop(context); // Close the dialog
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('User created successfully!'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            )),
                                        child: const Text(
                                          'Create User',
                                          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel",
                                            style: TextStyle(fontFamily: 'Poppins')),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder( // consistent button shape
                          borderRadius: BorderRadius.circular(4.0),
                        )),
                    child: const Text("Add New User",
                        style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('User List',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 10),
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(), // Add this line
                shrinkWrap: true,
                itemCount: users.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(users[index]["name"] ?? "No Name",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins')),
                      subtitle: Text(users[index]["role"] ?? "No Role",
                          style: const TextStyle(fontFamily: 'Poppins')),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editUser(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteUser(context, index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        bool obscureText = false,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2.0),
        ),
      ),
      style: const TextStyle(fontFamily: 'Poppins'),
      validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
    );
  }
}

