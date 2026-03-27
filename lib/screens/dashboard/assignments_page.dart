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
  String? _selectedSupervisorId;
  final List<String> _selectedInternIds = [];

  void _log(String message) {
    if (kDebugMode) debugPrint('[AssignmentsPage] $message');
  }

  Future<void> _assignInternship(String chosenSupervisorId) async {
    _log('ENTER _assignInternship');
    _log('chosenSupervisorId=$chosenSupervisorId');
    _log('_selectedInternshipId=$_selectedInternshipId');
    _log('_selectedInternIds=$_selectedInternIds');
    _log('_saving=$_saving');

    if (_selectedInternshipId == null) {
      _log('EXIT: no internship selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an internship')),
      );
      return;
    }

    if (_selectedInternIds.isEmpty) {
      _log('EXIT: no interns selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one intern')),
      );
      return;
    }

    if (chosenSupervisorId.isEmpty) {
      _log('EXIT: no supervisor selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supervisor')),
      );
      return;
    }

    setState(() => _saving = true);
    _log('_saving set true');

    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      _log('adminId=$adminId');

      final internshipRef =
          _firestore.collection('internships').doc(_selectedInternshipId);
      final internshipDoc = await internshipRef.get();
      _log('internshipDoc.exists=${internshipDoc.exists}');

      final internshipData = internshipDoc.data() ?? {};
      _log('internshipData=$internshipData');

      final internshipTitle =
          (internshipData['title'] ?? _selectedInternshipTitle ?? '')
              .toString();
      _log('internshipTitle=$internshipTitle');

      final batch = _firestore.batch();

      for (final internId in _selectedInternIds) {
        _log('processing internId=$internId');

        final internRef = _firestore.collection('users').doc(internId);
        final internDoc = await internRef.get();
        _log('internDoc.exists for $internId = ${internDoc.exists}');

        final internData = internDoc.data() ?? {};
        _log('internData for $internId = $internData');

        final internName = (internData['name'] ??
                '${internData['firstName'] ?? ''} ${internData['lastName'] ?? ''}')
            .toString()
            .trim();
        _log('internName=$internName');

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
            'supervisorId': chosenSupervisorId,
            'assignedByAdminId': adminId,
            'status': 'assigned',
            'assignedAt': FieldValue.serverTimestamp(),
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        _log('queued assignment write: $assignmentId');

        debugPrint('ABOUT TO UPDATE users/$internId');
        debugPrint('payload: {assignedSupervisorId: $chosenSupervisorId}');

        await internRef.set(
          {
            'assignedSupervisorId': chosenSupervisorId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        debugPrint('UPDATED users/$internId SUCCESSFULLY');
      }

      _log('committing batch...');
      await batch.commit();
      _log('batch committed');

      if (!mounted) {
        _log('not mounted after commit');
        return;
      }

      setState(() {
        _selectedInternIds.clear();
      });
      _log('cleared selected interns');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Internship assigned successfully')),
      );
      _log('success snackbar shown');
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
        _log('_saving set false');
      }
      _log('EXIT _assignInternship');
    }
  }

  Future<void> _handleAssignPressed() async {
    _log('ENTER _handleAssignPressed');
    _log('_selectedSupervisorId=$_selectedSupervisorId');
    await _assignInternship(_selectedSupervisorId ?? '');
  }

  @override
  Widget build(BuildContext context) {
    _log('build called');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            debugPrint('RAW BUTTON TAP');
            _handleAssignPressed();
          },
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Assign Internship'),
        ),
      ),
    );
  }
}
