import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/app_state.dart';
import '../../utils/download_helper.dart';
import 'dashboard_shell.dart';
import 'task_details_page.dart';

class InternDashboard extends StatefulWidget {
  const InternDashboard({super.key});

  @override
  State<InternDashboard> createState() => _InternDashboardState();
}

class _InternDashboardState extends State<InternDashboard> {
  int _currentIndex = 0;

  String? get _internId => FirebaseAuth.instance.currentUser?.uid;

  Future<List<Map<String, dynamic>>> _loadInternTasks(String internId) async {
    final assignmentsSnapshot = await FirebaseFirestore.instance
        .collection('internship_assignments')
        .where('internId', isEqualTo: internId)
        .get();

    final assignments = assignmentsSnapshot.docs.map((d) => d.data()).toList();

    if (assignments.isEmpty) return [];

    final internshipIds = <String>{};
    final supervisorIds = <String>{};

    for (final a in assignments) {
      final internshipId = (a['internshipId'] ?? '').toString();
      final supervisorId = (a['supervisorId'] ?? '').toString();

      if (internshipId.isNotEmpty) internshipIds.add(internshipId);
      if (supervisorId.isNotEmpty) supervisorIds.add(supervisorId);
    }

    if (internshipIds.isEmpty || supervisorIds.isEmpty) return [];

    final taskSnapshot = await FirebaseFirestore.instance.collection('tasks').get();

    final filtered = taskSnapshot.docs.where((doc) {
      final task = doc.data();
      final taskInternshipId = (task['internshipId'] ?? '').toString();
      final taskSupervisorId = (task['supervisorId'] ?? '').toString();

      return internshipIds.contains(taskInternshipId) &&
          supervisorIds.contains(taskSupervisorId);
    }).toList();

    return filtered.map((doc) {
      final task = doc.data();
      return {
        'taskId': doc.id,
        'title': (task['title'] ?? 'Untitled').toString(),
        'status': (task['status'] ?? '').toString(),
        'priority': (task['priority'] ?? 'medium').toString(),
        'description': (task['description'] ?? '').toString(),
        'dueDate': task['dueDate'],
        'internshipId': (task['internshipId'] ?? '').toString(),
        'supervisorId': (task['supervisorId'] ?? '').toString(),
      };
    }).toList();
  }

  Future<Map<String, String>> _loadInternStats(String internId) async {
    final tasks = await _loadInternTasks(internId);

    final completedCount = tasks.where((task) {
      final status = (task['status'] ?? '').toString().toLowerCase();
      return status == 'completed' || status == 'done';
    }).length;

    final totalCount = tasks.length;

    return {
      'tasks_completed': '$completedCount/$totalCount',
      'attendance': Provider.of<AppState>(context, listen: false)
              .currentUserStats['attendance'] ??
          '0%',
      'days_left': Provider.of<AppState>(context, listen: false)
              .currentUserStats['daysLeft'] ??
          '0',
    };
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final internId = _internId;

    final documents = appState.currentUserDocuments;

    final pages = [
      _buildDashboardHome(appState, internId),
      _buildTasksPage(appState, internId),
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

  Widget _buildDashboardHome(AppState appState, String? internId) {
    final isNarrow = MediaQuery.of(context).size.width < 1100;

    return FutureBuilder<Map<String, String>>(
      future: internId == null
          ? Future.value({
              'tasks_completed': '0/0',
              'attendance': appState.currentUserStats['attendance'] ?? '0%',
              'days_left': appState.currentUserStats['daysLeft'] ?? '0',
            })
          : _loadInternStats(internId),
      builder: (context, snapshot) {
        final stats = snapshot.data ??
            {
              'tasks_completed': '0/0',
              'attendance': appState.currentUserStats['attendance'] ?? '0%',
              'days_left': appState.currentUserStats['daysLeft'] ?? '0',
            };

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
                          _buildTaskList(appState, internId),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(child: _buildQuickProfile(appState)),
                  ],
                )
              else
                Column(
                  children: [
                    _buildStatsRow(appState, stats),
                    const SizedBox(height: 24),
                    _buildQuickProfile(appState),
                    const SizedBox(height: 24),
                    _buildTaskList(appState, internId),
                  ],
                ),
            ],
          ),
        );
      },
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
              cardWidth,
            ),
            _buildStatCard(
              appState.translate('attendance'),
              stats['attendance']!,
              Icons.calendar_today,
              cardWidth,
            ),
            _buildStatCard(
              appState.translate('days_left'),
              stats['days_left']!,
              Icons.timer_outlined,
              cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    double width,
  ) {
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
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
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
          Text(
            appState.currentUserName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1F44),
            ),
          ),
          Text(
            appState.currentUserEmail,
            style: TextStyle(color: Colors.grey.shade600),
          ),
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

  Widget _buildTaskList(AppState appState, String? internId) {
    if (internId == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(24),
        child: const Text('No intern logged in'),
      );
    }

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
              Text(
                appState.translate('tasks'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1F44),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _currentIndex = 1),
                child: const Text('View All'),
              ),
            ],
          ),
          const Divider(),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadInternTasks(internId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final tasks = snapshot.data!;

              if (tasks.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No tasks assigned yet')),
                );
              }

              return Column(
                children: tasks.take(3).map((task) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFF5F5F5),
                      child: Icon(Icons.task, color: Color(0xFF0A1F44)),
                    ),
                    title: Text(
                      task['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(task['status'] ?? ''),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task['priority']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        task['priority'] ?? '',
                        style: TextStyle(
                          color: _getPriorityColor(task['priority']),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetailsPage(taskId: task['taskId']),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
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

  Widget _buildTasksPage(AppState appState, String? internId) {
    if (internId == null) {
      return const Center(child: Text('No intern logged in'));
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadInternTasks(internId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final tasks = snapshot.data!;

        if (tasks.isEmpty) {
          return const Center(child: Text('No tasks assigned yet'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: Text(task['title'] ?? ''),
                subtitle: Text(task['description'] ?? task['status'] ?? ''),
                trailing: Text(task['priority'] ?? ''),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskDetailsPage(taskId: task['taskId']),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttendancePage() {
    return const Center(
      child: Text(
        'Attendance tracking details',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildDocumentsPage(List<Map<String, dynamic>> documents) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: const Icon(
              Icons.insert_drive_file,
              color: Color(0xFF0A1F44),
            ),
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
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

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
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              _buildProfileInfoCard(appState, [
                {'label': appState.translate('email'), 'value': data['email'] ?? ''},
                {
                  'label': appState.translate('internship_duration'),
                  'value': '${data['startDate'] ?? 'N/A'} - ${data['endDate'] ?? 'N/A'}'
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
    AppState appState,
    List<Map<String, String>> items,
  ) {
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
                Text(
                  item['label']!.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF0A1F44),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item['value']!,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}