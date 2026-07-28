import 'package:flutter/material.dart';

/// Packages / Subscription screen — GET /api/wallet/packages/
class PackagesScreen extends StatelessWidget {
  const PackagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade Plan')),
      body: const Center(
        child: Text('Packages List (Coming Soon)'),
      ),
    );
  }
}
