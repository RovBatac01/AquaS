import 'dart:ui';
import 'package:flutter/material.dart';


class Background extends StatelessWidget {
  const Background({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Large Top Circle
        Positioned(
          top: -50,
          left: -50,
          child: _buildBlurredCircle(200),
        ),
        
        // Smaller Bottom Circle
        Positioned(
          bottom: 30,
          right: 30,
          child: _buildBlurredCircle(120),
        ),
      ],
    );
  }

  Widget _buildBlurredCircle(double size) {
    return ClipOval(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
