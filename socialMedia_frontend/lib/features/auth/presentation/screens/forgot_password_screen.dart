import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Forgot Password Screen (Dummy)'),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
  }
}
