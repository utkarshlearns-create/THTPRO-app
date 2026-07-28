import 'package:flutter/material.dart';

/// Tutor Detail screen — GET /api/users/tutors/:pk/
class TutorDetailScreen extends StatelessWidget {
  const TutorDetailScreen({super.key, required this.tutorId});
  final int tutorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutor Profile')),
      body: Center(
        child: Text('Tutor Profile ID: $tutorId (Coming Soon)'),
      ),
    );
  }
}
