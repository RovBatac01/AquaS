import 'package:aqua/components/colors.dart';
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
  

  //----------------Default Value for the List of Users----------------

  List<Map<String, String>> users = [
    {"name": "John Doe", "role": "Admin"},
    {"name": "Jane Smith", "role": "User"},
    {"name": "Alice Johnson", "role": "Moderator"},
  ];



  //----------------Build Method for the Account Management Page----------------
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
          title: Text("Edit User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: roleController,
                decoration: InputDecoration(labelText: "Role"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  users[index]["name"] = nameController.text;
                  users[index]["role"] = roleController.text;
                });
                Navigator.pop(context);
              },
              child: Text("Save"),
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
          title: Text("Confirm Deletion"),
          content: Text(
            "Are you sure you want to delete ${users[index]['name']}?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  users.removeAt(index); // ✅ Actually remove the user
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Delete"),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
            ? ASColor.fifthGradient
            : ASColor.fourthGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search and Dropdown (Responsive)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.start,
                children: [
                  SizedBox(
                    width: screenWidth, // Adjust width based on screen size
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: screenWidth * 0.3,
                    child: DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedRole = newValue!;
                        });
                      },
                      items:
                          ['Admin', 'User']
                              .map<DropdownMenuItem<String>>(
                                (String value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                ],
              ),
        
              const SizedBox(height: 20),
        
              // User List Container (Responsive)
              Container(
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 4, // Adds shadow for a lifted effect
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 400,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey, width: 2.0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ListView.separated(
                            padding: EdgeInsets.all(8),
                            itemCount: users.length,
                            separatorBuilder:
                                (context, index) =>
                                    Divider(color: Colors.grey[300]),
                            itemBuilder: (context, index) {
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueAccent,
                                  child: Icon(Icons.person),
                                ),
                                title: Text(
                                  users[index]["name"] ?? "No Name",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(users[index]["role"] ?? "No Role"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () => _editUser(index),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed:
                                          () => _deleteUser(context, index), //
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        
              const SizedBox(height: 20),
        
              // Create Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(15),
                            width: screenWidth * 0.8, // Responsive width
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Create Admin',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      color: ASColor.txt4Color,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        _buildTextField(username, 'Username'),
                                        const SizedBox(height: 15),
                                        _buildTextField(
                                          email,
                                          'Email/Phone Number',
                                        ),
                                        const SizedBox(height: 15),
                                        _buildTextField(
                                          password,
                                          'Password',
                                          obscureText: true,
                                        ),
                                        const SizedBox(height: 15),
                                        _buildTextField(
                                          confirm_password,
                                          'Confirm Password',
                                          obscureText: true,
                                        ),
                                        const SizedBox(height: 15),
                                        // _buildDropdown(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancel",
                                            style: TextStyle(
                                                fontFamily: 'Poppins',
                                                color: ASColor.txt4Color,
                                                fontSize: 16,)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState!.validate()) {
                                            // Perform actions
                                          }
                                        },
                                        child: const Text("Create",
                                            style: TextStyle(
                                                fontFamily: 'Poppins',
                                                color: ASColor.txt4Color,
                                                fontSize: 16,)),
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
                  child: const Text("Create Admin",
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: ASColor.txt4Color,
                          fontSize: 16,)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Reusable TextField Widget
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
          borderSide: const BorderSide(color: Colors.blue, width: 2.0),
        ),
      ),
      style: const TextStyle(fontFamily: 'Poppins'),
      validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
    );
  }

  // Reusable Dropdown Widget
  //   Widget _buildDropdown() {
  //     return DropdownButtonFormField<String>(
  //       value: selectedRole,
  //       decoration: InputDecoration(
  //         labelText: 'Role',
  //         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
  //       ),
  //       onChanged: (String? newValue) {
  //         setState(() {
  //           selectedRole = newValue!;
  //         });
  //       },
  //       items:
  //           ['Admin', 'User'].map((String value) {
  //             return DropdownMenuItem<String>(value: value, child: Text(value));
  //           }).toList(),
  //       validator: (value) => value == null ? 'Please select a role' : null,
  //     );
  //   }
  // }
}
