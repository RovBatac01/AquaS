import 'package:aqua/NavBar/Settings.dart';
import 'package:aqua/pages/Admin/AdminDashboard.dart' hide MyDrawerAndNavBarApp;
import 'package:aqua/pages/SAdmin/SAdminDashboard.dart';
import 'package:aqua/pages/User/UserDashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aqua/pages/Theme_Provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => ThemeProvider(), child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeProvider.themeMode,
      home: Userdashboard(),
    );
  }
}
