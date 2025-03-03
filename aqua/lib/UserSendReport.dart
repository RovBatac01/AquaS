import 'package:aqua/CustomTextField.dart';
import 'package:aqua/Login.dart';
import 'package:aqua/colors.dart';
import 'package:flutter/material.dart';

class Usersendreport extends StatefulWidget {
  const Usersendreport({super.key});

  @override
  State<Usersendreport> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Usersendreport> {

  TextEditingController username = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController report = TextEditingController();
  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Container(
              alignment: Alignment.center,
              child: Text('Write A Report',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                                  ? ASColor.txt2Color
                                  : ASColor.txt1Color, 
              ),),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 50, top: 30),
            child: Container(
              alignment: Alignment.topLeft,
                child: Text('Your Username',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w100
                ),)   
            ),
          ),

          Padding(padding: EdgeInsets.only(left: 20),
            child: CustomTextField(
              hintText: 'Enter your username',
              icon: Icons.person,
              controller: username,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 50, top: 10),
            child: Container(
              alignment: Alignment.topLeft,
                child: Text('Your Email',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w100
                ),)   
            ),
          ),

          Padding(padding: EdgeInsets.only(left: 20),
            child: CustomTextField(
              hintText: 'Enter your Email',
              icon: Icons.email,
              controller: email,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 50, top: 10),
            child: Container(
              alignment: Alignment.topLeft,
                child: Text('Your Report',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w100
                ),)   
            ),
          ),

          Padding(padding: EdgeInsets.only(left: 20),
            child: CustomTextField(
              hintText: 'Write your report',
              icon: Icons.report,
              controller: report,
              maxLines: 5,
            ),
          ),
        ],
      ),
    );
  }
}
