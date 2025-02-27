import 'package:aqua/colors.dart';
import 'package:flutter/material.dart';

class Aboutus extends StatefulWidget {

  const Aboutus({Key? key}) : super(key: key);
  
  @override
  _AboutusState createState() => _AboutusState();
}

class _AboutusState extends State<Aboutus> {
  @override
  Widget build(BuildContext context) {
    return Container(  // Color for visibility
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,  // Align the content to the left
            padding: EdgeInsets.only(left: 15, top: 30), // Optional: Add padding to the left if you want some space from the edge
            child: Column(
              children: [
                Text('ABOUT US',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: ASColor.txt1Color,
                    letterSpacing: 1.0,
                  ),)
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.only(left: 15, top: 20),
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text('When it comes to\nH20, We Dont Go\nWith the flow',
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.bold,
                    fontSize: 25,
                    letterSpacing: 1.0
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lorem ipsumNeque porro quisquam est\nqui dolorem ipsum quia dolor sit amet,\nconsectetur, adipisci velit Neque porro\nelit Neque porro quis ipsum',
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 15,
                    letterSpacing: 1.0
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
                side: BorderSide(color: ASColor.txt1Color, width: 2), // Change the outline color
                minimumSize: Size(30, 30), // Set equal width and height for a square shape
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Remove rounded corners to make it a square
                ),
              ),
              child: Text('READ MORE',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}