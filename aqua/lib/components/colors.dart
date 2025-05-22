import 'package:flutter/material.dart';

class ASColor {
  ASColor._();

  // BACKGROUND COLOR;
  static const Color BGfirst = Colors.white;
  static const Color BGsecond = Colors.black;
  static const Color BGthird = Color(0xFF006400);
  static const Color BGfourth = Color(0xFF1e1f21);
  static const Color BGFifth = Color(0xFF2f2f31);
  static const Color BGsixth = Color(0xFF899499);

  static Color getCardColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? BGFifth : BGfirst;
  }

  static Color getStatCardColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? BGFifth : BGfirst;
  }
  


  static Color getTextColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ?  txt6Color: txt7Color;
  }

  static const Color txt7Color = Color(0xFF2f2f31);
  static const Color txt6Color = Colors.white;
  static const Color txt1Color = Color.fromARGB(255, 42, 68, 181);
  static const Color txt3Color = Colors.black;
  static const Color txt4Color = Color(0xFF6D95FC);
  static const Color txt5Color = Color(0xFF89CFF1);
  
  
}
