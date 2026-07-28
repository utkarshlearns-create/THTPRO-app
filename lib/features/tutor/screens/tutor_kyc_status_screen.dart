import 'package:flutter/material.dart';

/// Status of the tutor's KYC verification.
class TutorKYCStatusScreen extends StatelessWidget {
  const TutorKYCStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verification Status')),
      body: const Center(
        child: Text('KYC Status (Coming Soon)'),
      ),
    );
  }
}
