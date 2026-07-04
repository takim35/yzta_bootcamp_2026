import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Reset Password Screen (Dummy)'),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Reset Password'),
            ),
          ],
        ),
      ),
    );
  }
}
