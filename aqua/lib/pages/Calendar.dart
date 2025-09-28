import 'dart:ui';
import 'package:aqua/pages/TimePicker.dart'; // Make sure this path is correct
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:aqua/components/colors.dart'; // Make sure this path is correct
import 'dart:async';

// Import the new files
import 'package:aqua/event.dart'; // Ensure this path is correct
import 'package:aqua/event_api_service.dart'; // Ensure this path is correct

void main() {
  runApp(MaterialApp(home: CalendarPage(), debugShowCheckedModeBanner: false));
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  final Map<DateTime, List<Event>> _events = {}; // Change type to List<Event>
  Timer? _midnightTimer;
  final EventApiService _eventApiService =
      EventApiService(); // Initialize the API service

  @override
  void initState() {
    super.initState();
    _fetchEventsForSelectedDay(_selectedDay); // Fetch initial events
    _startMidnightTimer();
  }

  // Function to fetch events for a given date
  Future<void> _fetchEventsForSelectedDay(DateTime date) async {
    try {
      final events = await _eventApiService.fetchEventsForDate(date);
      setState(() {
        // Clear existing events for the day and add the fetched ones
        _events[DateTime(date.year, date.month, date.day)] = events;
      });
    } catch (e) {
      print('Error fetching events: $e');
      // Optionally show an error message to the user
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load events: $e')));
    }
  }

  void _startMidnightTimer() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    _midnightTimer = Timer(durationUntilMidnight, () {
      setState(() {
        _focusedDay = DateTime.now();
        if (isSameDay(_selectedDay, now)) {
          _selectedDay = _focusedDay;
        }
      });
      _fetchEventsForSelectedDay(
        _selectedDay,
      ); // Re-fetch events for the new day
      _startMidnightTimer(); // Schedule the next midnight
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents =
        _events[DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
        )] ??
        [];

    return Scaffold(
      backgroundColor: ASColor.Background(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              TableCalendar(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _fetchEventsForSelectedDay(
                    selectedDay,
                  ); // Fetch events for the newly selected day
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(), // No background
                  selectedDecoration: BoxDecoration(), // No background
                  // Style for TODAY's date
                  todayTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),

                  // Style for SELECTED
                  selectedTextStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        Colors
                            .green, // Changed the selected date color to green
                  ),

                  // Style for the current day when it's not selected
                  defaultTextStyle: TextStyle(
                    fontSize: 14.sp.clamp(12, 16), // Normal size
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontWeight: FontWeight.w600),
                  weekendStyle: TextStyle(fontWeight: FontWeight.w600),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: ASColor.getTextColor(
                      context,
                    ), // Set your desired border color here
                    width: 1, // Set the thickness of the border
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Date:',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMMEEEEd().format(_selectedDay),
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final titleController = TextEditingController();
                          final timeController = TextEditingController();
                          final descController = TextEditingController();

                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            barrierColor: Colors.black.withOpacity(0.9),
                            builder:
                                (context) => Stack(
                                  children: [
                                    BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 8,
                                        sigmaY: 8,
                                      ),
                                      child: Container(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                    Center(
                                      child: AlertDialog(
                                        backgroundColor: ASColor.getCardColor(
                                          context,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        title: Text(
                                          'Add Schedule',
                                          style: TextStyle(
                                            color: ASColor.getTextColor(
                                              context,
                                            ),
                                            fontFamily: 'Montserrat',
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: SizedBox(
                                          height: 300,
                                          width: 300,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              TextFormField(
                                                controller: titleController,
                                                maxLines:
                                                    null, // Allows multi-line input if needed
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor:
                                                      Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Colors.white10
                                                          : Colors.black12,
                                                  labelText: 'Schedule Title',
                                                  labelStyle: TextStyle(
                                                    color: ASColor.getTextColor(
                                                      context,
                                                    ),
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14.sp.clamp(
                                                      12,
                                                      16,
                                                    ),
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  color: ASColor.getTextColor(
                                                    context,
                                                  ),
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14.sp.clamp(12, 16),
                                                ),
                                              ),

                                              SizedBox(height: 20),

                                              TextFormField(
                                                controller: timeController,
                                                readOnly:
                                                    true, // prevents keyboard from showing
                                                onTap: () async {
                                                  final now = DateTime.now();
                                                  int hour = now.hour;
                                                  final minute = now.minute;
                                                  String period = 'AM';

                                                  if (hour >= 12) {
                                                    period = 'PM';
                                                    if (hour > 12) hour -= 12;
                                                  }
                                                  if (hour == 0)
                                                    hour = 12; // Midnight fix

                                                  final selectedTime =
                                                      await showDialog<String>(
                                                        context: context,
                                                        builder:
                                                            (context) => Dialog(
                                                              child: SizedBox(
                                                                height: 250,
                                                                child: TimePickerDialogContent(
                                                                  initialHour:
                                                                      hour,
                                                                  initialMinute:
                                                                      minute,
                                                                  initialPeriod:
                                                                      period,
                                                                ),
                                                              ),
                                                            ),
                                                      );

                                                  if (selectedTime != null) {
                                                    timeController.text =
                                                        selectedTime;
                                                  }
                                                },
                                                decoration: InputDecoration(
                                                  labelText: 'Time',
                                                  labelStyle: TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14,
                                                    color: ASColor.getTextColor(
                                                      context,
                                                    ),
                                                  ),
                                                  filled:
                                                      true, // Enable background fill
                                                  fillColor:
                                                      Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Colors
                                                              .white10 // Dark mode background
                                                          : Colors
                                                              .black12, // Light mode background
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    borderSide:
                                                        BorderSide
                                                            .none, // Remove border outline
                                                  ),
                                                  enabledBorder: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    borderSide:
                                                        BorderSide
                                                            .none, // Remove border outline
                                                  ),
                                                  focusedBorder: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    borderSide:
                                                        BorderSide
                                                            .none, // Remove border outline
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  color: ASColor.getTextColor(
                                                    context,
                                                  ),
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14.sp.clamp(12, 16),
                                                ),
                                              ),

                                              SizedBox(height: 20),

                                              TextFormField(
                                                controller: descController,
                                                minLines:
                                                    4, // Set minimum height
                                                maxLines:
                                                    8, // Allow expansion if needed
                                                decoration: InputDecoration(
                                                  filled: true,
                                                  fillColor:
                                                      Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.dark
                                                          ? Colors.white10
                                                          : Colors.black12,
                                                  labelText: 'Description',
                                                  alignLabelWithHint:
                                                      true, // Keeps label at the top start
                                                  labelStyle: TextStyle(
                                                    color: ASColor.getTextColor(
                                                      context,
                                                    ),
                                                    fontFamily: 'Poppins',
                                                    fontSize: 14.sp.clamp(
                                                      12,
                                                      16,
                                                    ),
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                ),
                                                style: TextStyle(
                                                  color: ASColor.getTextColor(
                                                    context,
                                                  ),
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14.sp.clamp(12, 16),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: ASColor.getTextColor(
                                                  context,
                                                ),
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              // Make it async
                                              final date = _selectedDay;
                                              final title =
                                                  titleController.text;
                                              final time = timeController.text;
                                              final desc = descController.text;

                                              if (title.isNotEmpty) {
                                                // Only title is strictly required by backend
                                                try {
                                                  final newEvent = Event(
                                                    title: title,
                                                    time:
                                                        time.isNotEmpty
                                                            ? time
                                                            : null, // Pass null if empty
                                                    description:
                                                        desc.isNotEmpty
                                                            ? desc
                                                            : null, // Pass null if empty
                                                    eventDate: date,
                                                  );
                                                  await _eventApiService
                                                      .addEvent(newEvent);
                                                  Navigator.of(context).pop();
                                                  _fetchEventsForSelectedDay(
                                                    date,
                                                  ); // Re-fetch events after adding
                                                } catch (e) {
                                                  print(
                                                    'Error adding event: $e',
                                                  );
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Failed to add event: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } else {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Schedule title cannot be empty.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  ASColor.buttonBackground(
                                                    context,
                                                  ),
                                              foregroundColor: Colors.white,
                                            ),
                                            child: Text(
                                              'Add Schedule',
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        },
                        icon: Icon(Icons.add, size: 18),
                        label: Text(
                          'Add Schedule',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ASColor.buttonBackground(context),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                height: 300, // Fixed height for the events container
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ASColor.getTextColor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Events for ${DateFormat.yMMMMEEEEd().format(_selectedDay)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              color: ASColor.getTextColor(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (selectedEvents.isEmpty)
                        Center(
                          child: Text(
                            'No events for this date',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: ASColor.getTextColor(
                                context,
                              ).withOpacity(0.6),
                            ),
                          ),
                        )
                      else
                        // Use ListView.builder for potentially long lists of events
                        Expanded(
                          child: ListView.builder(
                            itemCount: selectedEvents.length,
                            itemBuilder: (context, index) {
                              final event = selectedEvents[index];
                              return ListTile(
                                title: Text(
                                  event.title,
                                  style: TextStyle(
                                    color: ASColor.getTextColor(context),
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (event.time != null &&
                                        event.time!.isNotEmpty)
                                      Text(
                                        'Time: ${event.time}',
                                        style: TextStyle(
                                          color: ASColor.getTextColor(
                                            context,
                                          ).withOpacity(0.8),
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                    if (event.description != null &&
                                        event.description!.isNotEmpty)
                                      Text(
                                        event.description!,
                                        style: TextStyle(
                                          color: ASColor.getTextColor(
                                            context,
                                          ).withOpacity(0.8),
                                          fontFamily: 'Poppins',
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    if (event.id != null) {
                                      try {
                                        await _eventApiService.deleteEvent(
                                          event.id!,
                                        );
                                        _fetchEventsForSelectedDay(
                                          _selectedDay,
                                        ); // Re-fetch events after deleting
                                      } catch (e) {
                                        print('Error deleting event: $e');
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to delete event: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
