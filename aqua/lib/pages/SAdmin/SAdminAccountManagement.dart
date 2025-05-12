import 'package:flutter/material.dart';

void main() {
  runApp(const Sadminaccountmanagement());
}

class Sadminaccountmanagement extends StatelessWidget {
  const Sadminaccountmanagement({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: UserListPage(), debugShowCheckedModeBanner: false);
  }
}

class UserListPage extends StatelessWidget {
  final List<Map<String, String>> users = [
    {'name': 'John Doe', 'role': 'Admin'},
    {'name': 'Jane Smith', 'role': 'Moderator'},
    {'name': 'Alice', 'role': 'User'},
    {'name': 'John Doe', 'role': 'Admin'},
    {'name': 'John Doe', 'role': 'Admin'},
    {'name': 'Jane Smith', 'role': 'Moderator'},
    {'name': 'Alice', 'role': 'User'},
    {'name': 'John Doe', 'role': 'Admin'},
  ];

  UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff1edeb),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Top Centered Filter Row
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                child: IntrinsicWidth(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        height: 40,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Select a saved filter',
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      DropdownButton<String>(
                        value: 'All',
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                        ],
                        onChanged: (value) {},
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // User Cards List
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.face),
                      title: Text(user['name']!),
                      subtitle: Text(user['role']!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.purple),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.indigo,
                            ),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
