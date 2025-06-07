import 'package:aqua/components/colors.dart';
import 'package:aqua/pages/SAdmin/AddAccount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const Sadminaccountmanagement());
}

class Sadminaccountmanagement extends StatelessWidget {
  const Sadminaccountmanagement({super.key});

  @override
  Widget build(BuildContext context) {
    return UserListPage(); // Removed inner MaterialApp
  }
}

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;

  final TextEditingController _searchController = TextEditingController();
  String _selectedRoleFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://aquasense-p36u.onrender.com/users'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> fetchedData = jsonDecode(response.body);
        setState(() {
          _users = fetchedData.cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load users: ${response.statusCode}';
          _isLoading = false;
        });
        print('Server error: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
        _isLoading = false;
      });
      print('Error fetching users: $e');
    }
  }

  // --- NEW: Function to handle user updates ---
  Future<void> _updateUser(
    int userId,
    String newUsername,
    String newRole,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('https://aquasense-p36u.onrender.com/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': newUsername, 'role': newRole}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully!')),
        );
        _fetchUsers(); // Refresh the list
      } else {
        final errorBody = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update user: ${errorBody['error'] ?? response.reasonPhrase}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating user: $e')));
    }
  }

  // --- NEW: Function to handle user deletion ---
  Future<void> _deleteUser(int userId, String username) async {
    final bool confirm =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Deletion'),
              content: Text(
                'Are you sure you want to delete user "$username"?',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // In case dialog is dismissed by tapping outside

    if (confirm) {
      try {
        final response = await http.delete(
          Uri.parse('https://aquasense-p36u.onrender.com/users/$userId'),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted successfully!')),
          );
          _fetchUsers(); // Refresh the list
        } else {
          final errorBody = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to delete user: ${errorBody['error'] ?? response.reasonPhrase}',
              ),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting user: $e')));
      }
    }
  }

  // --- NEW: Function to show edit dialog ---
  void _showEditDialog(Map<String, dynamic> user) {
    final TextEditingController usernameController = TextEditingController(
      text: user['username'],
    );
    String selectedRole =
        user['role'] ?? 'User'; // Default to 'User' if role is null

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(
                    value: 'Super Admin',
                    child: Text('Super Admin'),
                  ),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'User', child: Text('User')),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    selectedRole = newValue; // Update the selected role
                  }
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Call update function
                _updateUser(
                  user['id'], // Assuming 'id' is available in the fetched user map
                  usernameController.text,
                  selectedRole,
                );
                Navigator.of(context).pop(); // Close dialog after action
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Filtered list based on search and role
  List<Map<String, dynamic>> get _filteredUsers {
    List<Map<String, dynamic>> filtered = _users;

    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered =
          filtered.where((user) {
            return user['username']?.toLowerCase().contains(query) ?? false;
          }).toList();
    }

    if (_selectedRoleFilter != 'All') {
      filtered =
          filtered.where((user) {
            return user['role'] == _selectedRoleFilter;
          }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Top Centered Filter Row
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: IntrinsicWidth(
                  child: Row(
                    children: [
                      Expanded(
                        // makes the search bar take all remaining space
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              hintText: 'Search username',
                              hintStyle: TextStyle(
                                color: ASColor.getTextColor(context),
                                fontFamily: 'Poppins',
                                fontSize: 14.sp.clamp(12, 16)
                              ),
                              prefixIcon: const Icon(Icons.search),
                              contentPadding: const EdgeInsets.only(
                                bottom: 15.0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 100, // Optional: shrink or grow this if needed
                        child: DropdownButton<String>(
                          isExpanded:
                              true, // Important to avoid overflow inside Dropdown
                          value: _selectedRoleFilter,
                          items: const [
                            DropdownMenuItem(value: 'All', child: Text('All')),
                            DropdownMenuItem(
                              value: 'Super Admin',
                              child: Text('Super Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'Admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'User',
                              child: Text('User'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRoleFilter = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // User Cards List or Loading/Error Indicator
            _isLoading  ? const Center(child: CircularProgressIndicator()) : _error != null ? 
              Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
                : Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchUsers,
                    child: ListView.builder(
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: ASColor.getCardColor(
                            context,
                          ), // Use adaptive card color
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.face),
                            title: Text(
                              user['username']!,
                              style: TextStyle(
                                color: ASColor.getTextColor(context),
                                fontSize: 14.sp.clamp(12, 16),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            subtitle: Text(
                              user['role']!,
                              style: TextStyle(
                                color: ASColor.getTextColor(context),
                                fontSize: 14.sp.clamp(12, 16),
                                fontFamily: 'Poppins',
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // --- Call edit function on press ---
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: ASColor.getTextColor(context),
                                  ),
                                  onPressed: () {
                                    _showEditDialog(user); // Open edit dialog
                                  },
                                ),
                                // --- Call delete function on press ---
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: ASColor.getTextColor(context),
                                  ),
                                  onPressed: () {
                                    _deleteUser(
                                      user['id'],
                                      user['username'],
                                    ); // Pass ID and username
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ASColor.buttonBackground(context),
        onPressed: () {
          setState(() {
            // Add your action here, e.g., navigate to a new page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddAccount()),
            );
          });
        },
        child: Icon(Icons.add, color: ASColor.BGFifth),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat, // Bottom right
    );
  }
}
