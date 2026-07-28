import 'package:flutter/material.dart';
import 'package:tht_app/features/shared/widgets/tht_text_field.dart';
import 'package:tht_app/features/shared/widgets/tht_button.dart';

/// Forgot password screen — sends WhatsApp OTP via POST /api/auth/forgot-password/.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset your password',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your phone number and we\'ll send a reset OTP via WhatsApp.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              const ThtTextField(
                label: 'Phone number',
                hint: 'Enter your registered phone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const Spacer(),
              ThtButton(
                label: 'Send OTP',
                onPressed: () {
                  // TODO: POST /api/auth/forgot-password/
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
