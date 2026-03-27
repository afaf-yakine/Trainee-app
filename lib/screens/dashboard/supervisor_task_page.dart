import 'package:aoo/screens/dashboard/supervisor_dashboard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
    if (widget.supervisorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No supervisor logged in')),
      );
      return;
    }

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
    String statusValue = 'active';
    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() => dueDate = picked);
              }
            }

            return AlertDialog(
              title: const Text('Create Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedInternshipId,
                      decoration: const InputDecoration(labelText: 'Internship'),
                      items: internshipSnapshot.docs.map((doc) {
                        final data = doc.data();
                        final title = (data['title'] ?? 'Untitled Internship').toString();
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(title),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedInternshipId = value;
                          final match = internshipSnapshot.docs.where((d) => d.id == value).toList();
                          selectedInternshipTitle = match.isNotEmpty
                              ? (match.first.data()['title'] ?? '').toString()
                              : '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Task Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Task Description'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: statusValue,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'paused', child: Text('Paused')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (value) {
                        if (value != null) setDialogState(() => statusValue = value);
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
                          if (selectedInternshipId == null) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('Select an internship')),
                            );
                            return;
                          }
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('Enter a task title')),
                            );
                            return;
                          }

                          setDialogState(() => saving = true);
                          try {
                            await _service.createTaskForInternship(
                              internshipId: selectedInternshipId!,
                              internshipTitle: selectedInternshipTitle ?? '',
                              supervisorId: widget.supervisorId!,
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              status: statusValue,
                              dueDate: dueDate,
                            );
                            if (!mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task created and assigned')),
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
    final titleController =
        TextEditingController(text: (taskData['title'] ?? '').toString());
    final descriptionController =
        TextEditingController(text: (taskData['description'] ?? '').toString());

    String statusValue = (taskData['status'] ?? 'active').toString();
    String internshipId = (taskData['internshipId'] ?? '').toString();
    String internshipTitle = (taskData['internshipTitle'] ?? '').toString();

    DateTime? dueDate;
    final dueRaw = taskData['dueDate'];
    if (dueRaw is Timestamp) dueDate = dueRaw.toDate();

    final internshipSnapshot = await _firestore
        .collection('internships')
        .where('supervisorId', isEqualTo: widget.supervisorId)
        .get();

    if (!mounted) return;

    bool saving = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setDialogState(() => dueDate = picked);
              }
            }

            return AlertDialog(
              title: const Text('Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: internshipId.isEmpty ? null : internshipId,
                      decoration: const InputDecoration(labelText: 'Internship'),
                      items: internshipSnapshot.docs.map((doc) {
                        final data = doc.data();
                        final title = (data['title'] ?? 'Untitled Internship').toString();
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(title),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          internshipId = value ?? '';
                          final match = internshipSnapshot.docs.where((d) => d.id == value).toList();
                          internshipTitle = match.isNotEmpty
                              ? (match.first.data()['title'] ?? '').toString()
                              : '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Task Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Task Description'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: statusValue,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(value: 'paused', child: Text('Paused')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      ],
                      onChanged: (value) {
                        if (value != null) setDialogState(() => statusValue = value);
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
                          if (titleController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('Enter a task title')),
                            );
                            return;
                          }

                          setDialogState(() => saving = true);
                          try {
                            await _service.updateTaskAndAssignments(
                              taskId: taskId,
                              supervisorId: widget.supervisorId!,
                              internshipId: internshipId,
                              internshipTitle: internshipTitle,
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              status: statusValue,
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
          content: const Text('Delete this task and all assignments?'),
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
      await _service.deleteTask(taskId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.supervisorId == null) {
      return const Center(child: Text('No supervisor logged in'));
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
                  if (snapshot.hasError) return Text('Error: ${snapshot.error}');
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
                      final description = (task['description'] ?? '').toString();
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
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openEditTaskDialog(context, doc.id, task);
                                } else if (value == 'delete') {
                                  _confirmDeleteTask(context, doc.id);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(value: 'delete', child: Text('Delete')),
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