import 'package:flutter/material.dart';

class ASColor {
  ASColor._();

  // BACKGROUND COLOR
  static const Color primary = Color.fromARGB(255, 42, 68, 181);
  static const Color secondary = Colors.black;

  static LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerRight, // Start point of the gradient
    end: Alignment.centerLeft, // End point of the gradient
    colors: [
      primary, // Use the primary color
      secondary, // Transition to white
    ],
  );

  // TEXT COLOR
  static const Color txt1Color = Color(0xFF6D95FC);
  static const Color txt2Color = Colors.white;
}
