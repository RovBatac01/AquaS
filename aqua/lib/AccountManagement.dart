import 'package:flutter/material.dart';

class Accountmanagement extends StatefulWidget {
  const Accountmanagement({super.key});

  @override
  State<Accountmanagement> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Accountmanagement> {
  String selectedRole = 'Admin';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
         Padding(padding: EdgeInsets.all(18),
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
         )
        ],
      ),
    );
  }
}
