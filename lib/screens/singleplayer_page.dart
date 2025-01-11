// lib\screens\singleplayer_page.dart, do not remove this line

import 'package:flutter/material.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/custom_button.dart';

class SingleplayerPage extends StatelessWidget {
  const SingleplayerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Singleplayer:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            CustomButton(
              text: 'Classic',
              onPressed: () {
                // Start singleplayer classic
              },
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Custom',
              onPressed: () {
                // Start singleplayer custom
              },
            ),
          ],
        ),
      ),
    );
  }
}
