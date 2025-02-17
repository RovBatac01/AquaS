import 'package:aqua/Contact.dart';
import 'package:aqua/Services.dart';
import 'package:flutter/material.dart';
import 'package:aqua/colors.dart';
import 'package:aqua/Home.dart';
import 'package:aqua/AboutUs.dart'; // Import the AboutUs widget
import 'menubuttons.dart'; // Import MenuButtons

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // ScrollController for scrolling
  ScrollController _scrollController = ScrollController();

  // GlobalKeys for different sections
  final GlobalKey _aboutUsKey = GlobalKey();
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey(); // Add GlobalKey for Home section

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          controller: _scrollController, // Attach the ScrollController
          child: Stack(
            children: [
              IntrinsicHeight(
                child: Container(
                  decoration: BoxDecoration(gradient: ASColor.primaryGradient),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 25),
                        child: Center(
                          child: MenuButtons(
                            scrollController:_scrollController, // Pass ScrollController to MenuButtons
                            aboutUsKey:
                                _aboutUsKey, // Pass GlobalKey for AboutUs section
                            homeKey: _homeKey,
                            servicesKey: _servicesKey,
                            contactUsKey:
                                _contactKey, // Pass GlobalKey for Home section
                          ),
                        ),
                      ),
                      // Call the Home widget here to display its design on the LandingPage
                      Padding(
                        padding: const EdgeInsets.only(top: 50),
                        child: Container(
                          key: _homeKey,
                          child: Home(), // Attach GlobalKey to Home widget
                        ),
                      ),
                      // About Us section with GlobalKey to scroll to
                      Container(
                        key: _aboutUsKey,
                        child: Aboutus(), // Attach GlobalKey to AboutUs widget
                      ),

                      Container(
                        key: _servicesKey,
                        child:
                            Ourservices(), // Attach GlobalKey to AboutUs widget
                      ),

                      Container(
                        key: _contactKey,
                        child:
                            Contactus(), // Attach GlobalKey to AboutUs widget
                      ),

                    ],
                  ),
                ),

                
              ),
            ],
          ),
        ),
      ),
    );
  }
}
