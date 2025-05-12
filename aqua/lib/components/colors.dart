import 'package:flutter/material.dart';

class ASColor {
  ASColor._();

  // BACKGROUND COLOR
  static const Color BGfirst = Color.fromARGB(255, 42, 68, 181);
  static const Color BGsecond = Colors.white;
  static const Color BGthird = Colors.black;
  static const Color BGfourth = Color(0xFF0077b6);
  static const Color BGfifth = Color(0xFF89CFF1);
  static const Color BGSixth = Color(0xFF006400);

  static const LinearGradient firstGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF87CEEB), // SkyBlue
      Color(0xFFADD8E6), // LightBlue
      Color(0xFFFFFFFF), // White
    ],
    stops: [0.2, 0.8, 1.0], // Black covers 70%, blue covers 30%
  );

  static const LinearGradient secondGradient = LinearGradient(
    colors: [
      Colors.black, // Start color
      Color(0xFF006400), // Middle color
      Color(0xFF006d00), // End color
    ],
    begin: Alignment.centerLeft, // Gradient starts from the left
    end: Alignment.centerRight, // Gradient ends at the right
  );

  static const LinearGradient thirdGradient = LinearGradient(
    colors: [Color(0xFFE0F7FA), Color(0xFFD1C4E9)], // Ice Blue to Soft Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fourthGradient = LinearGradient(
    colors: [Color(0xFFE0F7FA), Color(0xFFD1C4E9)], // Ice Blue to Soft Purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fifthGradient = LinearGradient(
    colors: [Color(0xFF121212), Color(0xFF1F2A40)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // TEXT COLOR
  static const Color txt1Color = Color.fromARGB(255, 42, 68, 181);
  static const Color txt2Color = Colors.white;
  static const Color txt3Color = Colors.black;
  static const Color txt4Color = Color(0xFF6D95FC);
  static const Color txt5Color = Color(0xFF89CFF1);
  static const Color txt6Color = Color(0xFF006400);
}
