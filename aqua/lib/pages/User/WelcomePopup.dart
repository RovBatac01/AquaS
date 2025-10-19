import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/colors.dart';

class WelcomePopup extends StatefulWidget {
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

  // List of tutorial images in order
  static const List<String> tutorialImages = [
    'assets/images/User/User1.png',
    'assets/images/User/User2.png',
    'assets/images/User/User3.png',
    'assets/images/User/User4.png',
    'assets/images/User/User5.png',
    'assets/images/User/User6.png',
    'assets/images/User/User7.png',
    'assets/images/User/User8.png',
    'assets/images/User/User9.png',
    'assets/images/User/User10.png',
    'assets/images/User/User11.png',
    'assets/images/User/User12.png',
    'assets/images/User/User13.png',
    'assets/images/User/User14.png',
    'assets/images/User/User15.png',
    'assets/images/User/User16.png',
    'assets/images/User/User17.png',
    'assets/images/User/User18.png',
    'assets/images/User/User19.png',
    'assets/images/User/User20.png',
    'assets/images/User/User21.png',
    'assets/images/User/User22.png',
    'assets/images/User/User23.png',
    'assets/images/User/User24.png',
    'assets/images/User/User25.png',
  ];

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
  State<WelcomePopup> createState() => _WelcomePopupState();
}

class _WelcomePopupState extends State<WelcomePopup> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
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
        child: Column(
          children: [
            // Header
            Center(
              child: Text(
                widget.title ?? 'Welcome to AquaS!',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: ASColor.getTextColor(context),
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // Description
            if (widget.description != null || widget.title == null)
              Padding(
                padding: EdgeInsets.only(bottom: 15.h),
                child: Text(
                  widget.description ??
                      'Swipe through the tutorial images to learn how to use AquaS!',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: ASColor.getTextColor(context).withOpacity(0.7),
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w300,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Scrollable Image Gallery
            Expanded(child: _buildImageGallery(context)),

            SizedBox(height: 20.h),

            // Get Started Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    widget.onGetStarted ?? () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ASColor.buttonBackground(context),
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
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ASColor.Background(context),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ASColor.getTextColor(context).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Scroll indicator
          Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.arrow_back_ios,
                  size: 16.sp,
                  color: ASColor.getTextColor(context).withOpacity(0.5),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Swipe to navigate',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: ASColor.getTextColor(context).withOpacity(0.6),
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.sp,
                  color: ASColor.getTextColor(context).withOpacity(0.5),
                ),
              ],
            ),
          ),
          // PageView for images
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                });
              },
              itemCount: WelcomePopup.tutorialImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.asset(
                      WelcomePopup.tutorialImages[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 300.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 48.sp,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Image not found',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14.sp,
                                ),
                              ),
                              Text(
                                WelcomePopup.tutorialImages[index]
                                    .split('/')
                                    .last,
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          // Page indicators
          SizedBox(height: 8.h),
          _buildPageIndicators(),
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Container(
      height: 30.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            WelcomePopup.tutorialImages.length,
            (index) => AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 1.w),
              width: _currentPage == index ? 5.w : 3.w,
              height: _currentPage == index ? 5.h : 3.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _currentPage == index
                        ? Colors.blue
                        : ASColor.getTextColor(context).withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
