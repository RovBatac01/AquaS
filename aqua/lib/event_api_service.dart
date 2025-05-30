// lib/services/event_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../event.dart';

class EventApiService {
  // Replace with your actual backend URL
  static const String _baseUrl = 'https://aquasense-p36u.onrender.com/api'; // Use 10.0.2.2 for Android emulator to access localhost

  // Fetch all events
  Future<List<Event>> fetchAllEvents() async {
    final response = await http.get(Uri.parse('$_baseUrl/events-all'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((event) => Event.fromJson(event)).toList();
    } else {
      throw Exception('Failed to load events');
    }
  }

  // Fetch events for a specific date
  Future<List<Event>> fetchEventsForDate(DateTime date) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final response = await http.get(Uri.parse('$_baseUrl/events?date=$formattedDate'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((event) => Event.fromJson(event)).toList();
    } else {
      throw Exception('Failed to load events for date: $formattedDate');
    }
  }

  // Add a new event
  Future<Event> addEvent(Event event) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/events'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(event.toJson()), // Convert Event object to JSON string
    );

    if (response.statusCode == 201) {
      return Event.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add event');
    }
  }

  // Delete an event
  Future<void> deleteEvent(int eventId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/events/$eventId'));

    if (response.statusCode == 200) {
      print('Event deleted successfully');
    } else if (response.statusCode == 404) {
      throw Exception('Event not found.');
    } else {
      throw Exception('Failed to delete event');
    }
  }
}