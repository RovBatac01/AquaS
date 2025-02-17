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

  // TEXT COLOR
  static const Color txt1Color = Color(0xFF6D95FC);
  static const Color txt2Color = Colors.white;
}



