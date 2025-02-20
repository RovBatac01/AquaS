import 'package:aqua/Login.dart';
import 'package:flutter/material.dart';
import 'package:aqua/colors.dart';

class Contactus extends StatefulWidget {
  const Contactus({Key? key}) : super(key: key);

  @override
  State<Contactus> createState() => _ContactUsState();
}

class _ContactUsState extends State<Contactus> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _messageController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          alignment: Alignment.centerLeft, // Align the content to the left
          padding: EdgeInsets.only(
            left: 30,
            top: 30,
          ), // Optional: Add padding to the left if you want some space from the edge
          child: Column(
            children: [
              Text(
                'CONTACT US',
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

        SizedBox(height: 20),

        Container(
          width: 300,
          height: 350,
          decoration: BoxDecoration(
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
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 25, top: 10),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your Name',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: ASColor.txt2Color,
                      ),
                    ),
                  ),

                  SizedBox(height: 5),

                  Container(
                    padding: EdgeInsets.only(bottom: 17, left: 5),
                    width: 250,
                    height: 40,
                    alignment: Alignment.topLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: ASColor.txt2Color, // The color of the outline
                        width: 1, // Width of the outline
                      ),
                    ),
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(
                        color: ASColor.txt2Color,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                      decoration: InputDecoration(border: InputBorder.none),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.only(left: 25, top: 20),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your Email',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: ASColor.txt2Color,
                      ),
                    ),
                  ),

                  SizedBox(height: 5),

                  Container(
                    padding: EdgeInsets.only(bottom: 18, left: 5),
                    width: 250,
                    height: 40,
                    alignment: Alignment.topLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Optional for rounded corners
                      border: Border.all(
                        color: ASColor.txt2Color, // The color of the outline
                        width: 1, // Width of the outline
                      ), // Optional for rounded corners
                    ),
                    child: TextField(
                      controller: _emailController,
                      style: TextStyle(
                        color: ASColor.txt2Color,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                      decoration: InputDecoration(border: InputBorder.none),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.only(left: 25, top: 20),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Your Message',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: ASColor.txt2Color,
                      ),
                    ),
                  ),

                  SizedBox(height: 5),

                  Container(
                    padding: EdgeInsets.only(bottom: 20, left: 10),
                    width: 250,
                    height: 120,
                    alignment: Alignment.topLeft,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        10,
                      ), // Optional for rounded corners
                      border: Border.all(
                        color: ASColor.txt2Color, // The color of the outline
                        width: 1, // Width of the outline
                      ), // Optional for rounded corners
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(
                        color: ASColor.txt2Color,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: null, // Allows multiple lines of text
                      keyboardType:
                          TextInputType
                              .multiline, // Ensures the multiline functionality works on some devices
                      decoration: InputDecoration(border: InputBorder.none),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Container(
          padding: EdgeInsets.only(left: 15, top: 10),
          child: Center(
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
                'SEND MESSAGE',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: ASColor.txt2Color,
                ),
              ),
            ),
          ),
        ),

        Container(
          padding: EdgeInsets.only(left: 30, top: 30),
          alignment: Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              text: 'GET IN ', // First part of the text
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Poppins',
                color: ASColor.txt2Color,
                fontWeight: FontWeight.bold,
              ),
              children: [
                TextSpan(
                  text: 'TOUCH', // Second part with different color
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

        Align(
          alignment:
              Alignment
                  .topLeft, // Align it to the top left corner of the screen
          child: Container(
            padding: EdgeInsets.only(
              top: 10,
              left: 30,
              right: 200,
            ), // Optional top padding
            width: 290, // Set the specific width of the divider
            child: Divider(
              color: ASColor.txt2Color,
              thickness: 2.0, // Thickness of the line
            ),
          ),
        ),

        Container(
          padding: EdgeInsets.only(left: 30, top: 10),
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lorem ipsumNeque porro quisquam est\nqui dolorem ipsum quia dolor sit amet,\nconsectetur, adipisci velit Neque porro',
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
          padding: EdgeInsets.only(left: 20, top: 20),
          child: Row(
            children: [
              Icon(Icons.pin_drop_outlined, color: ASColor.primary, size: 20),
              SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Office Address\n', // First part of the text
                      style: TextStyle(
                        fontSize: 10.0, // Style for the "Office Address"
                        color: ASColor.txt2Color, // Color for "Office Address"
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'NU Dasmariñas', // Second part of the text
                      style: TextStyle(
                        fontSize: 8.0, // Different size for "NU Dasmariñas"
                        color:
                            ASColor
                                .txt1Color, // Different color for "NU Dasmariñas"
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: EdgeInsets.only(left: 20, top: 20),
          child: Row(
            children: [
              Icon(Icons.phone_enabled, color: ASColor.primary, size: 20),
              SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Call Us\n', // First part of the text
                      style: TextStyle(
                        fontSize: 10.0, // Style for the "Office Address"
                        color: ASColor.txt2Color, // Color for "Office Address"
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '+639123456789', // Second part of the text
                      style: TextStyle(
                        fontSize: 8.0, // Different size for "NU Dasmariñas"
                        color:
                            ASColor
                                .txt1Color, // Different color for "NU Dasmariñas"
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: EdgeInsets.only(left: 20, top: 20),
          child: Row(
            children: [
              Icon(Icons.mail_outline, color: ASColor.primary, size: 20),
              SizedBox(width: 20),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Mail Us\n', // First part of the text
                      style: TextStyle(
                        fontSize: 10.0, // Style for the "Office Address"
                        color: ASColor.txt2Color, // Color for "Office Address"
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'deleazar62@gmail.com', // Second part of the text
                      style: TextStyle(
                        fontSize: 8.0, // Different size for "NU Dasmariñas"
                        color:
                            ASColor
                                .txt1Color, // Different color for "NU Dasmariñas"
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: EdgeInsets.only(top: 20),
          child: Center(
            child: Text(
              'AQUASENSE',
              style: TextStyle(
                fontSize: 25,
                color: ASColor.txt1Color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        Align(
          alignment:
              Alignment.center, // Align it to the top left corner of the screen
          child: Container(
            padding: EdgeInsets.only(
              left: 100,
              right: 100,
            ), // Optional top padding
            width: 290, // Set the specific width of the divider
            child: Divider(
              color: ASColor.txt2Color,
              thickness: 2.0, // Thickness of the line
            ),
          ),
        ),

        Container(
          padding: EdgeInsets.only(top: 20),
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
              minimumSize: Size(30, 30,
              ), // Set equal width and height for a square shape
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.zero, // Remove rounded corners to make it a square
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

        Container(
          padding: EdgeInsets.only(top: 60, bottom: 10),
          child: Center(
            child: Text(
              'Copyright © 2003-2023 Creatic Agency\nAll Rights Reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 8, color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }
}
