import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tht_app/core/network/token_storage.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Beautiful, Premium Tutor Dashboard matching the high-fidelity mockup.
class TutorHomeScreen extends ConsumerStatefulWidget {
  const TutorHomeScreen({super.key});

  @override
  ConsumerState<TutorHomeScreen> createState() => _TutorHomeScreenState();
}

class _TutorHomeScreenState extends ConsumerState<TutorHomeScreen> {
  String _name = 'Utkarsh';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await TokenStorage.getName() ??
        await TokenStorage.getUsername() ??
        'Utkarsh';

    // Capitalize first letter if available
    if (name.isNotEmpty) {
      final formattedName = name[0].toUpperCase() + name.substring(1);
      setState(() => _name = formattedName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark)
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .slideY(begin: -0.2, end: 0),
              const SizedBox(height: 24),
              _buildHeroSection(isDark)
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .scale(begin: const Offset(0.95, 0.95)),
              const SizedBox(height: 24),
              _buildTodaysSchedule(isDark)
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              _buildStudentLeads(isDark)
                  .animate()
                  .fadeIn(delay: 400.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              _buildMonthOverview(isDark)
                  .animate()
                  .fadeIn(delay: 500.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              _buildQuickActions(isDark)
                  .animate()
                  .fadeIn(delay: 600.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              _buildPromoBanner(isDark)
                  .animate()
                  .fadeIn(delay: 700.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Menu + Greeting
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.white,
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
              ),
              child: const Icon(Icons.menu, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning 👋',
                  style: TextStyle(
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.verified,
                        color: AppColors.primaryBlue, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Level 3  •  Verified Tutor',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        // Right: Notification Bell
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.white,
            shape: BoxShape.circle,
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
          ),
          child: const Icon(Icons.notifications_outlined, size: 20),
        ),
      ],
    );
  }

  Widget _buildHeroSection(bool isDark) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF1F5FE), // Light blue tint
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.2,
                  ),
                  children: const [
                    TextSpan(text: 'You '),
                    TextSpan(
                      text: 'inspire.\n',
                      style: TextStyle(color: AppColors.primaryBlue),
                    ),
                    TextSpan(text: 'We connect.'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Teach what you love and\nhelp students achieve more.',
                style: TextStyle(
                  color: isDark ? AppColors.slate400 : AppColors.slate500,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24), // Space for image
            ],
          ),
        ),

        // Tutor Image Overlay
        Positioned(
          right: -10,
          bottom: 0,
          child: Image.asset(
            'assets/images/hero-main.png', // Assuming we copied this earlier
            height: 160,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 160,
                width: 140,
                alignment: Alignment.bottomRight,
                child: const Icon(Icons.person,
                    size: 100, color: AppColors.slate300),
              );
            },
          ),
        ),

        // Floating Rating Badge
        Positioned(
          top: -10,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '4.9',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Your Rating',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(
                  begin: -4,
                  end: 4,
                  duration: 2000.ms,
                  curve: Curves.easeInOut),
        ),
      ],
    );
  }

  Widget _buildTodaysSchedule(bool isDark) {
    return _BaseCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.calendar_today_outlined,
            iconColor: AppColors.primaryBlue,
            iconBg: AppColors.primaryBlue.withValues(alpha: 0.1),
            title: "Today's Schedule",
            actionText: 'View Calendar',
            onAction: () {},
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _ScheduleItem(
                  time: '10:00\nAM',
                  title: 'Class 10 Maths',
                  subtitle: 'CBSE • Aarav Singh',
                  location: 'Gomti Nagar, Lucknow',
                  isDark: isDark,
                  timeColor: AppColors.primaryBlue,
                ),
                const SizedBox(width: 16),
                _ScheduleItem(
                  time: '5:00\nPM',
                  title: 'JEE Physics',
                  subtitle: 'JEE • Rohan Verma',
                  location: 'Aliganj, Lucknow',
                  isDark: isDark,
                  timeColor: Colors.deepPurple,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentLeads(bool isDark) {
    return _BaseCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            icon: Icons.people_outline,
            iconColor: Colors.teal,
            iconBg: Colors.teal.withValues(alpha: 0.1),
            title: 'New Student Leads',
            actionText: 'View Leads',
            onAction: () {},
          ),
          const SizedBox(height: 4),
          Text(
            'Students are looking for tutors like you!',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.slate400 : AppColors.slate500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.teal.withValues(alpha: 0.05)
                  : Colors.teal.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Text(
                  '12',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.teal.shade700,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Students nearby',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      const Text(
                        'looking for Mathematics',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(Icons.location_on,
                      color: Colors.teal.shade400, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Within 5 km',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Lucknow',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.slate400 : AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthOverview(bool isDark) {
    return _BaseCard(
      isDark: isDark,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bar_chart,
                        color: AppColors.primaryBlue, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'This Month Overview',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate700 : AppColors.slate100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      'May 2024',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.slate300 : AppColors.slate600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down,
                        size: 14,
                        color:
                            isDark ? AppColors.slate300 : AppColors.slate600),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricItem(
                icon: Icons.currency_rupee,
                iconColor: Colors.green,
                iconBg: Colors.green.withValues(alpha: 0.1),
                value: '32,500',
                label: 'Total Earnings',
                trend: '↑ 18%',
                trendColor: Colors.green,
                isDark: isDark,
              ),
              _MetricItem(
                icon: Icons.calendar_month,
                iconColor: AppColors.primaryBlue,
                iconBg: AppColors.primaryBlue.withValues(alpha: 0.1),
                value: '18',
                label: 'Classes Completed',
                trend: '↑ 5',
                trendColor: Colors.green,
                isDark: isDark,
              ),
              _MetricItem(
                icon: Icons.star,
                iconColor: Colors.deepPurple,
                iconBg: Colors.deepPurple.withValues(alpha: 0.1),
                value: '4.9',
                label: 'Average Rating',
                trend: '↑ 0.2',
                trendColor: Colors.green,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionIcon(
                icon: Icons.calendar_month,
                color: AppColors.primaryBlue,
                label: 'Add\nAvailability',
                isDark: isDark),
            _ActionIcon(
                icon: Icons.menu_book,
                color: Colors.deepPurple,
                label: 'My\nSubjects',
                isDark: isDark),
            _ActionIcon(
                icon: Icons.description_outlined,
                color: Colors.orange,
                label: 'Documents\n& Certificates',
                isDark: isDark),
            _ActionIcon(
                icon: Icons.chat_bubble_outline,
                color: Colors.teal,
                label: 'Messages\n',
                isDark: isDark),
            _ActionIcon(
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.primaryBlue,
                label: 'Earnings\n& Payouts',
                isDark: isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildPromoBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFF1F5FE), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.white,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Trophy icon representation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Text('🏆', style: TextStyle(fontSize: 32)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Become a Top Rated Tutor!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Maintain high ratings, complete more classes and grow your reputation.',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.slate300 : AppColors.slate600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: const Row(
              children: [
                Text(
                  'View Tips',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ──

class _BaseCard extends StatelessWidget {
  const _BaseCard({required this.child, required this.isDark});
  final Widget child;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String actionText;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onAction,
          child: Row(
            children: [
              Text(
                actionText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios,
                  color: AppColors.primaryBlue, size: 10),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  const _ScheduleItem({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.isDark,
    required this.timeColor,
  });

  final String time;
  final String title;
  final String subtitle;
  final String location;
  final bool isDark;
  final Color timeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240, // Fixed width for horizontal scrolling
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: isDark ? AppColors.slate700 : AppColors.slate200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: timeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: timeColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 12, color: AppColors.slate400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isDark ? AppColors.slate400 : AppColors.slate500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    required this.trend,
    required this.trendColor,
    required this.isDark,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final String trend;
  final Color trendColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppColors.slate400 : AppColors.slate500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              trend,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: trendColor,
              ),
            ),
            Text(
              ' vs Apr',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.slate500 : AppColors.slate400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.label,
    required this.isDark,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    )
                  ],
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.slate300 : AppColors.slate700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
