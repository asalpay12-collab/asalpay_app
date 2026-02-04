// lib/test_screen.dart
import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  const TestScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FCM Test Screen')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Text(
            // data.toString(),
            "Hello",
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
