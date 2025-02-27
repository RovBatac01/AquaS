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
  final GlobalKey _contactKey = GlobalKey();

  final ValueNotifier<ThemeMode> _notifier = ValueNotifier(ThemeMode.dark);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _notifier,
      builder: (_, mode, __) {
        return MaterialApp(
          themeMode: mode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: Scaffold(
            body: SingleChildScrollView(
              controller: _scrollController,
              child: Stack(
                children: [
                  IntrinsicHeight(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 25),
                          child: Center(
                            child: MenuButtons(
                              scrollController: _scrollController,
                              aboutUsKey: _aboutUsKey,
                              homeKey: _homeKey,
                              servicesKey: _servicesKey,
                              contactUsKey: _contactKey,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 50),
                          child: Container(key: _homeKey, child: Home()),
                        ),
                        Container(key: _aboutUsKey, child: Aboutus()),
                        Container(key: _servicesKey, child: Ourservices()),
                        Container(key: _contactKey, child: Contactus()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  mode =
                      mode == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
                  _notifier.value = mode;
                });
              },
              child: Icon(Icons.dark_mode_outlined),
            ),
          ),
        );
      },
    );
  }
}
