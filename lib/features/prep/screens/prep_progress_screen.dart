import 'package:flutter/material.dart';

/// Prep module student progress and analytics.
class PrepProgressScreen extends StatelessWidget {
  const PrepProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: const Center(
        child: Text('Analytics & Scores (Coming Soon)'),
      ),
    );
  }
}
