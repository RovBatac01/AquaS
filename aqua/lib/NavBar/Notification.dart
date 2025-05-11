import 'package:flutter/material.dart';
import 'NotificationDetailPage.dart';

void main() {
  runApp(
    MaterialApp(home: NotificationPage(), debugShowCheckedModeBanner: false),
  );
}

class NotificationPage extends StatefulWidget {
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

  //Start of the code for the selection and deletion of the notification
  Set<int> selectedIndexes = {};
  bool get isSelectionMode => selectedIndexes.isNotEmpty;

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

  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndexes.contains(index)) {
        selectedIndexes.remove(index);
      } else {
        selectedIndexes.add(index);
      }
    });
  }

  void _deleteSelected() {
    setState(() {
      notifications = notifications
          .asMap()
          .entries
          .where((entry) => !selectedIndexes.contains(entry.key))
          .map((entry) => entry.value)
          .toList();
      selectedIndexes.clear();
    });
  }

  void _selectAll() {
    setState(() {
      selectedIndexes = Set.from(List.generate(notifications.length, (i) => i));
    });
  }
  //End of the code for the selection and deletion of the notification

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: isSelectionMode
          ? AppBar(
              title: Text('${selectedIndexes.length} selected'),
              backgroundColor: Colors.deepPurple,
              actions: [
                IconButton(
                  icon: Icon(Icons.select_all),
                  onPressed: _selectAll,
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: _deleteSelected,
                ),
              ],
            )
          : null,
      body: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: Colors.grey[300]),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final isSelected = selectedIndexes.contains(index);

          return GestureDetector(
            onLongPress: () => _toggleSelection(index),
            onTap: () {
              if (isSelectionMode) {
                _toggleSelection(index);
              } else {
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
              }
            },
            child: Card(
              color: isSelected ? Colors.deepPurple[50] : null,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    color: isSelected ? Colors.deepPurple : Colors.black,
                  ),
                ),
                subtitle: Text(notification['subtitle']!),
                trailing: Text(
                  notification['time']!,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}



