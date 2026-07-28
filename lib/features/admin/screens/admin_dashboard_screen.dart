import 'package:flutter/material.dart';
import 'package:tht_app/features/shared/widgets/stat_card.dart';

/// Admin / Counsellor Dashboard — Overview stats.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
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
                    icon: Icons.assignment_outlined,
                    label: 'Total Leads',
                    value: '0',
                    tintColor: Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: StatCard(
                    icon: Icons.check_circle_outline,
                    label: 'Closed',
                    value: '0',
                    tintColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
