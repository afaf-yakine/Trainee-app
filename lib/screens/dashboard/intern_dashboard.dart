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
    final isNarrow = MediaQuery.of(context).size.width < 1100;

    final stats = {
      'tasks_completed': appState.currentUserStats['tasksCompleted'] ?? '0/0',
      'attendance': appState.currentUserStats['attendance'] ?? '0%',
      'days_left': appState.currentUserStats['daysLeft'] ?? '0',
    };

    final tasks = appState.currentUserTasks;
    final notifications = appState.currentUserNotifications;

    return DashboardShell(
      title: appState.translate('intern'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeHeader(appState, context),
            const SizedBox(height: 32),
            if (!isNarrow)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildStatsRow(appState, stats),
                        const SizedBox(height: 24),
                        _buildTaskList(appState, tasks),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildProfileCard(appState),
                        const SizedBox(height: 24),
                        _buildNotificationsList(appState, notifications),
                      ],
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  _buildStatsRow(appState, stats),
                  const SizedBox(height: 24),
                  _buildProfileCard(appState),
                  const SizedBox(height: 24),
                  _buildTaskList(appState, tasks),
                  const SizedBox(height: 24),
                  _buildNotificationsList(appState, notifications),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // -------------------- Widgets --------------------

  Widget _buildWelcomeHeader(AppState appState, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${appState.translate('welcome')}, ${appState.currentUserName} 👋',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          appState.translate('intern_welcome_message'),
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStatsRow(AppState appState, Map<String, String> stats) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard(
          appState.translate('tasks_completed'),
          stats['tasks_completed']!,
          Icons.check_circle_outline,
        ),
        _buildStatCard(
          appState.translate('attendance'),
          stats['attendance']!,
          Icons.calendar_today,
        ),
        _buildStatCard(
          appState.translate('days_left'),
          stats['days_left']!,
          Icons.timer_outlined,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14)),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(AppState appState) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(appState.currentUserName),
        subtitle: Text(appState.currentUserEmail),
      ),
    );
  }

  Widget _buildTaskList(AppState appState, List<Map<String, String>> tasks) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appState.translate('tasks'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...tasks.map((task) => _buildTaskItem(task)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(Map<String, String> task) {
    return ListTile(
      title: Text(task['title'] ?? ''),
      subtitle: Text(task['status'] ?? ''),
      trailing: Text(task['priority'] ?? ''),
    );
  }

  Widget _buildNotificationsList(
      AppState appState, List<Map<String, String>> notifications) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appState.translate('notifications'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...notifications
                .map((n) => _buildNotificationItem(n['title']!, n['time']!)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, String time) {
    return ListTile(
      title: Text(title),
      subtitle: Text(time),
    );
  }
}
