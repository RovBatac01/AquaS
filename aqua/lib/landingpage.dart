import 'package:flutter/material.dart';
import 'package:aqua/colors.dart';
import 'package:aqua/Home.dart';
import 'package:aqua/AboutUs.dart';  // Import the AboutUs widget
import 'menubuttons.dart';  // Import MenuButtons

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<LandingPage> {
  // ScrollController for scrolling
  ScrollController _scrollController = ScrollController();

  // GlobalKeys for different sections
  GlobalKey _aboutUsKey = GlobalKey();
  GlobalKey _homeKey = GlobalKey();  // Add GlobalKey for Home section

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          controller: _scrollController, // Attach the ScrollController
          child: Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height + 500,
                decoration: BoxDecoration(
                  gradient: ASColor.primaryGradient,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 25),
                child: Center(
                  child: MenuButtons(
                    scrollController: _scrollController,  // Pass ScrollController to MenuButtons
                    aboutUsKey: _aboutUsKey,  // Pass GlobalKey for AboutUs section
                    homeKey: _homeKey,        // Pass GlobalKey for Home section
                  ),
                ),
              ),
              // Call the Home widget here to display its design on the LandingPage
              Padding(
                padding: const EdgeInsets.only(top: 100),
                child: Center(
                  child: Home(key: _homeKey),  // Attach GlobalKey to Home widget
                ),
              ),
              // About Us section with GlobalKey to scroll to
              Padding(
                padding: const EdgeInsets.only(top: 500),
                child: Center(
                  child: Aboutus(key: _aboutUsKey), // Attach GlobalKey to AboutUs widget
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}