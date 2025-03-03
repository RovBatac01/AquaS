import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'colors.dart';

class Adminviewreport extends StatefulWidget {
  @override
  _AdminviewreportState createState() => _AdminviewreportState();
}

class _AdminviewreportState extends State<Adminviewreport> {
  List<dynamic> reports = [];

  @override
  void initState() {
    super.initState();
    reports = [
      {
        'username': 'Anya',
        'email': 'Anya@gmail.com',
        'report': 'This is a sample report for testing purposes.'
      },
      {
        'username': 'Tan',
        'email': 'Cristan@gmail.com',
        'report': 'Another example report to test the UI layout.'
      },
      {
        'username': 'Rovic',
        'email': 'Rovic@gmail.com',
        'report': 'Another example report to test the UI layout.'
      },
      {
        'username': 'Zar',
        'email': 'Eleazar@gmail.com',
        'report': 'Another example report to test the UI layout.'
      }
    ];
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3000/reports'));
      if (response.statusCode == 200) {
        setState(() {
          reports = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load reports');
      }
    } catch (e) {
      print('Error fetching reports: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Container(
              alignment: Alignment.center,
              child: Text(
                'View Report',
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.orange : ASColor.txt3Color,
                ),
              ),
            ),
          ),
          Expanded(
            child: reports.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(15),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];

                      return Container(
                        margin: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: isDarkMode
                              ? ASColor.firstGradient
                              : ASColor.secondGradient,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Card(
                          color: Colors.transparent, // Allows gradient to be visible
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Username:',
                                          style: TextStyle(
                                            color: Colors.orange, // Change color here
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          report['username'],
                                          style: TextStyle(
                                            color: isDarkMode 
                                              ? ASColor.txt3Color //Color of Text in Light Mode
                                              : ASColor.txt2Color, // Color of Text in Dark Mode
                                            fontSize: 14,
                                            fontWeight: FontWeight.w100
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          'Email:',
                                          style: TextStyle(
                                            color: Colors.orange, // Change color here
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          report['email'],
                                          style: TextStyle(
                                            color: isDarkMode 
                                              ? ASColor.txt3Color //Color of Text in Light Mode
                                              : ASColor.txt2Color, // Color of Text in Dark Mode
                                            fontSize: 14,
                                            fontWeight: FontWeight.w100
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.person_outline,
                                      color: Colors.white, // Change icon color here
                                      size: 40,
                                    ),
                                  ],
                                ),
                                Divider(height: 20, thickness: 1.5),
                                Text(
                                  'Report:',
                                  style: TextStyle(
                                    color: Colors.orange, // Change color here
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  report['report'],
                                  style: TextStyle(
                                    color: isDarkMode 
                                              ? ASColor.txt3Color //Color of Text in Light Mode
                                              : ASColor.txt2Color, // Color of Text in Dark Mode
                                    fontSize: 14,
                                    fontWeight: FontWeight.w100
                                  ),
                                ),
                                SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      // Implement see more action
                                    },
                                    icon: Icon(
                                      Icons.more_horiz,
                                      color: isDarkMode 
                                              ? ASColor.BGthird //Color of Icon in Light Mode
                                              : Colors.orange, // Color of Icon in Dark Mode 
                                    ),
                                    label: Text(
                                      'See More',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode 
                                              ? ASColor.BGthird //Color of Text in Light Mode
                                              : Colors.orange, // Color of Text in Dark Mode 
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}