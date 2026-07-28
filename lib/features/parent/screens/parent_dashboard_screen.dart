import 'package:flutter/material.dart';
import 'package:tht_app/features/shared/widgets/stat_card.dart';

/// Parent's dashboard tab — shows stats and quick actions.
class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Fetch dashboard stats from /api/jobs/stats/parent/
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
                    icon: Icons.work_outline,
                    label: 'Active Jobs',
                    value: '0',
                    tintColor: Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    icon: Icons.people_outline,
                    label: 'Applications',
                    value: '0',
                    tintColor: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.check_circle_outline,
                    label: 'Hired Tutors',
                    value: '0',
                    tintColor: Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Credits',
                    value: '0',
                    tintColor: Colors.purple,
                  ),
                ),
              ],
            ),
            
            // TODO: Unlocked contacts list, recent applications, etc.
          ],
        ),
      ),
    );
  }
}
