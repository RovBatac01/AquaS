import 'package:intl/intl.dart';
// lib/models/event.dart
class Event {
  final int? id; // Nullable for new events before they get an ID from the backend
  final String title;
  final String? time;
  final String? description;
  final DateTime eventDate; // Use DateTime for easier manipulation in Flutter

  Event({
    this.id,
    required this.title,
    this.time,
    this.description,
    required this.eventDate,
  });

  // Factory constructor to create an Event from a JSON map (from backend)
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      time: json['time'],
      description: json['description'],
      eventDate: DateTime.parse(json['event_date']), // Parse date string to DateTime
    );
  }

  // Method to convert an Event object to a JSON map (for sending to backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'time': time,
      'description': description,
      'event_date': DateFormat('yyyy-MM-dd').format(eventDate), // Format DateTime to 'YYYY-MM-DD'
    };
  }
}