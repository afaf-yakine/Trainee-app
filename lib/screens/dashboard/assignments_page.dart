import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedInternshipId;
  String? _selectedInternshipTitle;
  final Set<String> _selectedInternIds = {};
  bool _saving = false;

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

      final internshipData = internshipDoc.data() ?? {};
      final internshipTitle =
          (internshipData['title'] ?? _selectedInternshipTitle ?? '')
              .toString();
      final supervisorId = (internshipData['supervisorId'] ?? '').toString();

      final batch = _firestore.batch();

      for (final internId in _selectedInternIds) {
        final internDoc =
            await _firestore.collection('users').doc(internId).get();
        final internData = internDoc.data() ?? {};
        final internName = (internData['name'] ??
                '${internData['firstName'] ?? ''} ${internData['lastName'] ?? ''}')
            .toString()
            .trim();

        final assignmentId = '${_selectedInternshipId}_$internId';
        final assignmentRef =
            _firestore.collection('internship_assignments').doc(assignmentId);

        batch.set(
            assignmentRef,
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
            SetOptions(merge: true));
      }

      await batch.commit();

      if (!mounted) return;
      setState(() {
        _selectedInternIds.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Internship assigned successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assignments',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildInternshipSelector(),
          const SizedBox(height: 24),
          _buildInternsSelector(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _assignInternship,
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Assign Internship'),
            ),
          ),
          const SizedBox(height: 24),
          _buildAssignmentsList(),
        ],
      ),
    );
  }

  Widget _buildInternshipSelector() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore.collection('internships').orderBy('title').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final internships = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedInternshipId,
            decoration: const InputDecoration(
              labelText: 'Select Internship',
              border: OutlineInputBorder(),
            ),
            items: internships.map((doc) {
              final data = doc.data();
              return DropdownMenuItem<String>(
                value: doc.id,
                child: Text((data['title'] ?? 'Untitled').toString()),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              final selected = internships.firstWhere((e) => e.id == value);
              setState(() {
                _selectedInternshipId = value;
                _selectedInternshipTitle =
                    (selected.data()['title'] ?? '').toString();
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildInternsSelector() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('users')
          .where('role', isEqualTo: 'intern')
          .orderBy('name')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final interns = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Interns',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (interns.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No interns found'),
                )
              else
                ...interns.map((doc) {
                  final data = doc.data();
                  final name = (data['name'] ?? 'Unnamed').toString();
                  final email = (data['email'] ?? '').toString();

                  return CheckboxListTile(
                    value: _selectedInternIds.contains(doc.id),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          _selectedInternIds.add(doc.id);
                        } else {
                          _selectedInternIds.remove(doc.id);
                        }
                      });
                    },
                    title: Text(name),
                    subtitle: Text(email),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignmentsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('internship_assignments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final assignments = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Assignments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (assignments.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No assignments yet'),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: assignments.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = assignments[index].data();
                    return ListTile(
                      title: Text((data['internName'] ?? 'Intern').toString()),
                      subtitle: Text(
                        '${data['internshipTitle'] ?? 'Internship'}\nStatus: ${data['status'] ?? 'assigned'}',
                      ),
                      isThreeLine: true,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
