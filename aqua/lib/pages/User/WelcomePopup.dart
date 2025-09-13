import 'package:aqua/pages/User/ColorIndicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/colors.dart';

class WelcomePopup extends StatelessWidget {
  final String? title;
  final String? description;
  final String? imagePath;
  final Widget? customContent;
  final VoidCallback? onGetStarted;

  const WelcomePopup({
    Key? key,
    this.title,
    this.description,
    this.imagePath,
    this.customContent,
    this.onGetStarted,
  }) : super(key: key);

  // Static method to show the popup
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const WelcomePopup();
      },
    );
  }

  // Static method to show custom popup
  static void showCustom(
    BuildContext context, {
    String? title,
    String? description,
    String? imagePath,
    Widget? customContent,
    VoidCallback? onGetStarted,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WelcomePopup(
          title: title,
          description: description,
          imagePath: imagePath,
          customContent: customContent,
          onGetStarted: onGetStarted,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: ASColor.getCardColor(context),
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.green.withOpacity(0.1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Welcome Image
              _buildWelcomeImage(),
              SizedBox(height: 20.h),

              // Welcome Title
              Text(
                title ?? 'Welcome to AquaS!',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: ASColor.getTextColor(context),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),

              // Welcome Description
              Text(
                description ?? 'Monitor your water quality with ease. Track TDS, conductivity, and more to ensure clean and safe water.',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: ASColor.getTextColor(context).withOpacity(0.7),
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),

              // Custom content or default features list
              if (customContent != null) ...[
                customContent!,
                SizedBox(height: 24.h),
              ] else ...[
                _buildFeaturesContainer(context),
                SizedBox(height: 24.h),
              ],

              // Get Started Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onGetStarted ?? () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeImage() {
    if (imagePath != null) {
      return Container(
        width: 150.w,
        height: 150.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Image.asset(imagePath!, fit: BoxFit.cover),
        ),
      );
    } else {
      return Container(
        width: 150.w,
        height: 150.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.cyan.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.water_drop, size: 50.sp, color: Colors.white),
            Positioned(
              top: 45.h,
              right: 45.w,
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 16.sp,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFeaturesContainer(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: ASColor.Background(context),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFeatureItem(
                context,
                Icons.analytics,
                'Color Indicator',
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 16.sp, color: ASColor.getTextColor(context).withOpacity(0.5)),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => WaterQualityPopupDemo()));
                },
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFeatureItem(
                context,
                Icons.history,
                'Historical Data',
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 16.sp, color: ASColor.getTextColor(context).withOpacity(0.5)),
                onPressed: () {},
              ),
            ],
          ),

          SizedBox(height: 8.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFeatureItem(
                context,
                Icons.notifications,
                'Smart Alerts',
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 16.sp, color: ASColor.getTextColor(context).withOpacity(0.5)),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFeatureItem(
                context,
                Icons.calendar_today,
                'Schedule Reports',
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, size: 16.sp, color: ASColor.getTextColor(context).withOpacity(0.5)),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String text,
  ) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 20.sp, color: Colors.blue),
        ),
        SizedBox(width: 12.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            color: ASColor.getTextColor(context),
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}