import 'package:flutter/material.dart';

class ASColor {
  ASColor._();

  // BACKGROUND COLOR;
  static const Color BGfirst = Colors.white;
  static const Color BGSecond = Color(
    0xFF2f2f31,
  ); //background color for dark mode
  static const Color BGthird = Color(
    0xFF1e1f21,
  ); //background color for dark mode for navigation bar and app bar
  static const Color BGFourth = Color(
    0xFFDDDDDD,
  ); // background color for light mode
  static const Color BGFifth = Color(
    0xFFFFFDF6,
  ); // background color for light mode for navigation bar and app bar

  static Color getCardColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? BGSecond : BGfirst;
  }

  static Color getStatCardColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? BGSecond : BGfirst;
  }

  static Color Background(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? BGSecond : BGFourth;
  }

  static Color buttonBackground(BuildContext context) {
    return const Color(0xFF28a745); // Use green as default
  }

  static Color buttonHoverBackground(BuildContext context) {
    return const Color(0xFF218838); // Use darker green on hover
  }

  static Color getTextColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? txt1Color : txt2Color;
  }

  static const Color txt2Color = Color(0xFF2f2f31); // text color for light mode
  static const Color txt1Color = Color(0xFFFFFDF6); // text color for dark mode
}
