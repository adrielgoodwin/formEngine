import 'package:flutter/material.dart';

/// Helper widget for displaying the Estate Intake icon
class EstateIntakeIcon extends StatelessWidget {
  final double width;
  final double height;
  
  const EstateIntakeIcon({
    super.key,
    this.width = 32.0,
    this.height = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: width,
      height: height,
    );
  }
}
