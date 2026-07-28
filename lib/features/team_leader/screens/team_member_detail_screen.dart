import 'package:flutter/material.dart';

/// Individual team member details.
class TeamMemberDetailScreen extends StatelessWidget {
  const TeamMemberDetailScreen({super.key, required this.memberId});
  final int memberId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Details')),
      body: Center(
        child: Text('Member ID: $memberId (Coming Soon)'),
      ),
    );
  }
}
