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
    final attendance = await _loadAttendanceStats(internId);

    final completedCount = tasks.where((task) {
      final status = (task['status'] ?? '').toString().toLowerCase();
      return status == 'completed' || status == 'done';
    }).length;

    final totalCount = tasks.length;

    return {
      'tasks_completed': '$completedCount/$totalCount',
      'attendance': attendance['attendance'] ?? '0%',
      'attendance_summary': attendance['attendance_summary'] ?? '0/0 present',
      'attendance_records': attendance['attendance_records'] ?? '0',
      'days_left': Provider.of<AppState>(context, listen: false)
              .currentUserStats['daysLeft'] ??
          '0',
    };
  }

  Future<Map<String, String>> _loadAttendanceStats(String internId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('attendance_sessions')
        .where('internId', isEqualTo: internId)
        .get();

    if (snapshot.docs.isEmpty) {
      return {
        'attendance': '0%',
        'attendance_summary': '0/0 present',
        'attendance_records': '0',
      };
    }

    int presentCount = 0;
    int totalCount = snapshot.docs.length;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'present') {
        presentCount++;
      }
    }

    final percentage = totalCount == 0 ? 0.0 : (presentCount / totalCount) * 100.0;

    return {
      'attendance': '${percentage.toStringAsFixed(0)}%',
      'attendance_summary': '$presentCount/$totalCount present',
      'attendance_records': '$totalCount',
    };
  }

  String _formatDueDate(dynamic dueDate) {
    if (dueDate == null) return 'No due date';

    DateTime? dateTime;
    if (dueDate is Timestamp) {
      dateTime = dueDate.toDate();
    } else if (dueDate is DateTime) {
      dateTime = dueDate;
    } else {
      return 'No due date';
    }

    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')}';
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

  Widget _taskCard(Map<String, dynamic> task) {
    final title = (task['title'] ?? '').toString();
    final description = (task['description'] ?? '').toString();
    final status = (task['status'] ?? '').toString();
    final priority = (task['priority'] ?? '').toString();
    final dueDate = _formatDueDate(task['dueDate']);

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'in progress':
        statusColor = Colors.orange;
        break;
      case 'pending':
        statusColor = Colors.blue;
        break;
      case 'overdue':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF5F5F5),
          child: Icon(Icons.task, color: Color(0xFF0A1F44)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              description.isEmpty ? 'No description' : description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Status: '),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.isEmpty ? 'Unknown' : status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Due: $dueDate'),
          ],
        ),
        isThreeLine: true,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getPriorityColor(priority).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            priority.isEmpty ? 'N/A' : priority,
            style: TextStyle(
              color: _getPriorityColor(priority),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final internId = _internId;
    final documents = appState.currentUserDocuments;

    final pages = [
      _buildDashboardHome(appState, internId),
      _buildTasksPage(appState, internId),
      _buildAttendancePage(appState, internId),
      _buildDocumentsPage(documents),
      _buildProfilePage(appState),
    ];

    return DashboardShell(
      title: appState.translate('intern'),
      selectedIndex: _currentIndex,
      onItemSelected: (index) {
        setState(() => _currentIndex = index);
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
              'attendance_summary':
                  appState.currentUserStats['attendance_summary'] ?? '0/0 present',
              'attendance_records':
                  appState.currentUserStats['attendance_records'] ?? '0',
              'days_left': appState.currentUserStats['daysLeft'] ?? '0',
            })
          : _loadInternStats(internId),
      builder: (context, snapshot) {
        final stats = snapshot.data ??
            {
              'tasks_completed': '0/0',
              'attendance': appState.currentUserStats['attendance'] ?? '0%',
              'attendance_summary':
                  appState.currentUserStats['attendance_summary'] ?? '0/0 present',
              'attendance_records':
                  appState.currentUserStats['attendance_records'] ?? '0',
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
                Text(title,
                    style: const TextStyle(fontSize: 14, color: Colors.white70)),
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
                children: tasks.take(3).map<Widget>((task) {
                  return _taskCard(task);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
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
            return _taskCard(task);
          },
        );
      },
    );
  }

  Widget _buildAttendancePage(AppState appState, String? internId) {
    if (internId == null) {
      return const Center(child: Text('No intern logged in'));
    }

    return FutureBuilder<Map<String, String>>(
      future: _loadAttendanceStats(internId),
      builder: (context, snapshot) {
        final stats = snapshot.data ??
            {
              'attendance': '0%',
              'attendance_summary': '0/0 present',
              'attendance_records': '0',
            };

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Attendance Rate',
                      stats['attendance']!,
                      Icons.calendar_month,
                      double.infinity,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Present Ratio',
                      stats['attendance_summary']!,
                      Icons.fact_check,
                      double.infinity,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Attendance Records',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1F44),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('attendance_sessions')
                          .where('internId', isEqualTo: internId)
                          .orderBy('date', descending: true)
                          .get(),
                      builder: (context, attendanceSnapshot) {
                        if (attendanceSnapshot.hasError) {
                          return Text('Error: ${attendanceSnapshot.error}');
                        }
                        if (!attendanceSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final docs = attendanceSnapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text('No attendance records found'),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final data = docs[index].data();
                            final status =
                                (data['status'] ?? 'unknown').toString();
                            final note = (data['note'] ?? '').toString();
                            final rawDate = data['date'];
                            String dateText = 'No date';
                            if (rawDate is Timestamp) {
                              final d = rawDate.toDate();
                              dateText =
                                  '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                            }

                            Color statusColor;
                            switch (status.toLowerCase()) {
                              case 'present':
                                statusColor = Colors.green;
                                break;
                              case 'late':
                                statusColor = Colors.orange;
                                break;
                              case 'absent':
                                statusColor = Colors.red;
                                break;
                              case 'excused':
                                statusColor = Colors.blue;
                                break;
                              default:
                                statusColor = Colors.grey;
                            }

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.event_available,
                                      color: statusColor,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateText,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('Status: $status'),
                                        if (note.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text('Note: $note'),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file,
                color: Color(0xFF0A1F44)),
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