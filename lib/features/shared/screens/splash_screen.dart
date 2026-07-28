import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Full-screen loading spinner shown while the auth state initializes.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Match the light theme of the mockup
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Brand mark with smooth scaling animation (Airbnb style)
            Image.asset(
              'assets/images/logo.png',
              width: 200,
              fit: BoxFit.contain,
            )
            .animate()
            .fadeIn(duration: 800.ms, curve: Curves.easeOut)
            .scale(
              begin: const Offset(0.8, 0.8), 
              end: const Offset(1.0, 1.0), 
              duration: 1200.ms, 
              curve: Curves.elasticOut,
            ),
            
            const SizedBox(height: 48),
            
            // Subtle loading indicator
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryOrange,
              ),
            )
            .animate()
            .fadeIn(delay: 800.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
