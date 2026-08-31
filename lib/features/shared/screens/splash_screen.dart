import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tht_app/core/theme/app_colors.dart';

/// The moment between tapping the icon and the app appearing.
///
/// Timed against the 1100ms floor in `AuthNotifier`, so the whole sequence
/// completes rather than being cut off mid-animation — the mark settles, the
/// wordmark follows it, and there is a beat of stillness before the app
/// replaces it. Previously the auth check resolved in milliseconds and this
/// was torn down inside a frame or two, which read as the app snapping
/// straight to a login form.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Matches the native splash behind it, so the handover between the two
      // is invisible rather than a flash of a different colour.
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/icon_foreground.png',
              width: 132,
              fit: BoxFit.contain,
            )
                .animate()
                .fadeIn(duration: 420.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.86, 0.86),
                  end: const Offset(1, 1),
                  duration: 620.ms,
                  curve: Curves.easeOutBack,
                ),
            const SizedBox(height: AppSpacing.lg),

            // The wordmark arrives after the mark rather than with it, so the
            // eye is led rather than shown everything at once.
            Text(
              'THE HOME TUITIONS',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
                color: isDark ? AppColors.slate100 : AppColors.slate900,
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 420.ms).slideY(
                  begin: 0.35,
                  end: 0,
                  delay: 300.ms,
                  duration: 480.ms,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 6),
            Text(
              'Learn & Earn',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.4,
                color: isDark ? AppColors.slate400 : AppColors.slate500,
              ),
            ).animate().fadeIn(delay: 520.ms, duration: 380.ms),
          ],
        ),
      ),

      // Held to the bottom rather than under the mark: it is a progress hint,
      // not part of the brand lockup, and it only appears if the launch is
      // slow enough to be worth explaining.
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
        child: SizedBox(
          height: 20,
          child: Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isDark ? AppColors.slate600 : AppColors.slate300,
              ),
            ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
          ),
        ),
      ),
    );
  }
}
