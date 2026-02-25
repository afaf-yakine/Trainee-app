import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'dashboard_shell.dart';
import '../../utils/download_helper.dart';

class InternDashboard extends StatefulWidget {
  const InternDashboard({super.key});

  @override
  State<InternDashboard> createState() => _InternDashboardState();
}

class _InternDashboardState extends State<InternDashboard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    final stats = {
      'tasks_completed': appState.currentUserStats['tasksCompleted'] ?? '0/0',
      'attendance': appState.currentUserStats['attendance'] ?? '0%',
      'days_left': appState.currentUserStats['daysLeft'] ?? '0',
    };

    final tasks = appState.currentUserTasks;
    final documents = appState.currentUserDocuments;

    final pages = [
      _buildDashboardHome(appState, stats, tasks),
      _buildTasksPage(appState, tasks),
      _buildAttendancePage(),
      _buildDocumentsPage(documents),
      _buildProfilePage(appState),
    ];

    return DashboardShell(
      title: appState.translate('intern'),
      selectedIndex: _currentIndex,
      onItemSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      pages: pages,
      child: pages[_currentIndex],
    );
  }

  Widget _buildDashboardHome(AppState appState, Map<String, String> stats,
      List<Map<String, String>> tasks) {
    final isNarrow = MediaQuery.of(context).size.width < 1100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeHeader(appState),
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
                  child: _buildQuickProfile(appState),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildStatsRow(appState, stats),
                const SizedBox(height: 24),
                _buildQuickProfile(appState),
                const SizedBox(height: 24),
                _buildTaskList(appState, tasks),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader(AppState appState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${appState.translate('welcome')}, ${appState.currentUserName} 👋',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          appState.translate('intern_welcome_message'),
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatsRow(AppState appState, Map<String, String> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = (constraints.maxWidth - 32) / 3;
        if (cardWidth < 180) cardWidth = constraints.maxWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
                appState.translate('tasks_completed'),
                stats['tasks_completed']!,
                Icons.check_circle_outline,
                cardWidth),
            _buildStatCard(appState.translate('attendance'),
                stats['attendance']!, Icons.calendar_today, cardWidth),
            _buildStatCard(appState.translate('days_left'), stats['days_left']!,
                Icons.timer_outlined, cardWidth),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1F44).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickProfile(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF0A1F44),
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(appState.currentUserName,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1F44))),
          Text(appState.currentUserEmail,
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            dense: true,
            leading: const Icon(Icons.work_outline, color: Color(0xFF0A1F44)),
            title: Text(appState.translate('specialization')),
            subtitle: Text(appState.currentUserSpecialty),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(AppState appState, List<Map<String, String>> tasks) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(appState.translate('tasks'),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1F44))),
              TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: const Text('View All')),
            ],
          ),
          const Divider(),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('No tasks assigned yet')),
            )
          else
            ...tasks.take(3).map((task) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF5F5F5),
                      child: Icon(Icons.task, color: Color(0xFF0A1F44))),
                  title: Text(task['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(task['status'] ?? ''),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          _getPriorityColor(task['priority']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(task['priority'] ?? '',
                        style: TextStyle(
                            color: _getPriorityColor(task['priority']),
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                )),
        ],
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Widget _buildTasksPage(AppState appState, List<Map<String, String>> tasks) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            title: Text(task['title'] ?? ''),
            subtitle: Text(task['status'] ?? ''),
            trailing: Text(task['priority'] ?? ''),
          ),
        );
      },
    );
  }

  Widget _buildAttendancePage() {
    return const Center(
        child: Text('Attendance tracking details',
            style: TextStyle(color: Colors.white)));
  }

  Widget _buildDocumentsPage(List<Map<String, dynamic>> documents) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading:
                const Icon(Icons.insert_drive_file, color: Color(0xFF0A1F44)),
            title: Text(doc['name'] ?? 'File'),
            trailing: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                final url = doc['url'];
                if (url != null) downloadFile(url, doc['name'] ?? 'file');
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfilePage(AppState appState) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Colors.white));

        final data = snapshot.data!.data() as Map<String, dynamic>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 32),
              _buildProfileInfoCard(appState, [
                {
                  'label': appState.translate('email'),
                  'value': data['email'] ?? ''
                },
                {
                  'label': appState.translate('internship_duration'),
                  'value':
                      '${data['startDate'] ?? 'N/A'} - ${data['endDate'] ?? 'N/A'}'
                },
                {
                  'label': appState.translate('supervisor_name'),
                  'value': data['supervisorName'] ?? 'Not assigned'
                },
                {
                  'label': appState.translate('department'),
                  'value': data['department'] ?? data['specialization'] ?? 'N/A'
                },
                {
                  'label': appState.translate('internship_type'),
                  'value': data['internshipType'] ?? 'N/A'
                },
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileInfoCard(
      AppState appState, List<Map<String, String>> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['label']!.toUpperCase(),
                    style: const TextStyle(
                        color: Color(0xFF0A1F44),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(item['value']!,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
