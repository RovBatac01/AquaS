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
    _fetchEventsForMonth(_selectedDay); // Fetch events for the current month
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

  // Function to fetch events for the entire month
  Future<void> _fetchEventsForMonth(DateTime focusedDay) async {
    try {
      final firstDay = DateTime(focusedDay.year, focusedDay.month, 1);
      final lastDay = DateTime(focusedDay.year, focusedDay.month + 1, 0);
      
      for (DateTime day = firstDay; day.isBefore(lastDay.add(Duration(days: 1))); day = day.add(Duration(days: 1))) {
        final events = await _eventApiService.fetchEventsForDate(day);
        if (events.isNotEmpty) {
          setState(() {
            _events[DateTime(day.year, day.month, day.day)] = events;
          });
        }
      }
    } catch (e) {
      print('Error fetching monthly events: $e');
    }
  }

  // Function to get events for a specific day (for calendar markers)
  List<Event> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _startMidnightTimer() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    _midnightTimer = Timer(durationUntilMidnight, () {
      setState(() {
        _focusedDay = DateTime.now();
        if (_selectedDay.year == now.year &&
            _selectedDay.month == now.month &&
            _selectedDay.day == now.day) {
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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedEvents =
        _events[DateTime(
          _selectedDay.year,
          _selectedDay.month,
          _selectedDay.day,
        )] ??
        [];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode 
              ? [Colors.grey[900]!, Colors.grey[850]!]
              : [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Enhanced Calendar Container
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TableCalendar<Event>(
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                eventLoader: _getEventsForDay,
                selectedDayPredicate: (day) {
                  return _selectedDay.year == day.year &&
                         _selectedDay.month == day.month &&
                         _selectedDay.day == day.day;
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _fetchEventsForSelectedDay(
                    selectedDay,
                  ); // Fetch events for the newly selected day
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _fetchEventsForMonth(focusedDay); // Fetch events when month changes
                },
                calendarStyle: CalendarStyle(
                  // Enhanced Today decoration
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue, width: 2),
                  ),
                  // Enhanced Selected decoration
                  selectedDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  // Style for TODAY's date
                  todayTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontFamily: 'Montserrat',
                  ),
                  // Style for SELECTED
                  selectedTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Montserrat',
                  ),
                  // Style for regular days
                  defaultTextStyle: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  // Weekend styling
                  weekendTextStyle: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  ),
                  // Outside month styling
                  outsideTextStyle: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  ),
                  weekendStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Montserrat',
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  leftChevronIcon: Icon(
                    Icons.chevron_left_rounded,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  rightChevronIcon: Icon(
                    Icons.chevron_right_rounded,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                calendarBuilders: CalendarBuilders<Event>(
                  markerBuilder: (context, date, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

              // Enhanced Selected Date Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.event_rounded,
                            color: Colors.blue,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Selected Date',
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      DateFormat.yMMMMEEEEd().format(_selectedDay),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Montserrat',
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                                                  _fetchEventsForMonth(
                                                    _focusedDay,
                                                  ); // Re-fetch monthly events to update markers
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
                        icon: Icon(Icons.add_rounded, size: 20),
                        label: Text(
                          'Add Schedule',
                          style: TextStyle(
                            fontFamily: 'Poppins', 
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          elevation: 2,
                          shadowColor: Colors.blue.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              // Enhanced Events Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.event_note_rounded,
                            color: Colors.green,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scheduled Events',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  fontFamily: 'Montserrat',
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                DateFormat.MMMMEEEEd().format(_selectedDay),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Enhanced Events List
                    if (selectedEvents.isEmpty)
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_available_rounded,
                                size: 48,
                                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No events scheduled',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Montserrat',
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap "Add Schedule" to create your first event',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                  color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          itemCount: selectedEvents.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final event = selectedEvents[index];
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode 
                                    ? Colors.grey[700]?.withOpacity(0.5)
                                    : Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDarkMode 
                                      ? Colors.grey[600]!.withOpacity(0.3)
                                      : Colors.grey[200]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Event indicator
                                  Container(
                                    width: 4,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Event details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Montserrat',
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        if (event.time != null && event.time!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                size: 12,
                                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                event.time!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontFamily: 'Poppins',
                                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                        if (event.description != null && event.description!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            event.description!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'Poppins',
                                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Delete button
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete_rounded,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                      onPressed: () async {
                                        if (event.id != null) {
                                          try {
                                            await _eventApiService.deleteEvent(event.id!);
                                            _fetchEventsForSelectedDay(_selectedDay);
                                            _fetchEventsForMonth(_focusedDay); // Refresh markers
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Failed to delete event: $e'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
