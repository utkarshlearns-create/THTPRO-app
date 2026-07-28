import 'package:flutter/material.dart';

/// Screen displaying a tutor's upcoming demo classes.
class TutorScheduleScreen extends StatelessWidget {
  const TutorScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Schedule')),
      body: const Center(
        child: Text('Schedule List (Coming Soon)'),
      ),
    );
  }
}
