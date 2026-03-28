import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _saving = false;
  String? _selectedInternshipId;
  String? _selectedInternshipTitle;
  final List<String> _selectedInternIds = [];

  void _log(String message) {
    if (kDebugMode) debugPrint('[AssignmentsPage] $message');
  }

  Future<String> _getUserNameById(String userId) async {
    if (userId.isEmpty) return 'Unknown';
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return 'Unknown';

    final data = doc.data() ?? {};
    final name = (data['name'] ??
            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}')
        .toString()
        .trim();

    return name.isEmpty ? 'Unknown' : name;
  }

  Future<void> _assignInternship() async {
    if (_selectedInternshipId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an internship')),
      );
      return;
    }

    if (_selectedInternIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one intern')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;

      final internshipDoc = await _firestore
          .collection('internships')
          .doc(_selectedInternshipId)
          .get();

      if (!internshipDoc.exists) {
        throw Exception('Internship not found');
      }

      final internshipData = internshipDoc.data() ?? {};
      final internshipTitle =
          (internshipData['title'] ?? _selectedInternshipTitle ?? '').toString();
      final supervisorId = (internshipData['supervisorId'] ?? '').toString();

      if (supervisorId.isEmpty) {
        throw Exception('This internship has no supervisor assigned');
      }

      final batch = _firestore.batch();

      for (final internId in _selectedInternIds) {
        final internRef = _firestore.collection('users').doc(internId);
        final internDoc = await internRef.get();
        final internData = internDoc.data() ?? {};

        final internName = (internData['name'] ??
                '${internData['firstName'] ?? ''} ${internData['lastName'] ?? ''}')
            .toString()
            .trim();

        final assignmentId = '${_selectedInternshipId}_$internId';

        batch.set(
          _firestore.collection('internship_assignments').doc(assignmentId),
          {
            'uid': assignmentId,
            'internshipId': _selectedInternshipId,
            'internshipTitle': internshipTitle,
            'internId': internId,
            'internName': internName,
            'supervisorId': supervisorId,
            'assignedByAdminId': adminId,
            'status': 'assigned',
            'assignedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        batch.set(
          internRef,
          {
            'assignedSupervisorId': supervisorId,
            'internshipId': _selectedInternshipId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();

      if (!mounted) return;

      setState(() {
        _selectedInternIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Internship assigned successfully')),
      );
    } catch (e, st) {
      _log('ERROR: $e');
      _log('STACK: $st');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _openAssignModal() async {
    final internshipsSnapshot =
        await _firestore.collection('internships').get();

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        String? selectedInternshipId = _selectedInternshipId;
        String? selectedInternshipTitle = _selectedInternshipTitle;
        final selectedInternIds = <String>{..._selectedInternIds};
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Internship'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedInternshipId,
                        decoration: const InputDecoration(
                          labelText: 'Select Internship',
                        ),
                        items: internshipsSnapshot.docs.map((doc) {
                          final data = doc.data();
                          final title = (data['title'] ?? 'Untitled').toString();
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(title),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedInternshipId = value;
                            final match = internshipsSnapshot.docs
                                .where((d) => d.id == value)
                                .toList();
                            selectedInternshipTitle = match.isNotEmpty
                                ? (match.first.data()['title'] ?? '').toString()
                                : null;
                            selectedInternIds.clear();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Select Interns',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (selectedInternshipId == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Please select an internship first'),
                        )
                      else
                        FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          future: _firestore
                              .collection('users')
                              .where('role', isEqualTo: 'intern')
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            if (!snapshot.hasData) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              );
                            }

                            final interns = snapshot.data!.docs;
                            if (interns.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('No interns found'),
                              );
                            }

                            return Column(
                              children: interns.map((doc) {
                                final data = doc.data();
                                final internId = doc.id;
                                final name = (data['name'] ??
                                        '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}')
                                    .toString()
                                    .trim();

                                return CheckboxListTile(
                                  value: selectedInternIds.contains(internId),
                                  title: Text(name.isEmpty ? 'No Name' : name),
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  onChanged: (checked) {
                                    setDialogState(() {
                                      if (checked == true) {
                                        selectedInternIds.add(internId);
                                      } else {
                                        selectedInternIds.remove(internId);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            );
                          },
                        ),
                    ],
                  ),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select an internship'),
                              ),
                            );
                            return;
                          }

                          if (selectedInternIds.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select at least one intern'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => saving = true);
                          try {
                            _selectedInternshipId = selectedInternshipId;
                            _selectedInternshipTitle = selectedInternshipTitle;
                            _selectedInternIds
                              ..clear()
                              ..addAll(selectedInternIds);

                            await _assignInternship();

                            if (!mounted) return;
                            Navigator.pop(dialogContext);
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

  Widget _buildRecentAssignments() {
    return Container(
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
            'Recent Internship Assignments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0A1F44),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('internship_assignments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No assignments found'),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final internName =
                      (data['internName'] ?? 'No Name').toString();
                  final internshipTitle =
                      (data['internshipTitle'] ?? 'No Internship').toString();
                  final status = (data['status'] ?? 'assigned').toString();
                  final supervisorId = (data['supervisorId'] ?? '').toString();

                  return FutureBuilder<String>(
                    future: _getUserNameById(supervisorId),
                    builder: (context, supervisorSnapshot) {
                      final supervisorName = supervisorSnapshot.data ?? 'Loading...';

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFF0A1F44),
                              child: Icon(Icons.assignment_ind, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    internName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    internshipTitle,
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Supervisor: $supervisorName',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              status,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _openAssignModal,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Assign Internship'),
              ),
            ),
            const SizedBox(height: 24),
            _buildRecentAssignments(),
          ],
        ),
      ),
    );
  }
}