import 'package:flutter/material.dart';

/// Job Detail screen — GET /api/jobs/:pk/
class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.jobId});
  final int jobId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: Center(
        child: Text('Job Details ID: $jobId (Coming Soon)'),
      ),
    );
  }
}
