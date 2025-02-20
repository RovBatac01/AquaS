import 'package:flutter/material.dart';

class ASColor {
  ASColor._();

  // BACKGROUND COLOR
  static const Color primary = Color.fromARGB(255, 42, 68, 181);
  static const Color secondary = Colors.black;

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft, 
    end: Alignment.centerRight, 
    colors: [
      ASColor.secondary, // Black (left)
      ASColor.primary,   // Blue (right)
    ],
    stops: [0.8, 1.0], // Black covers 70%, blue covers 30%
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
}



