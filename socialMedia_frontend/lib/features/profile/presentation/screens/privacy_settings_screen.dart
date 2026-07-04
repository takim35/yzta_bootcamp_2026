import 'package:flutter/material.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Privacy Settings (Dummy)'),
            SwitchListTile(
              title: const Text('Private Profile'),
              value: false,
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }
}
