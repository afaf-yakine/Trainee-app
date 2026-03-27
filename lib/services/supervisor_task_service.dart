import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupervisorTaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createTaskForInternship({
    required String internshipId,
    required String internshipTitle,
    required String supervisorId,
    required String title,
    required String description,
    required String status,
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
        'status': status,
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
