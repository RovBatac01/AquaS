import 'package:flutter/material.dart';
import 'package:aqua/colors.dart';

class Ourservices extends StatefulWidget {
  const Ourservices({Key? key}) : super(key: key);

  @override
  State<Ourservices> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<Ourservices> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(left: 15, top: 30),
          alignment: Alignment.centerLeft, // Align the content to the left
          child: Column(
            children: [
              Container(
                alignment:
                    Alignment.centerLeft, // Align the content to the left
                padding: EdgeInsets.only(
                  left: 15,
                  top: 30,
                ), // Optional: Add padding to the left if you want some space from the edge
                child: Column(
                  children: [
                    Text(
                      'OUR SERVICES',
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
                padding: EdgeInsets.only(left: 15, top: 30),
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    text: 'Experience The Power\nOf ', // First part of the text
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Poppins',
                      color: ASColor.txt2Color,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: 'Innovation', // Second part with different color
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          color: ASColor.txt1Color, // Change to desired color
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              Container(
                width: 300,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ASColor.secondary,
                      ASColor.primary,
                    ], // Your gradient colors
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    10,
                  ), // Optional for rounded corners
                  border: Border.all(
                    color: ASColor.txt1Color, // The color of the outline
                    width: 2, // Width of the outline
                  ), // Optional for rounded corners
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    2.0,
                  ), // This space is for the border effect
                  child: Container(
                    width: 396, // Subtract the padding from the width
                    height: 96, // Subtract the padding from the height
                    color:
                        Colors
                            .transparent, // Background color for the content inside the box
                    child: Center(
                      child: Text(
                        'Content Here',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
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
                side: BorderSide(color: ASColor.txt1Color, width: 2), // Change the outline color
                minimumSize: Size(30, 30), // Set equal width and height for a square shape
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Remove rounded corners to make it a square
                ),
              ),
              child: Text('VIEW ALL',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: ASColor.txt2Color
                ),
              ),
            ),
          ),
            ],
          ),
        ),
      ],
    );
  }
}
