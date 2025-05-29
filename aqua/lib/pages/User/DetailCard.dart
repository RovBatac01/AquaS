import 'package:aqua/components/colors.dart';
import 'package:aqua/pages/Admin/AdminDetails.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'Details.dart'; // Adjust the import path as needed
import 'package:aqua/components/colors.dart';

class DetailCard extends StatelessWidget {
  final String title;
  final String quality;
  final VoidCallback? onEdit;

  const DetailCard({
    super.key,
    required this.title,
    required this.quality,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Card(
        color: ASColor.getCardColor(
          context,
        ), // Use theme card color, or set a custom color
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 5,
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: ASColor.getTextColor(context),
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      color: ASColor.getTextColor(context),
                    ),
                    onPressed: onEdit ?? () {},
                  ),
                ],
              ),
              Text(
                "Water Quality",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: ASColor.getTextColor(context),
                ),
              ),

              SizedBox(height: 5.h), // Use ScreenUtil for responsive height

              Text(
                "Good",
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
