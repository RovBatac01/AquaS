import 'package:aqua/colors.dart';
import 'package:flutter/material.dart';


class MenuButtons extends StatelessWidget {
  final ScrollController scrollController; // Pass the ScrollController
  final GlobalKey aboutUsKey; // Pass the GlobalKey for About Us section
  final GlobalKey homeKey;
  final GlobalKey servicesKey;
  final GlobalKey contactUsKey; // Pass the GlobalKey for Home section

  const MenuButtons({
    required this.scrollController,
    required this.aboutUsKey,
    required this.homeKey,
    required this.servicesKey,
    required this.contactUsKey,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Home button - scroll to Home section
        TextButton(
          onPressed: () {
            // Scroll to the Home section when the button is pressed
            _scrollToHome();
          },
          child: Text(
            'Home',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: ASColor.txt2Color,
            ),
          ),
        ),
        // About Us button - scroll to About Us section
        TextButton(
          onPressed: () {
            // Scroll to the About Us section when the button is pressed
            _scrollToAboutUs();
          },
          child: Text(
            'About Us',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: ASColor.txt2Color,
            ),
          ),
        ),

        // Other buttons...
        TextButton(
          onPressed: () {
            // Scroll to the Home section when the button is pressed
            _scrollToServices();
          },
          child: Text(
            'Services',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: ASColor.txt2Color,
            ),
          ),
        ),

        TextButton(
          onPressed: () {
            // Scroll to the Home section when the button is pressed
            _scrollToContactUs();
          },
          child: Text(
            'Contact Us',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: ASColor.txt2Color,
            ),
          ),
        ),
      ],
    );
  }

  // Function to scroll to the About Us section
  void _scrollToAboutUs() {
    final context = aboutUsKey.currentContext;
    if (context != null) {
      final position = aboutUsKey.currentContext!
          .findRenderObject()!
          .getTransformTo(null);
      scrollController.animateTo(
        position
            .getTranslation()
            .y, // Scroll to the y position of the About Us section
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  // Function to scroll to the Home section
  void _scrollToHome() {
    final context = homeKey.currentContext;
    if (context != null) {
      final position = homeKey.currentContext!
          .findRenderObject()!
          .getTransformTo(null);
      scrollController.animateTo(
        position
            .getTranslation()
            .y, // Scroll to the y position of the Home section
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToServices() {
    final context = servicesKey.currentContext;
    if (context != null) {
      final position = servicesKey.currentContext!
          .findRenderObject()!
          .getTransformTo(null);
      // Use the passed scrollController here instead of declaring a new one
      scrollController.animateTo(
        position
            .getTranslation()
            .y, // Scroll to the y position of the Home section
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToContactUs() {
    final context = contactUsKey.currentContext;
    if (context != null) {
      final position = contactUsKey.currentContext!
          .findRenderObject()!
          .getTransformTo(null);
      scrollController.animateTo(
        position
            .getTranslation()
            .y, // Scroll to the y position of the Home section
        duration: Duration(seconds: 1),
        curve: Curves.easeInOut,
      );
    }
  }
}
