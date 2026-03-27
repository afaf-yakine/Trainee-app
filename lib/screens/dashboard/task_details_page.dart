import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TaskDetailsPage extends StatefulWidget {
  final String taskId;
  const TaskDetailsPage({super.key, required this.taskId});

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();

  String? _currentUserId;
  String? _currentUserRole;
  bool _isAdminReadOnly = true;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserRole();
    _ensureChatExists();
  }

  Future<void> _loadUserRole() async {
    final uid = _currentUserId;
    if (uid == null) return;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!mounted || !doc.exists) return;

    final role = (doc.data()?['role'] ?? '').toString();
    setState(() {
      _currentUserRole = role;
      _isAdminReadOnly = role == 'admin';
    });
  }

  Future<void> _ensureChatExists() async {
    final taskDoc =
        await _firestore.collection('tasks').doc(widget.taskId).get();
    if (!taskDoc.exists) return;

    final task = taskDoc.data()!;
    final supervisorId = (task['supervisorId'] ?? '').toString();
    final internshipId = (task['internshipId'] ?? '').toString();

    final assignmentSnapshot = await _firestore
        .collection('task_assignments')
        .where('taskId', isEqualTo: widget.taskId)
        .get();

    final participantIds = <String>{};
    if (supervisorId.isNotEmpty) participantIds.add(supervisorId);

    for (final doc in assignmentSnapshot.docs) {
      final data = doc.data();
      final internId = (data['internId'] ?? '').toString();
      if (internId.isNotEmpty) participantIds.add(internId);
    }

    final chatId = widget.taskId;

    await _firestore.collection('task_chats').doc(chatId).set({
      'taskId': widget.taskId,
      'supervisorId': supervisorId,
      'internshipId': internshipId,
      'participantIds': participantIds.toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null || _isAdminReadOnly) return;

    final userDoc =
        await _firestore.collection('users').doc(_currentUserId).get();
    final role = (userDoc.data()?['role'] ?? '').toString();

    final chatRef = _firestore.collection('task_chats').doc(widget.taskId);
    final messageRef = chatRef.collection('messages').doc();

    final batch = _firestore.batch();

    batch.set(messageRef, {
      'senderId': _currentUserId,
      'senderRole': role,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [_currentUserId],
    });

    batch.set(
        chatRef,
        {
          'lastMessage': text,
          'lastMessageAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));

    await batch.commit();
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: const Color(0xFF0A1F44),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('tasks').doc(widget.taskId).snapshots(),
        builder: (context, taskSnapshot) {
          if (taskSnapshot.hasError) {
            return Center(child: Text('Error: ${taskSnapshot.error}'));
          }
          if (!taskSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final taskData = taskSnapshot.data!.data();
          if (taskData == null) {
            return const Center(child: Text('Task not found'));
          }

          final title = (taskData['title'] ?? '').toString();
          final description = (taskData['description'] ?? '').toString();
          final status = (taskData['status'] ?? '').toString();
          final internshipTitle =
              (taskData['internshipTitle'] ?? '').toString();

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Internship: $internshipTitle'),
                            const SizedBox(height: 8),
                            Text('Status: $status'),
                            const SizedBox(height: 12),
                            Text(description),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore
                          .collection('task_chats')
                          .doc(widget.taskId)
                          .collection('messages')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, msgSnapshot) {
                        if (msgSnapshot.hasError) {
                          return Text('Error: ${msgSnapshot.error}');
                        }
                        if (!msgSnapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        final messages = msgSnapshot.data!.docs;
                        if (messages.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('No messages yet'),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: messages.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final msg = messages[index].data();
                            final senderId = (msg['senderId'] ?? '').toString();
                            final senderRole =
                                (msg['senderRole'] ?? '').toString();
                            final text = (msg['text'] ?? '').toString();

                            final isMe = senderId == _currentUserId;

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 320),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFF0A1F44)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      senderRole,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            isMe ? Colors.white70 : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      text,
                                      style: TextStyle(
                                        color: isMe
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (!_isAdminReadOnly)
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border:
                          Border(top: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Write a message...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _sendMessage,
                          child: const Text('Send'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isAdminReadOnly)
                const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Admin view only',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
