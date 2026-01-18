import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    const int booksReading = 2;
    const int booksCompleted = 2;
    const int booksWantToRead = 2;
    const int currentStreak = 9;
    const int yearlyGoal = 24;
    final double goalProgress = (booksCompleted / yearlyGoal) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stats'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Reading Stats',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your reading journey',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Reading Goal Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.purpleStart, AppTheme.indigoEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '2026 Reading Goal',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$booksCompleted of $yearlyGoal books',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      Text(
                        '${goalProgress.round()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goalProgress / 100,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${yearlyGoal - booksCompleted} books to go!',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _buildStatCard(
                  context,
                  icon: Icons.book_outlined,
                  iconColor: Colors.blue,
                  iconBg: Colors.blue.withOpacity(0.1),
                  label: 'Currently Reading',
                  value: '$booksReading',
                ),
                _buildStatCard(
                  context,
                  icon: Icons.check_circle_outline,
                  iconColor: Colors.green,
                  iconBg: Colors.green.withOpacity(0.1),
                  label: 'Completed',
                  value: '$booksCompleted',
                ),
                _buildStatCard(
                  context,
                  icon: Icons.bookmark_outline,
                  iconColor: Colors.orange,
                  iconBg: Colors.orange.withOpacity(0.1),
                  label: 'Want to Read',
                  value: '$booksWantToRead',
                ),
                _buildStatCard(
                  context,
                  icon: Icons.local_fire_department,
                  iconColor: Colors.red,
                  iconBg: Colors.red.withOpacity(0.1),
                  label: 'Current Streak',
                  value: '$currentStreak days',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

