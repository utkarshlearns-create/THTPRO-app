import 'package:flutter/material.dart';

/// Screen listing all jobs posted by the parent.
class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Posted Jobs')),
      body: const Center(
        child: Text('My Jobs List (Coming Soon)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open Job Wizard
        },
        icon: const Icon(Icons.add),
        label: const Text('Post Job'),
      ),
    );
  }
}
