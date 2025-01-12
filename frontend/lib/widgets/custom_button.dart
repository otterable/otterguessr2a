// lib/widgets/custom_button.dart
//
// Fixes:
//   • Remove unused import '../theme.dart'
//   • Convert constructor param 'key' to super parameter if desired
//
// Bullet Points:
//   • A simple reusable CustomButton widget
//   • No references to theme.dart if not used
//   • Example debug statements if you want them

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  // Using super parameters:
  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
