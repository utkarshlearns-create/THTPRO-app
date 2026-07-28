import 'package:flutter/material.dart';
import 'package:tht_app/core/theme/app_colors.dart';
import 'package:tht_app/core/network/api_config.dart';

class TutorCard extends StatelessWidget {
  final Map<String, dynamic> tutor;

  const TutorCard({super.key, required this.tutor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String name = tutor['first_name'] ?? 'Unknown Tutor';
    final String experience = tutor['experience_years']?.toString() ?? '0';
    final List<dynamic> subjects = tutor['subjects_taught'] ?? [];
    final List<dynamic> locations = tutor['teaching_locations'] ?? [];
    final String mode = tutor['teaching_mode'] ?? 'BOTH';
    final double rating = (tutor['rating'] as num?)?.toDouble() ?? 5.0;

    String avatarUrl = '';
    if (tutor['profile_picture'] != null && tutor['profile_picture'].toString().isNotEmpty) {
      avatarUrl = tutor['profile_picture'];
      if (!avatarUrl.startsWith('http')) {
        avatarUrl = '${ApiConfig.baseUrl}$avatarUrl';
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.slate200,
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 30, color: AppColors.slate500)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.work_outline, size: 14, color: AppColors.slate500),
                          const SizedBox(width: 4),
                          Text(
                            '$experience Years Exp.',
                            style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (subjects.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subjects.take(4).map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      s.toString(),
                      style: const TextStyle(
                        color: AppColors.primaryOrangeDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.slate500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locations.isNotEmpty ? locations.join(', ') : 'Location not specified',
                    style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.computer_outlined, size: 16, color: AppColors.slate500),
                const SizedBox(width: 4),
                Text(
                  mode == 'HOME' ? 'Home Tuition' : (mode == 'ONLINE' ? 'Online Tuition' : 'Home & Online'),
                  style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
