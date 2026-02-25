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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appState.translate('supervisor_dashboard_title'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                if (isMobile)
                  Column(
                    children: [
                      _buildSummaryCard(appState.translate('total_interns'),
                          '12', Icons.people_outline, Colors.blue),
                      const SizedBox(height: 16),
                      _buildSummaryCard(appState.translate('pending_reviews'),
                          '5', Icons.rate_review_outlined, Colors.orange),
                      const SizedBox(height: 16),
                      _buildSummaryCard(appState.translate('average_progress'),
                          '78%', Icons.trending_up_rounded, Colors.green),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                          child: _buildSummaryCard(
                              appState.translate('total_interns'),
                              '12',
                              Icons.people_outline,
                              Colors.blue)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildSummaryCard(
                              appState.translate('pending_reviews'),
                              '5',
                              Icons.rate_review_outlined,
                              Colors.orange)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildSummaryCard(
                              appState.translate('average_progress'),
                              '78%',
                              Icons.trending_up_rounded,
                              Colors.green)),
                    ],
                  ),
                const SizedBox(height: 32),
                _buildInternsTable(appState),
                const SizedBox(height: 32),
                _buildMeetingsSchedule(appState),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildInternsTable(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appState.translate('interns'),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1F44))),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text(appState.translate('name'))),
                DataColumn(label: Text(appState.translate('project'))),
                DataColumn(label: Text(appState.translate('progress'))),
                DataColumn(label: Text(appState.translate('status'))),
                DataColumn(label: Text(appState.translate('actions'))),
              ],
              rows: [
                _buildDataRow('Alice Johnson', 'Mobile App', '85%', 'Active'),
                _buildDataRow('Bob Smith', 'Backend API', '40%', 'On Leave'),
                _buildDataRow('Charlie Brown', 'UI Design', '95%', 'Active'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(
      String name, String project, String progress, String status) {
    return DataRow(
      cells: [
        DataCell(
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(project)),
        DataCell(SizedBox(
            width: 80,
            child: LinearProgressIndicator(
                value: double.parse(progress.replaceAll('%', '')) / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF0A1F44))))),
        DataCell(Text(status)),
        DataCell(
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {})),
      ],
    );
  }

  Widget _buildMeetingsSchedule(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(appState.translate('meetings'),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1F44))),
          const SizedBox(height: 16),
          _buildMeetingItem(
              'Weekly Sync', 'Today, 2:00 PM', 'Google Meet', appState),
          _buildMeetingItem(
              'Project Review', 'Tomorrow, 10:00 AM', 'Room 302', appState),
        ],
      ),
    );
  }

  Widget _buildMeetingItem(
      String title, String time, String location, AppState appState) {
    return ListTile(
      leading: const Icon(Icons.event, color: Color(0xFF0A1F44)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('$time • $location'),
      trailing: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0A1F44),
            foregroundColor: Colors.white),
        child: Text(appState.translate('join')),
      ),
    );
  }
}
