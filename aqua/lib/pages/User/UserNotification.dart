import 'package:aqua/config/api_config.dart';
import 'package:aqua/NavBar/NotificationDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aqua/components/colors.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserNotification extends StatefulWidget {
  const UserNotification({super.key});

  @override
  _UserNotification createState() => _UserNotification();
}

class _UserNotification extends State<UserNotification> {
  List<Map<String, dynamic>> notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  /// Fetches notifications from the backend
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      if (token == null) {
        setState(() {
          _errorMessage = 'Authentication token not found';
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.apiBase}/notifications/admin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          notifications =
              (data['notifications'] as List).where((notif) {
                // Only show sensor alerts - exclude everything else
                final type = notif['type']?.toString().toLowerCase() ?? '';
                final title = notif['title']?.toString().toLowerCase() ?? '';
                
                // Only allow sensor-related notifications
                return type == 'sensor' || 
                       title.contains('sensor') || 
                       title.contains('turbidity') ||
                       title.contains('ph') ||
                       title.contains('tds') ||
                       title.contains('salinity') ||
                       title.contains('temperature') ||
                       title.contains('alert');
              }).map((notif) {
                return {
                  'id': notif['id'].toString(),
                  'title': notif['title'] ?? 'No Title',
                  'subtitle': notif['message'] ?? 'No Message',
                  'time': _formatTimestamp(notif['createdAt']),
                  'type': notif['type'] ?? 'default',
                  'is_read': notif['read'] == 1 || notif['read'] == true,
                };
              }).toList();
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load notifications: ${response.statusCode} ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error connecting to the server: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Delete a notification
  Future<void> _deleteNotification(String notificationId, int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('userToken');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication token not found')),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.apiBase}/notifications/admin/$notificationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification deleted successfully')),
        );
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete notification: ${errorData['message'] ?? response.reasonPhrase}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
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
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  /// Get notification icon based on type
  Icon _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'sensor':
        return Icon(Icons.sensors, color: Colors.red);
      case 'schedule':
      case 'event':
        return Icon(Icons.calendar_month, color: Colors.blue);
      default:
        return Icon(Icons.notifications, color: Colors.grey);
    }
  }

  /// Build notifications list
  Widget _buildNotificationsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
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
                onPressed: _fetchNotifications,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Text(
          'No notifications to display.',
          style: TextStyle(
            fontSize: 16.sp,
            color: ASColor.getTextColor(context),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const SizedBox.shrink(),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(notification, index);
      },
    );
  }

  /// Build individual notification item
  Widget _buildNotificationItem(Map<String, dynamic> notification, int index) {
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
      child: Container(
        margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
        decoration: BoxDecoration(
          color:
              notification['is_read'] == true
                  ? ASColor.Background(context)
                  : ASColor.Background(context).withOpacity(0.7),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color:
                notification['is_read'] == true
                    ? Colors.grey.withOpacity(0.3)
                    : Colors.blue.withOpacity(0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(16.w),
          leading: _getNotificationIcon(notification['type']),
          title: Text(
            notification['title']!,
            style: TextStyle(
              fontWeight:
                  notification['is_read'] == true
                      ? FontWeight.normal
                      : FontWeight.bold,
              fontSize: 16.sp,
              color: ASColor.getTextColor(context),
              fontFamily: 'Poppins',
            ),
          ),
          subtitle: Text(
            notification['subtitle']!,
            style: TextStyle(
              fontSize: 14.sp,
              color: ASColor.getTextColor(context).withOpacity(0.7),
              fontFamily: 'Poppins',
            ),
          ),
          trailing: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width *
                  0.22, // Max 22% of screen width
              minWidth: 50, // Minimum width to ensure functionality
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        notification['time']!,
                        style: TextStyle(
                          fontSize: 8.sp, // Smaller responsive font size
                          color: ASColor.getTextColor(context).withOpacity(0.5),
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (notification['is_read'] == false)
                      Container(
                        margin: EdgeInsets.only(left: 2.w),
                        width: 4.w,
                        height: 4.h,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: 24.h, // Responsive height
                  width: 24.w, // Responsive width
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 20, minHeight: 20),
                    icon: Icon(
                      Icons.delete,
                      color: Colors.red,
                      size: 14.sp, // Responsive icon size
                    ),
                    onPressed:
                        () => _deleteNotification(notification['id'], index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              isDarkMode
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ASColor.BGSecond,
                      ASColor.BGthird.withOpacity(0.8),
                    ],
                  )
                  : null,
          color: isDarkMode ? null : ASColor.BGfirst,
        ),
        child: SafeArea(
          child: Column(
            children: [


              // Content Area
              Expanded(
                child: _buildNotificationsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
