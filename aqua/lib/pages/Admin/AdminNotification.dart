import 'package:aqua/NavBar/NotificationDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconsax/iconsax.dart';
import 'package:aqua/components/colors.dart'; // Assuming this file defines ASColor
import 'package:http/http.dart' as http; // Import for making HTTP requests
import 'dart:convert'; // Import for JSON encoding/decoding

void main() {
  runApp(
    MaterialApp(home: AdminNotification(), debugShowCheckedModeBanner: false),
  );
}

class AdminNotification extends StatefulWidget {
  const AdminNotification({super.key});

  @override
  _AdminNotification createState() => _AdminNotification();
}

class _AdminNotification extends State<AdminNotification> {
  // Use a List of Map<String, dynamic> to accommodate various data types from backend
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = true; // To show a loading indicator
  String? _errorMessage; // To display any fetch errors

  @override
  void initState() {
    super.initState();
    _fetchNotifications(); // Call the fetch function when the widget initializes
  }

  /// Fetches notifications from the backend API.
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true; // Set loading state to true
      _errorMessage = null; // Clear any previous error messages
    });

    try {
      // The endpoint for Super Admin notifications (unauthenticated)
      final response = await http.get(
        Uri.parse('https://aquasense-p36u.onrender.com/api/notifications/admin'), // <-- Adjust your backend URL if different
        headers: {
          'Content-Type': 'application/json',
          // No 'Authorization' header needed for this unauthenticated endpoint
        },
      );

      if (response.statusCode == 200) {
        // Decode the JSON response. The backend is expected to return a list directly.
        final List<dynamic> fetchedNotifications = json.decode(response.body);

        setState(() {
          notifications = fetchedNotifications.map((notif) {
            // Map backend fields to your local notification structure.
            // Ensure the keys match what your backend returns (e.g., 'id', 'type', 'title', 'message', 'createdAt', 'read').
            return {
              'id': notif['id'].toString(), // Convert ID to string for consistency
              'title': notif['title'] ?? 'No Title', // Use 'title' from backend
              'subtitle': notif['message'] ?? 'No Message', // Use 'message' from backend as 'subtitle'
              'time': _formatTimestamp(notif['createdAt']), // Format 'createdAt' from backend
              'type': notif['type'] ?? 'default', // Use 'type' for icon mapping
              'is_read': notif['read'] == 1 || notif['read'] == true, // Handle boolean from DB (int 1/0 or actual boolean)
            };
          }).toList();
        });
      } else {
        // Handle non-200 responses (e.g., 404, 500)
        setState(() {
          _errorMessage = 'Failed to load notifications: ${response.statusCode} ${response.reasonPhrase}';
        });
        print('Failed to load notifications: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // Handle network errors or other exceptions during the HTTP request
      setState(() {
        _errorMessage = 'Error connecting to the server: $e';
      });
      print('Error fetching notifications: $e');
    } finally {
      setState(() {
        _isLoading = false; // Always set loading to false when done
      });
    }
  }

  /// Deletes a notification from the backend and updates the UI.
  Future<void> _deleteNotification(String notificationId, int index) async {
    try {
      final response = await http.delete(
        Uri.parse('https://aquasense-p36u.onrender.com/api/notifications/superadmin/$notificationId'), // <-- Adjust your backend URL if different
        headers: {
          'Content-Type': 'application/json',
          // No 'Authorization' header needed for this unauthenticated endpoint
        },
      );

      if (response.statusCode == 200) {
        // If deletion is successful, remove the item from the local list
        setState(() {
          notifications.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification deleted successfully!')),
        );
      } else {
        // Parse error message from backend if available
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete notification: ${errorData['message'] ?? response.reasonPhrase}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  /// Helper function to format a timestamp string into a human-readable relative time.
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      // Parse the timestamp string received from the backend
      final dateTime = DateTime.parse(timestamp).toLocal(); // Convert to local time zone
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        // For older notifications, display the date
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      // If parsing fails, return the original timestamp string
      print('Error formatting timestamp: $e');
      return timestamp;
    }
  }

  /// Returns an appropriate icon based on the notification type from the backend.
  Icon _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sensor':
        return Icon(Icons.sensors, color: Colors.red); // For sensor alerts
      case 'schedule':
        return Icon(Icons.calendar_month, color: Colors.blue); // For scheduled events
      case 'request':
        return Icon(Icons.pending_actions, color: Colors.orange); // For access requests
      case 'new_user':
        return Icon(Icons.person_add, color: Colors.green); // For new user registrations
      default:
        return Icon(Icons.notifications, color: Colors.grey); // Default icon
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
              ? [ASColor.BGSecond, ASColor.BGthird.withOpacity(0.8)]
              : [ASColor.BGFifth, Colors.white.withOpacity(0.95)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode 
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode ? Colors.white12 : Colors.black12,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.notifications_rounded,
                        color: Colors.blue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: ASColor.getTextColor(context),
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${notifications.length} notifications',
                            style: TextStyle(
                              fontSize: 14,
                              color: ASColor.getTextColor(context).withOpacity(0.7),
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content Area
              Expanded(
                child: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : _errorMessage != null
              ? Center(
                  // Show error message if fetch failed
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red, fontSize: 16.sp),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchNotifications, // Retry button
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : notifications.isEmpty
                  ? Center(
                      // Show message if no notifications are found
                      child: Text(
                        'No notifications to display.',
                        style: TextStyle(fontSize: 16.sp, color: ASColor.getTextColor(context)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox.shrink(), // Remove the default divider between list items
                      itemBuilder: (context, index) {
                        final notification = notifications[index];

                        return GestureDetector(
                          onTap: () {
                            // Navigate to detail page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationDetailPage(
                                  title: notification['title']!,
                                  subtitle: notification['subtitle']!,
                                  time: notification['time']!,
                                  // You might pass other details to the detail page if needed
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.fromLTRB(
                              16.w,
                              index == 0 ? 8.h : 0,
                              16.w,
                              12.h,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isDarkMode ? Colors.white12 : Colors.black12,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16.w),
                              leading: _getNotificationIcon(notification['type']!), // Use 'type' for icon
                              title: Text(
                                notification['title']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                  color: ASColor.getTextColor(context),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notification['subtitle']!,
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    notification['time']!,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12.sp),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Iconsax.trash, size: 16, color: Colors.red),
                                onPressed: () async {
                                  // Show confirmation dialog before deleting
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        'Delete Notification',
                                        style: TextStyle(
                                          fontFamily: 'Montserrat',
                                          fontSize: 18.sp,
                                        ),
                                      ),
                                      content: const Text(
                                        'Are you sure you want to delete this notification?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 16.sp,
                                              color: ASColor.getTextColor(context),
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 16.sp,
                                              color: ASColor.getTextColor(context),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && notification['id'] != null) {
                                    // Call delete function if confirmed
                                    _deleteNotification(notification['id'], index);
                                  }
                                },
                                tooltip: 'Delete notification',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}