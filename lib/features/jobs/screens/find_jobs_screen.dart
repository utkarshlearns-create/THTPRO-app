import 'package:flutter/material.dart';

/// Job Search screen — GET /api/jobs/search/
class FindJobsScreen extends StatelessWidget {
  const FindJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Tuition Jobs'),
      ),
      body: const Center(
        child: Text('Job Search Results (Coming Soon)'),
      ),
    );
  }
}
