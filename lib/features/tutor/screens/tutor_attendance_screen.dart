import 'package:flutter/material.dart';

/// Screen for tracking tutor attendance for active tuitions.
class TutorAttendanceScreen extends StatelessWidget {
  const TutorAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: const Center(
        child: Text('Attendance Tracking (Coming Soon)'),
      ),
    );
  }
}
