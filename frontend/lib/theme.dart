// lib\theme.dart, do not remove this line

import 'package:flutter/material.dart';

/// Define your color palette & style constants.
const Color topBarColor = Color(0xFF00355D);
const Color scaffoldBgColor = Color(0xFFF5F1E4);
const Color buttonColor = Color(0xFF000000);
const Color buttonTextColor = Color(0xFFFFFFFF);
const Color fieldColor = Color(0xFFD9D4C7);
const double borderRadiusValue = 30.0;

ThemeData buildThemeData() {
  return ThemeData(
    primaryColor: topBarColor,
    scaffoldBackgroundColor: scaffoldBgColor,
    fontFamily: 'Roboto',

    textTheme: const TextTheme(
      // Generic text style for body
      bodyMedium: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(buttonColor),
        foregroundColor: MaterialStatePropertyAll(buttonTextColor),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(borderRadiusValue)),
          ),
        ),
        textStyle: const MaterialStatePropertyAll(
          TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
}
