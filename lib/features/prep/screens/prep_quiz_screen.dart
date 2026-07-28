import 'package:flutter/material.dart';

/// Prep module quiz interface.
class PrepQuizScreen extends StatelessWidget {
  const PrepQuizScreen({super.key, required this.quizId});
  final int quizId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Center(
        child: Text('Quiz ID: $quizId (Coming Soon)'),
      ),
    );
  }
}
