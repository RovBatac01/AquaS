import 'package:flutter/material.dart';

class NotificationDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;

  const NotificationDetailPage({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification Details'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 16),
            Text(
              subtitle,
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
