import 'package:aqua/LandingPage.dart';
import 'package:flutter/material.dart';
import 'package:aqua/colors.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black, // Start color
              Color(0xFF02030F), // Middle color
              Color(0xFF0D1326), // End color
            ],
            begin: Alignment.centerLeft, // Gradient starts from the left
            end: Alignment.centerRight, // Gradient ends at the right
          ),
        ),


        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align children to the left
          children: [
            SizedBox(height: 50),
            Container(
              padding: EdgeInsets.only(left: 47),
              child: Container(
                width: 300,
                height: 500,
                decoration: BoxDecoration(
                  color: Colors.transparent, // Keeps the background transparent
                  border: Border.all(
                    color: Colors.white, // Outline color
                    width: 1.0, // Outline thickness
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),

                child: Column(
                  children: [
                    Text('Login \nGlad you are back!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: ASColor.txt2Color
                    ),)
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.only(top: 20),
              alignment: Alignment.center,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LandingPage(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: ASColor.txt1Color,
                    width: 2,
                  ), // Change the outline color
                  minimumSize: const Size(
                    30,
                    30,
                  ), // Set equal width and height for a square shape
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .zero, // Remove rounded corners to make it a square
                  ),
                ),
                child: Text(
                  'GET STARTED',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: ASColor.txt1Color,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
