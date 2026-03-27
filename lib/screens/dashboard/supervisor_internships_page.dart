import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SupervisorInternshipsPage extends StatefulWidget {
  const SupervisorInternshipsPage({super.key});

  @override
  State<SupervisorInternshipsPage> createState() =>
      _SupervisorInternshipsPageState();
}

class _SupervisorInternshipsPageState extends State<SupervisorInternshipsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _saving = false;

  String? _editingDocId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? get _currentSupervisorId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _saveInternship() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final supervisorId = _currentSupervisorId;

    if (supervisorId == null) return;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = {
        'title': title,
        'description': description,
        'supervisorId': supervisorId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_editingDocId == null) {
        await _firestore.collection('internships').add({
          ...payload,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('internships').doc(_editingDocId).update(payload);
      }

      _titleController.clear();
      _descriptionController.clear();
      _editingDocId = null;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Internship saved successfully')),
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

  Future<void> _deleteInternship(String docId) async {
    await _firestore.collection('internships').doc(docId).delete();
  }

  void _editInternship(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    _titleController.text = (data['title'] ?? '').toString();
    _descriptionController.text = (data['description'] ?? '').toString();
    _editingDocId = doc.id;
    setState(() {});
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _editingDocId = null;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final supervisorId = _currentSupervisorId;

    if (supervisorId == null) {
      return const Center(child: Text('No supervisor found'));
    }

    final query = _firestore
        .collection('internships')
        .where('supervisorId', isEqualTo: supervisorId)
        .orderBy('createdAt', descending: true);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Internships',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingDocId == null ? 'Create Internship' : 'Edit Internship',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0A1F44),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _saving ? null : _saveInternship,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_editingDocId == null ? 'Save' : 'Update'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _resetForm,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final internships = snapshot.data!.docs;

              if (internships.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No internships found',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: internships.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = internships[index];
                    final data = doc.data();
                    final title = (data['title'] ?? '').toString();
                    final description = (data['description'] ?? '').toString();

                    return ListTile(
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(description),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _editInternship(doc);
                          } else if (value == 'delete') {
                            await _deleteInternship(doc.id);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}