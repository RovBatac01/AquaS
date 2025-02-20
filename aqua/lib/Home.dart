import 'package:aqua/Login.dart';
import 'package:aqua/colors.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // Color for visibility
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 70),
            alignment: Alignment.center,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: ASColor.txt1Color,
                  width: 2,
                ), // Change the outline color
                minimumSize: Size(
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
                  color: ASColor.txt2Color,
                ),
              ),
            ),
          ),
          Text(
            'AQUASENSE',
            style: TextStyle(
              fontSize: 25,
              color: ASColor.txt1Color,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            'SOLUTIONS',
            style: TextStyle(
              fontSize: 10,
              color: ASColor.txt2Color,
              letterSpacing: 2.0,
            ),
          ),

          Container(
            alignment: Alignment.centerLeft, // Align the content to the left
            padding: EdgeInsets.only(
              left: 15,
              top: 60,
            ), // Optional: Add padding to the left if you want some space from the edge
            child: Column(
              children: [
                Text(
                  'WELCOME TO AQUASENSE',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: ASColor.txt1Color,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.only(left: 15, top: 20),
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'WATER QUALITY\nMONITORING\nSYSTEM',
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: ASColor.txt2Color,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),

          Align(
            alignment:
                Alignment
                    .topLeft, // Align it to the top left corner of the screen
            child: Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 15,
                right: 200,
              ), // Optional top padding
              width: 290, // Set the specific width of the divider
              child: Divider(
                color: ASColor.txt1Color,
                thickness: 2.0, // Thickness of the line
              ),
            ),
          ),

          Container(
            padding: EdgeInsets.only(left: 15, top: 20),
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lorem ipsumNeque porro quisquam est\nqui dolorem ipsum quia dolor sit amet,\nconsectetur, adipisci velit Neque porro\nelit Neque porro quis ipsum',
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 10,
                    color: ASColor.txt2Color,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.only(left: 15, top: 20),
            alignment: Alignment.topLeft,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: ASColor.txt1Color,
                  width: 2,
                ), // Change the outline color
                minimumSize: Size(
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
                'GET IN TOUCH',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: ASColor.txt2Color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
