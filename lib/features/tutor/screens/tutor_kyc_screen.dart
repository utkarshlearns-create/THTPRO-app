import 'package:flutter/material.dart';
import 'package:tht_app/features/shared/widgets/tht_button.dart';

/// Tutor KYC screen — POST /api/users/kyc/upload/
class TutorKYCScreen extends StatelessWidget {
  const TutorKYCScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identity Verification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify your identity',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Upload your Aadhaar or PAN card to get verified and start applying for jobs.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              
              const Spacer(),
              ThtButton(
                label: 'Upload Documents',
                onPressed: () {
                  // TODO: Document picker
                },
                isExpanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
