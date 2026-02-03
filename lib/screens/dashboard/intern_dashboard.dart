import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'dashboard_shell.dart';

class InternDashboard extends StatelessWidget {
  const InternDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return DashboardShell(
      title: appState.translate('intern'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 1100;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(context),
                const SizedBox(height: 32),
                if (!isNarrow)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildStatsRow(appState, constraints.maxWidth),
                            const SizedBox(height: 24),
                            _buildTaskList(appState),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _buildProfileCard(appState),
                            const SizedBox(height: 24),
                            _buildNotificationsList(appState),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildStatsRow(appState, constraints.maxWidth),
                      const SizedBox(height: 24),
                      _buildProfileCard(appState),
                      const SizedBox(height: 24),
                      _buildTaskList(appState),
                      const SizedBox(height: 24),
                      _buildNotificationsList(appState),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, John Doe 👋',
          style: TextStyle(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          'Here is what is happening with your internship today.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatsRow(AppState appState, double width) {
    final bool isSmall = width < 600;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(
          'Tasks Completed',
          '12/15',
          Icons.check_circle_outline,
          Colors.blue,
          isSmall,
          width,
        ),
        _buildStatCard(
          'Attendance',
          '95%',
          Icons.calendar_today,
          Colors.green,
          isSmall,
          width,
        ),
        _buildStatCard(
          'Days Left',
          '45',
          Icons.timer_outlined,
          Colors.orange,
          isSmall,
          width,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isSmall,
    double width,
  ) {
    return SizedBox(
      width: isSmall ? double.infinity : (width < 900 ? 180 : 220),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskList(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appState.translate('tasks'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const Divider(),
            _buildTaskItem('Feature Implementation', 'High', 'Pending'),
            _buildTaskItem('Bug Fixing', 'Medium', 'Completed'),
            _buildTaskItem('Documentation', 'Low', 'In Progress'),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(String title, String priority, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.assignment_outlined, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Priority: $priority',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'Completed'
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: status == 'Completed' ? Colors.green : Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryColor,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'John Doe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Software Engineering Intern',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildProfileInfo(Icons.email_outlined, 'john.doe@example.com'),
            _buildProfileInfo(Icons.phone_outlined, '+1 234 567 890'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () {}, child: const Text('Edit Profile')),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appState.translate('notifications'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildNotificationItem('New task assigned', '2 hours ago'),
            _buildNotificationItem('Report approved', '5 hours ago'),
            _buildNotificationItem('Meeting scheduled', 'Yesterday'),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            size: 18,
            color: AppTheme.notificationColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14)),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
