import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: TimePickerScreen()));
}

class TimePickerScreen extends StatefulWidget {
  const TimePickerScreen({Key? key}) : super(key: key);

  @override
  _TimePickerScreenState createState() => _TimePickerScreenState();
}

class _TimePickerScreenState extends State<TimePickerScreen> {
  int selectedHour = 11;
  int selectedMinute = 22;
  String selectedPeriod = 'AM';

  final FixedExtentScrollController hourController =
      FixedExtentScrollController(initialItem: 10); // 11th index = 11
  final FixedExtentScrollController minuteController =
      FixedExtentScrollController(initialItem: 21); // 22nd index = 22
  final FixedExtentScrollController periodController =
      FixedExtentScrollController(initialItem: 0); // AM

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Add Alarm', style: TextStyle(color: Colors.white)),
        actions: const [
          Icon(Icons.check, color: Colors.white),
        ],
        leading: const Icon(Icons.close, color: Colors.white),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildPicker(
              controller: hourController,
              items: List.generate(12, (index) => index + 1),
              onSelectedItemChanged: (index) {
                setState(() => selectedHour = index + 1);
              },
            ),
            buildPicker(
              controller: minuteController,
              items: List.generate(60, (index) => index),
              onSelectedItemChanged: (index) {
                setState(() => selectedMinute = index);
              },
            ),
            buildPicker(
              controller: periodController,
              items: ['AM', 'PM'],
              onSelectedItemChanged: (index) {
                setState(() => selectedPeriod = index == 0 ? 'AM' : 'PM');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPicker<T>({
    required FixedExtentScrollController controller,
    required List<T> items,
    required void Function(int) onSelectedItemChanged,
  }) {
    return SizedBox(
      width: 80,
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 50,
        perspective: 0.005,
        diameterRatio: 2,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelectedItemChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            if (index < 0 || index >= items.length) return null;
            return Center(
              child: Text(
                '${items[index]}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }
}