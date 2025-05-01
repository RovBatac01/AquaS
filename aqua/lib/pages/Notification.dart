import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For more readable time formatting

void main() {
  runApp(MaterialApp(
    home: NotificationPage(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'Roboto', // A clean and widely used font
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true, // Opt-in for Material 3 design
    ),
  ));
}

class NotificationPage extends StatelessWidget {
  final List<Map<String, String>> notifications = [
    {
      'title': 'Warning!!',
      'subtitle': 'There is abnormality to the system.',
      'time': DateTime.now().toString(),
    },
    {
      'title': 'System Update',
      'subtitle': 'Version 2.0.1 is available now.',
      'time': DateTime.now().subtract(const Duration(hours: 1)).toString(),
    },
    {
      'title': 'Reminder',
      'subtitle': 'Meeting with team at 3 PM.',
      'time': DateTime.now().toString(),
    },
    {
      'title': 'Payment Received',
      'subtitle': 'You received \$100 from Alice.',
      'time': DateTime.now().subtract(const Duration(days: 1)).toString(),
    },
    // Repeated for example purposes
    {
      'title': 'Payment Received',
      'subtitle': 'You received \$100 from Alice.',
      'time': DateTime.now().subtract(const Duration(days: 1)).toString(),
    },
    {
      'title': 'Payment Received',
      'subtitle': 'You received \$100 from Alice.',
      'time': DateTime.now().subtract(const Duration(days: 1)).toString(),
    },
  ];

  String _formatTime(String rawTime) {
    final dateTime = DateTime.parse(rawTime);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference < const Duration(minutes: 1)) {
      return 'Just now';
    } else if (difference < const Duration(hours: 1)) {
      return '${difference.inMinutes} min ago';
    } else if (difference < const Duration(days: 1)) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference < const Duration(days: 7)) {
      return DateFormat('EEE').format(dateTime); // e.g., Mon, Tue
    } else {
      return DateFormat('MMM d').format(dateTime); // e.g., May 1
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Divider(height: 1), // Minimal divider
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: const Icon(Icons.notifications_outlined), // Outlined icon for a lighter feel
            title: Text(
              notification['title']!,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              notification['subtitle']!,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            trailing: Text(
              _formatTime(notification['time']!),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationDetailPage(
                    title: notification['title']!,
                    subtitle: notification['subtitle']!,
                    time: _formatTime(notification['time']!),
                  ),
                ),
              );
            },
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
        title: const Text('Notification Details'),
        elevation: 1, // Subtle shadow for detail page app bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 16, height: 1.4), // Improved line height
            ),
          ],
        ),
      ),
    );
  }
}