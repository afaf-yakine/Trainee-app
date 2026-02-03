import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'dashboard_shell.dart';

class SupervisorDashboard extends StatelessWidget {
  const SupervisorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return DashboardShell(
      title: appState.translate('supervisor'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supervisor Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildSummaryCard(
                  'Total Interns',
                  '12',
                  Icons.people_outline,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  'Pending Reviews',
                  '5',
                  Icons.rate_review_outlined,
                  Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  'Average Progress',
                  '78%',
                  Icons.trending_up_rounded,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildInternsTable(appState),
            const SizedBox(height: 32),
            _buildMeetingsSchedule(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInternsTable(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appState.translate('interns'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DataTable(
              columnSpacing: 40,
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Project')),
                DataColumn(label: Text('Progress')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: [
                _buildDataRow('Alice Johnson', 'Mobile App', '85%', 'Active'),
                _buildDataRow('Bob Smith', 'Backend API', '40%', 'On Leave'),
                _buildDataRow('Charlie Brown', 'UI Design', '95%', 'Active'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildDataRow(
    String name,
    String project,
    String progress,
    String status,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        DataCell(Text(project)),
        DataCell(
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: double.parse(progress.replaceAll('%', '')) / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
            ),
          ),
        ),
        DataCell(Text(status)),
        DataCell(
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ),
      ],
    );
  }

  Widget _buildMeetingsSchedule(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appState.translate('meetings'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMeetingItem('Weekly Sync', 'Today, 2:00 PM', 'Google Meet'),
            _buildMeetingItem(
              'Project Review',
              'Tomorrow, 10:00 AM',
              'Room 302',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetingItem(String title, String time, String location) {
    return ListTile(
      leading: const Icon(Icons.event),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$time • $location'),
      trailing: ElevatedButton(onPressed: () {}, child: const Text('Join')),
    );
  }
}
