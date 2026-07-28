import 'package:flutter/material.dart';

/// Prep module material viewer (video / pdf notes).
class PrepMaterialScreen extends StatelessWidget {
  const PrepMaterialScreen({super.key, required this.materialId});
  final int materialId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Material Viewer')),
      body: Center(
        child: Text('Viewing Material ID: $materialId (Coming Soon)'),
      ),
    );
  }
}
