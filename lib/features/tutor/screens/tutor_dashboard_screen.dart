import 'package:flutter/material.dart';
import 'package:tht_app/features/shared/widgets/stat_card.dart';

/// Tutor's dashboard tab.
class TutorDashboardScreen extends StatelessWidget {
  const TutorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Fetch from /api/users/dashboard/stats/
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            Text(
              'Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.school_outlined,
                    label: 'Active Tuitions',
                    value: '0',
                    tintColor: Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    icon: Icons.star_outline,
                    label: 'Profile Views',
                    value: '0',
                    tintColor: Colors.orange,
                  ),
                ),
              ],
            ),
            
            // TODO: Active applications, upcoming demos, etc.
          ],
        ),
      ),
    );
  }
}
