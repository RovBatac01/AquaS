import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:aqua/components/colors.dart';
import 'dart:async';

void main() {
  runApp(MaterialApp(home: CalendarPage(), debugShowCheckedModeBanner: false));
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final Map<DateTime, List<String>> _events = {};
  Timer? _midnightTimer;

  @override
  void initState() {
    super.initState();
    _startMidnightTimer();
  }

  void _startMidnightTimer() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    _midnightTimer = Timer(durationUntilMidnight, () {
      setState(() {
        _focusedDay = DateTime.now();
        if (_selectedDay != null && isSameDay(_selectedDay, now)) {
          _selectedDay = _focusedDay;
        }
      });
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
    final selectedEvents = _events[_selectedDay] ?? [];

    return Scaffold(
      backgroundColor: ASColor.Background(context),
      body: Padding(
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
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.green, // Changed from transparent to green
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: ASColor.buttonBackground(context),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(color: Colors.white),
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
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[850]
                        : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.black12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected Date:\n${DateFormat.yMMMMEEEEd().format(_selectedDay ?? _focusedDay)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        final date = _selectedDay ?? _focusedDay;
                        _events.putIfAbsent(date, () => []).add('New Event');
                      });
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add Event'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ASColor.buttonBackground(context),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Events for ${DateFormat.yMMMMEEEEd().format(_selectedDay ?? _focusedDay)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                          color: ASColor.getTextColor(context),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _events.remove(_selectedDay ?? _focusedDay);
                          });
                        },
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
                          color: ASColor.getTextColor(context).withOpacity(0.6),
                        ),
                      ),
                    )
                  else
                    ...selectedEvents.map(
                      (event) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('- $event'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
