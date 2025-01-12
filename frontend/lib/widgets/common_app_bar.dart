// lib\widgets\common_app_bar.dart, do not remove this line

import 'package:flutter/material.dart';
import '../theme.dart';

/// A reusable AppBar widget with the logo in the center.
/// When the logo is pressed, user goes back to Main Menu ('/').
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppBar({Key? key}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  void _onLogoPressed(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: topBarColor,
      centerTitle: true,
      title: InkWell(
        onTap: () => _onLogoPressed(context),
        child: Image.asset(
          'assets/logo.png',
          height: 40,
        ),
      ),
    );
  }
}
