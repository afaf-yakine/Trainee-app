import 'package:aoo/screens/dashboard/task_details_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import 'dashboard_shell.dart';
import 'supervisor_internships_page.dart';

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> {
  String? get _supervisorId => FirebaseAuth.instance.currentUser?.uid;

  int _selectedPage = 0;

  Future<int> _countInterns(String supervisorId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'intern')
        .where('assignedSupervisorId', isEqualTo: supervisorId)
        .get();
    return snapshot.docs.length;
  }

  Future<int> _countInternships(String supervisorId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('internships')
        .where('supervisorId', isEqualTo: supervisorId)
        .get();
    return snapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final supervisorId = _supervisorId;

    final pages = [
      LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (supervisorId == null) {
            return const Center(
              child: Text(
                'No supervisor logged in',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

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
                FutureBuilder<List<int>>(
                  future: Future.wait([
                    _countInterns(supervisorId),
                    _countInternships(supervisorId),
                  ]),
                  builder: (context, snapshot) {
                    final totalInterns =
                        snapshot.data != null ? snapshot.data![0] : 0;
                    final internshipsCount =
                        snapshot.data != null ? snapshot.data![1] : 0;

                    final cards = [
                      _buildSummaryCard(
                        appState.translate('total_interns'),
                        '$totalInterns',
                        Icons.people_outline,
                        Colors.blue,
                      ),
                      _buildSummaryCard(
                        appState.translate('pending_reviews'),
                        '5',
                        Icons.rate_review_outlined,
                        Colors.orange,
                      ),
                      _buildSummaryCard(
                        appState.translate('average_progress'),
                        '78%',
                        Icons.trending_up_rounded,
                        Colors.green,
                      ),
                      _buildSummaryCard(
                        'Internships Count',
                        '$internshipsCount',
                        Icons.work_outline,
                        Colors.purple,
                      ),
                    ];

                    return Column(
                      children: [
                        if (isMobile)
                          Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 16),
                              cards[1],
                              const SizedBox(height: 16),
                              cards[2],
                              const SizedBox(height: 16),
                              cards[3],
                            ],
                          )
                        else
                          Row(
                            children: [
                              Expanded(child: cards[0]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[1]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[2]),
                              const SizedBox(width: 16),
                              Expanded(child: cards[3]),
                            ],
                          ),
                        const SizedBox(height: 32),
                        _buildInternsTable(appState, supervisorId),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
      const SupervisorInternshipsPage(),
      SupervisorTasksPage(supervisorId: supervisorId),
      SupervisorAttendancePage(supervisorId: supervisorId),
      const Center(
        child: Text(
          'PROFILE PLACEHOLDER',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    ];

    return DashboardShell(
      title: appState.translate('supervisor'),
      pages: pages,
      initialIndex: _selectedPage,
      selectedIndex: _selectedPage,
      onItemSelected: (index) {
        setState(() => _selectedPage = index);
      },
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildInternsTable(AppState appState, String supervisorId) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appState.translate('interns'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1F44),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'intern')
                .where('assignedSupervisorId', isEqualTo: supervisorId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final interns = snapshot.data!.docs;

              if (interns.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No interns found'),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text(appState.translate('name'))),
                    DataColumn(label: Text(appState.translate('project'))),
                    DataColumn(label: Text(appState.translate('progress'))),
                    DataColumn(label: Text(appState.translate('status'))),
                    const DataColumn(label: Text('Attendance')),
                  ],
                  rows: interns.map((doc) {
                    final data = doc.data();
                    final name = (data['name'] ??
                            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}')
                        .toString()
                        .trim();
                    final project =
                        (data['projectName'] ?? data['project'] ?? 'No project')
                            .toString();
                    final progressValue = _toProgressValue(data['progress']);
                    final status = (data['status'] ?? 'Unknown').toString();

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            name.isEmpty ? 'No Name' : name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(Text(project)),
                        DataCell(
                          SizedBox(
                            width: 120,
                            child: LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF0A1F44),
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(status)),
                        DataCell(
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedPage = 3;
                              });
                            },
                            child: const Text('Open'),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  double _toProgressValue(dynamic value) {
    if (value == null) return 0;
    if (value is num) {
      final v = value.toDouble();
      return v > 1 ? v / 100 : v;
    }
    final text = value.toString().replaceAll('%', '').trim();
    final parsed = double.tryParse(text) ?? 0;
    return parsed > 1 ? parsed / 100 : parsed;
  }
}

class SupervisorTasksPage extends StatefulWidget {
  final String? supervisorId;
  const SupervisorTasksPage({super.key, required this.supervisorId});

  @override
  State<SupervisorTasksPage> createState() => _SupervisorTasksPageState();
}

class _SupervisorTasksPageState extends State<SupervisorTasksPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupervisorTaskService _service = SupervisorTaskService();

  Future<void> _openCreateTaskDialog(BuildContext context) async {
    if (widget.supervisorId == null) return;

    final internshipSnapshot = await _firestore
        .collection('internships')
        .where('supervisorId', isEqualTo: widget.supervisorId)
        .get();

    if (!mounted) return;

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedInternshipId;
    String? selectedInternshipTitle;
    DateTime? dueDate;
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate:
                    dueDate ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) setDialogState(() => dueDate = picked);
            }

            return AlertDialog(
              title: const Text('Create Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedInternshipId,
                      decoration:
                          const InputDecoration(labelText: 'Select Internship'),
                      items: internshipSnapshot.docs.map((doc) {
                        final data = doc.data();
                        final title =
                            (data['title'] ?? 'Untitled Internship').toString();
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(title),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedInternshipId = value;
                          final match = internshipSnapshot.docs
                              .where((d) => d.id == value)
                              .toList();
                          selectedInternshipTitle = match.isNotEmpty
                              ? (match.first.data()['title'] ?? '').toString()
                              : null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration:
                          const InputDecoration(labelText: 'Task Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(labelText: 'Task Description'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dueDate == null
                                ? 'No due date selected'
                                : 'Due: ${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                        TextButton(
                          onPressed: pickDate,
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (selectedInternshipId == null ||
                              titleController.text.trim().isEmpty) return;
                          setDialogState(() => saving = true);
                          try {
                            await _service.createTaskForInternship(
                              internshipId: selectedInternshipId!,
                              internshipTitle: selectedInternshipTitle ?? '',
                              supervisorId: widget.supervisorId!,
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              dueDate: dueDate,
                            );
                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Task created and assigned')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          } finally {
                            if (mounted) setDialogState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openEditTaskDialog(
    BuildContext context,
    String taskId,
    Map<String, dynamic> taskData,
  ) async {
    if (widget.supervisorId == null) return;

    final internshipSnapshot = await _firestore
        .collection('internships')
        .where('supervisorId', isEqualTo: widget.supervisorId)
        .get();

    if (!mounted) return;

    final titleController =
        TextEditingController(text: (taskData['title'] ?? '').toString());
    final descriptionController =
        TextEditingController(text: (taskData['description'] ?? '').toString());

    String taskStatus = (taskData['status'] ?? 'active').toString();
    String internshipId = (taskData['internshipId'] ?? '').toString();
    String internshipTitle = (taskData['internshipTitle'] ?? '').toString();

    DateTime? dueDate;
    final dueRaw = taskData['dueDate'];
    if (dueRaw is Timestamp) dueDate = dueRaw.toDate();

    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate:
                    dueDate ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) setDialogState(() => dueDate = picked);
            }

            return AlertDialog(
              title: const Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: internshipId.isEmpty ? null : internshipId,
                      decoration:
                          const InputDecoration(labelText: 'Internship'),
                      items: internshipSnapshot.docs.map((doc) {
                        final data = doc.data();
                        final title =
                            (data['title'] ?? 'Untitled Internship').toString();
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(title),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          internshipId = value ?? '';
                          final match = internshipSnapshot.docs
                              .where((d) => d.id == value)
                              .toList();
                          internshipTitle = match.isNotEmpty
                              ? (match.first.data()['title'] ?? '').toString()
                              : '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration:
                          const InputDecoration(labelText: 'Task Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(labelText: 'Task Description'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: taskStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'paused', child: Text('Paused')),
                        DropdownMenuItem(
                            value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (value) {
                        if (value != null)
                          setDialogState(() => taskStatus = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dueDate == null
                                ? 'No due date selected'
                                : 'Due: ${dueDate!.year}-${dueDate!.month.toString().padLeft(2, '0')}-${dueDate!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                        TextButton(
                          onPressed: pickDate,
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (titleController.text.trim().isEmpty) return;
                          setDialogState(() => saving = true);
                          try {
                            await _service.updateTaskAndAssignments(
                              taskId: taskId,
                              supervisorId: widget.supervisorId!,
                              internshipId: internshipId,
                              internshipTitle: internshipTitle,
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              status: taskStatus,
                              dueDate: dueDate,
                            );
                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task updated')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          } finally {
                            if (mounted) setDialogState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteTask(BuildContext context, String taskId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Delete this task and all its assignments?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _service.deleteTask(taskId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.supervisorId == null) {
      return const Center(
        child: Text(
          'No supervisor logged in',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1F44),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openCreateTaskDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('tasks')
                    .where('supervisorId', isEqualTo: widget.supervisorId)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Text('Error: ${snapshot.error}');
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data!.docs;

                  if (tasks.isEmpty) {
                    return const Center(child: Text('No tasks found'));
                  }

                  return ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = tasks[index];
                      final task = doc.data();
                      final title = (task['title'] ?? 'Untitled').toString();
                      final description =
                          (task['description'] ?? '').toString();
                      final internshipTitle =
                          (task['internshipTitle'] ?? '').toString();
                      final status = (task['status'] ?? '').toString();

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text('Internship: $internshipTitle'),
                                  const SizedBox(height: 6),
                                  Text(description),
                                  const SizedBox(height: 6),
                                  Text('Status: $status'),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'open') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TaskDetailsPage(taskId: doc.id),
                                    ),
                                  );
                                } else if (value == 'edit') {
                                  _openEditTaskDialog(context, doc.id, task);
                                } else if (value == 'delete') {
                                  _confirmDeleteTask(context, doc.id);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                    value: 'open', child: Text('Open')),
                                PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupervisorAttendancePage extends StatefulWidget {
  final String? supervisorId;

  const SupervisorAttendancePage({super.key, required this.supervisorId});

  @override
  State<SupervisorAttendancePage> createState() =>
      _SupervisorAttendancePageState();
}

class _SupervisorAttendancePageState extends State<SupervisorAttendancePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _openAttendanceDialog({
    String? docId,
    Map<String, dynamic>? existingData,
  }) async {
    if (widget.supervisorId == null) return;

    final internsSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'intern')
        .where('assignedSupervisorId', isEqualTo: widget.supervisorId)
        .get();

    if (!mounted) return;

    final noteController = TextEditingController(
      text: (existingData?['note'] ?? '').toString(),
    );

    String? selectedInternId = (existingData?['internId'] ?? '').toString();
    String selectedInternName =
        (existingData?['internName'] ?? '').toString();
    String selectedStatus =
        (existingData?['status'] ?? 'present').toString();
    String selectedInternshipId =
        (existingData?['internshipId'] ?? '').toString();
    String selectedInternshipTitle =
        (existingData?['internshipTitle'] ?? '').toString();

    DateTime selectedDate = DateTime.now();
    final rawDate = existingData?['date'];
    if (rawDate is Timestamp) {
      selectedDate = rawDate.toDate();
    }

    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setDialogState(() => selectedDate = picked);
            }

            return AlertDialog(
              title: Text(docId == null ? 'Add Attendance' : 'Edit Attendance'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedInternId,
                      decoration: const InputDecoration(labelText: 'Intern'),
                      items: internsSnapshot.docs.map((doc) {
                        final data = doc.data();
                        final name = (data['name'] ??
                                '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}')
                            .toString()
                            .trim();
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(name.isEmpty ? 'No Name' : name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedInternId = value;
                          final match = internsSnapshot.docs
                              .where((d) => d.id == value)
                              .toList();
                          selectedInternName = match.isNotEmpty
                              ? ((match.first.data()['name'] ??
                                      '${match.first.data()['firstName'] ?? ''} ${match.first.data()['lastName'] ?? ''}')
                                  .toString()
                                  .trim())
                              : '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                            value: 'present', child: Text('Present')),
                        DropdownMenuItem(
                            value: 'absent', child: Text('Absent')),
                        DropdownMenuItem(value: 'late', child: Text('Late')),
                        DropdownMenuItem(
                            value: 'excused', child: Text('Excused')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Date: ${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                        TextButton(
                          onPressed: pickDate,
                          child: const Text('Pick Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (selectedInternId == null ||
                              selectedInternId!.isEmpty) return;

                          setDialogState(() => saving = true);
                          try {
                            final attendanceId =
                                '${widget.supervisorId}_${selectedInternId}_${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

                            await _firestore
                                .collection('attendance_sessions')
                                .doc(attendanceId)
                                .set({
                              'uid': attendanceId,
                              'supervisorId': widget.supervisorId,
                              'internId': selectedInternId,
                              'internName': selectedInternName,
                              'internshipId': selectedInternshipId,
                              'internshipTitle': selectedInternshipTitle,
                              'date': Timestamp.fromDate(
                                DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                ),
                              ),
                              'status': selectedStatus,
                              'note': noteController.text.trim(),
                              'createdBySupervisorId': widget.supervisorId,
                              'createdAt': FieldValue.serverTimestamp(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            }, SetOptions(merge: true));

                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Attendance saved')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          } finally {
                            if (mounted) setDialogState(() => saving = false);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteAttendance(String docId) async {
    await _firestore.collection('attendance_sessions').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.supervisorId == null) {
      return const Center(
        child: Text(
          'No supervisor logged in',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attendance',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1F44),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openAttendanceDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Attendance'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('attendance_sessions')
                    .where('supervisorId', isEqualTo: widget.supervisorId)
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
                    return const Center(
                        child: Text('No attendance records found'));
                  }

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final internName =
                          (data['internName'] ?? 'No Name').toString();
                      final internshipTitle =
                          (data['internshipTitle'] ?? 'No internship')
                              .toString();
                      final status = (data['status'] ?? 'present').toString();
                      final note = (data['note'] ?? '').toString();
                      final rawDate = data['date'];
                      String dateText = '';
                      if (rawDate is Timestamp) {
                        final d = rawDate.toDate();
                        dateText =
                            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
                      }

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    internName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Internship: $internshipTitle'),
                                  const SizedBox(height: 4),
                                  Text('Date: $dateText'),
                                  const SizedBox(height: 4),
                                  Text('Status: $status'),
                                  if (note.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('Note: $note'),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  await _openAttendanceDialog(
                                    docId: doc.id,
                                    existingData: data,
                                  );
                                } else if (value == 'delete') {
                                  await _deleteAttendance(doc.id);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                    value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                    value: 'delete', child: Text('Delete')),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupervisorTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTaskForInternship({
    required String internshipId,
    required String internshipTitle,
    required String supervisorId,
    required String title,
    required String description,
    DateTime? dueDate,
  }) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    final taskId = _firestore.collection('tasks').doc().id;

    final internshipDoc =
        await _firestore.collection('internships').doc(internshipId).get();
    if (!internshipDoc.exists) {
      throw Exception('Internship not found');
    }

    final internAssignmentsSnapshot = await _firestore
        .collection('internship_assignments')
        .where('internshipId', isEqualTo: internshipId)
        .get();

    final batch = _firestore.batch();

    batch.set(
      _firestore.collection('tasks').doc(taskId),
      {
        'uid': taskId,
        'internshipId': internshipId,
        'internshipTitle': internshipTitle,
        'supervisorId': supervisorId,
        'title': title,
        'description': description,
        'status': 'active',
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
        'createdByAdminId': adminId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    for (final doc in internAssignmentsSnapshot.docs) {
      final data = doc.data();
      final internId = (data['internId'] ?? '').toString();
      final internName = (data['internName'] ?? '').toString();
      if (internId.isEmpty) continue;

      final assignmentId = '${taskId}_$internId';

      batch.set(
        _firestore.collection('task_assignments').doc(assignmentId),
        {
          'uid': assignmentId,
          'taskId': taskId,
          'internshipId': internshipId,
          'internId': internId,
          'internName': internName,
          'supervisorId': supervisorId,
          'taskTitle': title,
          'taskDescription': description,
          'status': 'assigned',
          'assignedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> updateTaskAndAssignments({
    required String taskId,
    required String supervisorId,
    required String internshipId,
    required String internshipTitle,
    required String title,
    required String description,
    required String status,
    DateTime? dueDate,
  }) async {
    final taskRef = _firestore.collection('tasks').doc(taskId);

    final assignmentsSnapshot = await _firestore
        .collection('task_assignments')
        .where('taskId', isEqualTo: taskId)
        .get();

    final batch = _firestore.batch();

    batch.set(
      taskRef,
      {
        'internshipId': internshipId,
        'internshipTitle': internshipTitle,
        'supervisorId': supervisorId,
        'title': title,
        'description': description,
        'status': status,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    for (final doc in assignmentsSnapshot.docs) {
      batch.set(
        doc.reference,
        {
          'taskTitle': title,
          'taskDescription': description,
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  Future<void> deleteTask(String taskId) async {
    final assignmentsSnapshot = await _firestore
        .collection('task_assignments')
        .where('taskId', isEqualTo: taskId)
        .get();

    final batch = _firestore.batch();
    batch.delete(_firestore.collection('tasks').doc(taskId));

    for (final doc in assignmentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}