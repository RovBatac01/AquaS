import 'dart:ui';

import 'package:aqua/pages/TimePicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
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
                todayDecoration: BoxDecoration(), // No background

                selectedDecoration: BoxDecoration(), // No background
                // Style for TODAY's date
                todayTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ASColor.buttonBackground(
                    context,
                  ).withOpacity(0.5), // Or any color
                ),

                // Style for SELECTED
                selectedTextStyle: TextStyle(
                  fontSize: 20, // Slightly bigger
                  fontWeight: FontWeight.bold,
                  color: ASColor.buttonBackground(
                    context,
                  ), // Use your theme color
                ),

                // Style for the current day when it's not selected
                defaultTextStyle: TextStyle(
                  fontSize: 14, // Normal size
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
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  SizedBox(
                    width: 140,
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
                                    child: Container(color: Colors.transparent),
                                  ),
                                  Center(
                                    child: AlertDialog(
                                      backgroundColor: ASColor.getCardColor(
                                        context,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      title: Text(
                                        'Add Schedule',
                                        style: TextStyle(
                                          color: ASColor.getTextColor(context),
                                          fontFamily: 'Montserrat',
                                          fontSize: 18,
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
                                                  fontSize: 14.sp.clamp(12, 16),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
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
                                                              child:
                                                                  TimePickerDialogContent(
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
                                                labelStyle:  TextStyle(
                                                  fontFamily: 'Poppins',
                                                  fontSize: 14,
                                                  color: ASColor.getTextColor(context)
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
                                                      BorderRadius.circular(10),
                                                  borderSide:
                                                      BorderSide
                                                          .none, // Remove border outline
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide:
                                                      BorderSide
                                                          .none, // Remove border outline
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
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
                                              ),
                                            ),
                    
                                            SizedBox(height: 20),
                    
                                            TextFormField(
                                              controller: descController,
                                              minLines: 4, // Set minimum height
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
                                                  fontSize: 14.sp.clamp(12, 16),
                                                ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
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
                                          onPressed: () {
                                            // You can now access: titleController.text, timeController.text, descController.text
                                            final date =
                                                _selectedDay ?? _focusedDay;
                                            final title = titleController.text;
                                            final time = timeController.text;
                                            final desc = descController.text;
                    
                                            if (title.isNotEmpty &&
                                                time.isNotEmpty &&
                                                desc.isNotEmpty) {
                                              setState(() {
                                                _events
                                                    .putIfAbsent(date, () => [])
                                                    .add('$title @ $time\n$desc');
                                              });
                                              Navigator.of(context).pop();
                                            } else {
                                              // Show error or snackbar
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                ASColor.buttonBackground(context),
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
                      label: Text('Add Schedule',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ASColor.buttonBackground(context),
                        foregroundColor: Colors.white,
                      ),
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
                        'Events for ${DateFormat.yMMMMEEEEd().format(_selectedDay ?? _focusedDay)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          color: ASColor.getTextColor(context),
                        ),
                      ),
                      // IconButton(
                      //   icon: Icon(Icons.close),
                      //   onPressed: () {
                      //     setState(() {
                      //       _events.remove(_selectedDay ?? _focusedDay);
                      //     });
                      //   },
                      // ),
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
