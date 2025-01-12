// lib\screens\home_page.dart, do not remove this line

import 'package:flutter/material.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/custom_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomButton(
              text: 'Singleplayer',
              onPressed: () => Navigator.pushNamed(context, '/singleplayer'),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Multiplayer',
              onPressed: () => Navigator.pushNamed(context, '/multiplayer'),
            ),
          ],
        ),
      ),
    );
  }
}
