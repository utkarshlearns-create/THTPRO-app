import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Redesigned Home Screen based on the modern light-theme mockup
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Background Blobs ──
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF3F8FF), // Very light blue
              ),
            ).animate().fadeIn(duration: 1.seconds),
          ),
          Positioned(
            top: 200,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFF9ED), // Very light yellow/orange
              ),
            ).animate().fadeIn(duration: 1.seconds),
          ),

          // ── Floating Icons ──
          Positioned(
            top: 120,
            left: 40,
            child: const _FloatingIcon(icon: Icons.menu_book, color: Colors.blueAccent)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOutSine),
          ),
          Positioned(
            top: 150,
            right: 40,
            child: const _FloatingIcon(icon: Icons.school, color: Colors.indigoAccent)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .moveY(begin: 5, end: -5, duration: 2.5.seconds, curve: Curves.easeInOutSine),
          ),
          Positioned(
            top: 400,
            left: 50,
            child: const _FloatingIcon(icon: Icons.location_on, color: Colors.blueAccent)
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .moveY(begin: -4, end: 4, duration: 2.2.seconds, curve: Curves.easeInOutSine),
          ),

          // ── Main Content Area (Scrollable to prevent overflow) ──
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      // ── Top Bar (Login Button) ──
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => context.push('/login'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF131D42),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ).animate().fadeIn(delay: 500.ms),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // ── Logo ──
                      Image.asset(
                        'assets/images/logo.png',
                        width: 180,
                        fit: BoxFit.contain,
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
                      
                      const SizedBox(height: 32),

                      // ── Headline ──
                      Text(
                        'India’s Trusted Platform\nfor Quality Education',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF131D42), // Dark Navy
                          height: 1.3,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),

                      // ── Subheadline ──
                      Text(
                        'Connect with verified tutors.\nLearn better. Achieve more.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate500,
                          height: 1.5,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 12),
                      
                      // Small divider/dash
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ).animate().fadeIn(delay: 400.ms).scaleX(),

                      const Spacer(),

                      // ── Hero Image ──
                      // Note: We use a slight overlap over the bottom drawer
                      Transform.translate(
                        offset: const Offset(0, 20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Image.asset(
                            'assets/images/hero-main.png',
                            height: 220,
                            fit: BoxFit.contain,
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                        ),
                      ),

                      // ── Bottom Drawer (Blue Curve) ──
                      ClipPath(
                        clipper: _CurveClipper(),
                        child: Container(
                          width: double.infinity,
                          color: const Color(0xFF2563EB), // Blue background
                          padding: const EdgeInsets.only(
                            top: 60, // Space for curve
                            left: 24,
                            right: 24,
                            bottom: 40,
                          ),
                          child: Column(
                            children: [
                              // ── Buttons ──
                              _ActionCard(
                                title: 'Find a Tutor',
                                subtitle: "For your child's success",
                                icon: Icons.search,
                                onPressed: () => context.push('/signup'),
                              ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),
                              
                              const SizedBox(height: 16),
                              
                              _ActionCard(
                                title: "I'm a Tutor",
                                subtitle: 'Teach. Inspire. Earn.',
                                icon: Icons.person,
                                outlined: true,
                                onPressed: () => context.push('/signup'), // Ideally a different route
                              ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1, end: 0),
                              
                              const SizedBox(height: 24),
                              
                              // ── Footer ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.verified_user_outlined,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '100% Verified Tutors • Safe & Secure',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 800.ms),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The curved top shape for the bottom drawer
class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 30); // Start slightly down
    path.quadraticBezierTo(size.width / 2, -10, size.width, 30); // Curve up in middle
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Small floating icon container with light drop shadow
class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

/// The large action buttons in the blue drawer
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final bgColor = outlined ? Colors.transparent : Colors.white;
    final textColor = outlined ? Colors.white : const Color(0xFF131D42);
    final subtextColor = outlined ? Colors.white70 : AppColors.slate500;
    final iconColor = outlined ? Colors.white : const Color(0xFF2563EB);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: outlined
              ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5)
              : null,
          boxShadow: outlined
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: outlined 
                    ? Colors.white.withValues(alpha: 0.1) 
                    : const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: outlined ? Colors.white70 : AppColors.slate400,
            ),
          ],
        ),
      ),
    );
  }
}
