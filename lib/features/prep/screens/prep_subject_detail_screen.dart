import 'package:flutter/material.dart';

/// Prep module subject details (chapters & syllabus).
class PrepSubjectDetailScreen extends StatelessWidget {
  const PrepSubjectDetailScreen({super.key, required this.subjectId});
  final int subjectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subject Syllabus')),
      body: Center(
        child: Text('Subject ID: $subjectId (Coming Soon)'),
      ),
    );
  }
}
