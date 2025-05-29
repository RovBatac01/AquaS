import 'package:aqua/components/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TimePickerDialogContent extends StatefulWidget {
  final int initialHour;
  final int initialMinute;
  final String initialPeriod;

  const TimePickerDialogContent({
    Key? key,
    required this.initialHour,
    required this.initialMinute,
    required this.initialPeriod,
  }) : super(key: key);

  @override
  _TimePickerDialogContentState createState() =>
      _TimePickerDialogContentState();
}

class _TimePickerDialogContentState extends State<TimePickerDialogContent> {
  late int selectedHour;
  late int selectedMinute;
  late String selectedPeriod;

  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;
  late FixedExtentScrollController periodController;

  @override
  void initState() {
    super.initState();

    selectedHour = widget.initialHour;
    selectedMinute = widget.initialMinute;
    selectedPeriod = widget.initialPeriod;

    hourController = FixedExtentScrollController(initialItem: selectedHour - 1);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
    periodController = FixedExtentScrollController(
      initialItem: selectedPeriod == 'AM' ? 0 : 1,
    );
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    periodController.dispose();
    super.dispose();
  }

  Widget buildPicker<T>({
    required FixedExtentScrollController controller,
    required List<T> items,
    required void Function(int) onSelectedItemChanged,
  }) {
    return SizedBox(
      width: 80,
      height: 150,
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
                style: TextStyle(
                  fontSize: 24,
                  color: ASColor.getTextColor(context), // Use theme color
                ),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildPicker<int>(
              controller: hourController,
              items: List.generate(12, (index) => index + 1),
              onSelectedItemChanged: (index) {
                setState(() {
                  selectedHour = index + 1;
                });
              },
            ),
            buildPicker<int>(
              controller: minuteController,
              items: List.generate(60, (index) => index),
              onSelectedItemChanged: (index) {
                setState(() {
                  selectedMinute = index;
                });
              },
            ),
            buildPicker<String>(
              controller: periodController,
              items: ['AM', 'PM'],
              onSelectedItemChanged: (index) {
                setState(() {
                  selectedPeriod = index == 0 ? 'AM' : 'PM';
                });
              },
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: () {
            final formattedTime =
                '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')} $selectedPeriod';
            Navigator.of(context).pop(formattedTime);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ASColor.Background(context), // Use theme color
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child:  Text('Confirm',
          style: TextStyle(
            color: ASColor.getTextColor(context),
            fontFamily: 'Poppins',
            fontSize: 14.sp.clamp(12, 16)
          ),),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
