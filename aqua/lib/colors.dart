import 'package:flutter/material.dart';

class ASColor {
  ASColor._();

  // BACKGROUND COLOR
  static const Color BGfirst = Color.fromARGB(255, 42, 68, 181);
  static const Color BGsecond = Colors.white;
  static const Color BGthird = Colors.black;
  static const Color BGfourth = Color(0xFF0077b6);
  static const Color BGfifth = Color(0xFF89CFF1);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft, 
    end: Alignment.centerRight, 
    colors: [
      Color(0xFF87CEEB), // SkyBlue
    Color(0xFFADD8E6), // LightBlue
    Color(0xFFFFFFFF), // White
    ],
    stops: [0.2, 0.8, 1.0], // Black covers 70%, blue covers 30%
  );

  static const LinearGradient secondaryGradient = LinearGradient(
  colors: [
    Colors.black, // Start color
    Color(0xFF02030F), // Middle color
    Color(0xFF0D1326), // End color
  ],
  begin: Alignment.centerLeft, // Gradient starts from the left
  end: Alignment.centerRight, // Gradient ends at the right
);

  // TEXT COLOR
  static const Color txt1Color = Color(0xFF6D95FC);
  static const Color txt2Color = Colors.white;
  static const Color txt3Color = Colors.black;
  static const Color txt4Color = Color.fromARGB(255, 42, 68, 181);
}



