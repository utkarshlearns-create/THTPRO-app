import 'package:flutter/material.dart';

/// Screen listing a tutor's job applications.
class TutorApplicationsScreen extends StatelessWidget {
  const TutorApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: const Center(
        child: Text('Applications List (Coming Soon)'),
      ),
    );
  }
}
