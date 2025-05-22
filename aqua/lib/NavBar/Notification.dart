import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';

import 'NotificationDetailPage.dart';
import 'package:aqua/components/colors.dart';

void main() {
  runApp(
    MaterialApp(home: NotificationPage(), debugShowCheckedModeBanner: false),
  );
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, String>> notifications = [
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
  ];

  Icon _getNotificationIcon(String title) {
    switch (title.toLowerCase()) {
      case 'warning!!':
        return Icon(Icons.warning, color: Colors.red);
      case 'system update':
        return Icon(Icons.system_update, color: Colors.blue);
      case 'reminder':
        return Icon(Icons.alarm, color: Colors.orange);
      case 'payment received':
        return Icon(Icons.attach_money, color: Colors.green);
      default:
        return Icon(Icons.notifications, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder:
            (context, index) => Divider(height: 1, color: Colors.grey[300]),
        itemBuilder: (context, index) {
          final notification = notifications[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => NotificationDetailPage(
                        title: notification['title']!,
                        subtitle: notification['subtitle']!,
                        time: notification['time']!,
                      ),
                ),
              );
            },
            child: Card(
              color: ASColor.getCardColor(context),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: _getNotificationIcon(notification['title']!),
                title: Text(
                  notification['title']!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: ASColor.getTextColor(context),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification['subtitle']!,
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    Text(
                      notification['time']!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                trailing: Icon(
                  Iconsax.trash,
                  size: 16,
                  color: Colors.red,
                ),
                // trailing: PopupMenuButton<String>(
                //   icon: Container(
                //     padding: EdgeInsets.all(4),
                //     child: Icon(
                //       Icons.more_horiz,
                //       size: 16,
                //       color: ASColor.getTextColor(context),
                //     ),
                //   ),
                //   color:
                //       Theme.of(
                //         context,
                //       ).cardColor, // Use theme card color for popup background
                //   itemBuilder:
                //       (context) => [
                //         PopupMenuItem<String>(
                //           value: 'delete',
                //           child: Center(
                //             child: Icon(
                //               Icons.delete,
                //               color:
                //                   Theme.of(context)
                //                       .colorScheme
                //                       .onSurface, // Use theme text/icon color
                //               size: 20, // Adjust the size as needed
                //             ),
                //           ),
                //         ),
                //       ],
                //   onSelected: (value) {
                //     if (value == 'delete') {
                //       setState(() {
                //         notifications.removeAt(index);
                //       });
                //     }
                //   },
                // ),
              ),
            ),
          );
        },
      ),
    );
  }
}
