import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: NotificationPage(),
    debugShowCheckedModeBanner: false,
  ));
}

class NotificationPage extends StatelessWidget {
  final List<Map<String, String>> notifications = [
    {
      'title': 'Warning!!',
      'subtitle': 'There is abnormality to the system.',
      'time': 'Just now',
    },
    {
      'title': 'System Update',
      'subtitle': 'Version 2.0.1 is available now.',
      'time': '1 hour ago',
    },
    {
      'title': 'Reminder',
      'subtitle': 'Meeting with team at 3 PM.',
      'time': 'Today',
    },
    {
      'title': 'Payment Received',
      'subtitle': 'You received \$100 from Alice.',
      'time': 'Yesterday',
    },
    // Repeated for example purposes
    {
      'title': 'Payment Received',
      'subtitle': 'You received \$100 from Alice.',
      'time': 'Yesterday',
    },
    {
      'title': 'Payment Received',
      'subtitle': 'You received \$100 from Alice.',
      'time': 'Yesterday',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'NOTIFICATIONS',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: Icon(Icons.notifications),
              title: Text(
                notification['title']!,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(notification['subtitle']!),
              trailing: Text(
                notification['time']!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationDetailPage(
                      title: notification['title']!,
                      subtitle: notification['subtitle']!,
                      time: notification['time']!,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class NotificationDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;

  const NotificationDetailPage({
    required this.title,
    required this.subtitle,
    required this.time,
    Key? key,
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
