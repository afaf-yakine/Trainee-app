import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import 'dashboard_shell.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const int _pageSize = 10;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _users = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

  int _totalUsers = 0;
  int _adminCount = 0;
  int _supervisorCount = 0;
  int _internCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _users.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    await Future.wait([
      _loadStats(),
      _loadUsers(reset: true),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStats() async {
    final snapshot = await _firestore.collection('users').get();
    int admin = 0;
    int supervisor = 0;
    int intern = 0;

    for (final doc in snapshot.docs) {
      final role = (doc.data()['role'] ?? 'intern').toString();
      if (role == 'admin') {
        admin++;
      } else if (role == 'supervisor') {
        supervisor++;
      } else {
        intern++;
      }
    }

    if (mounted) {
      setState(() {
        _totalUsers = snapshot.docs.length;
        _adminCount = admin;
        _supervisorCount = supervisor;
        _internCount = intern;
      });
    }
  }

  Future<void> _loadUsers({bool reset = false}) async {
    if (_isLoading || (!_hasMore && !reset)) return;

    setState(() => _isLoading = true);

    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .orderBy('name')
        .limit(_pageSize);

    if (!reset && _lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      _hasMore = false;
    } else {
      _lastDocument = snapshot.docs.last;
      _users.addAll(snapshot.docs);
      if (snapshot.docs.length < _pageSize) {
        _hasMore = false;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const delta = 200.0;

    if (maxScroll - currentScroll <= delta && _hasMore && !_isLoading) {
      _loadUsers();
    }
  }

  Future<void> _updateRole(
    String uid,
    String newRole,
  ) async {
    await _firestore.collection('users').doc(uid).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _loadInitialData();
  }

  Future<void> _deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();

    await _loadInitialData();
  }

  Future<void> _openEditDialog(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();

    final nameController = TextEditingController(text: (data['name'] ?? '').toString());
    final emailController =
        TextEditingController(text: (data['email'] ?? '').toString());
    final specializationController = TextEditingController(
      text: (data['specialization'] ?? data['specialty'] ?? '').toString(),
    );
    String selectedRole = (data['role'] ?? 'intern').toString();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: specializationController,
                  decoration: const InputDecoration(labelText: 'Specialization'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'supervisor', child: Text('Supervisor')),
                    DropdownMenuItem(value: 'intern', child: Text('Intern')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedRole = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection('users').doc(doc.id).update({
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'specialization': specializationController.text.trim(),
                  'role': selectedRole,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                await _loadInitialData();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return DashboardShell(
      title: appState.translate('admin'),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appState.translate('admin_control_panel'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatsGrid(appState),
            const SizedBox(height: 32),
            _buildUserManagementSection(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AppState appState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width < 600 ? 1 : (width < 1000 ? 2 : 4);
        final aspectRatio = width < 600 ? 2.5 : 1.5;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          children: [
            _buildAdminStatCard(
              appState.translate('total_users'),
              '$_totalUsers',
              Icons.people,
              Colors.indigoAccent,
            ),
            _buildAdminStatCard(
              appState.translate('admins'),
              '$_adminCount',
              Icons.admin_panel_settings,
              Colors.tealAccent,
            ),
            _buildAdminStatCard(
              appState.translate('supervisors'),
              '$_supervisorCount',
              Icons.manage_accounts,
              Colors.amberAccent,
            ),
            _buildAdminStatCard(
              appState.translate('interns'),
              '$_internCount',
              Icons.school,
              Colors.greenAccent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdminStatCard(
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildUserManagementSection(AppState appState) {
    return Container(
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
              Text(
                appState.translate('users'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1F44),
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _loadInitialData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _users.isEmpty && _isLoading
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _users.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    if (index == _users.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const SizedBox.shrink(),
                        ),
                      );
                    }

                    final doc = _users[index];
                    final data = doc.data();
                    final role = (data['role'] ?? 'intern').toString();
                    final name = (data['name'] ?? 'No Name').toString();
                    final email = (data['email'] ?? '').toString();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF5F5F5),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Color(0xFF0A1F44)),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('$email\nRole: $role'),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _openEditDialog(context, doc);
                          } else if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) {
                                return AlertDialog(
                                  title: const Text('Delete user'),
                                  content: const Text(
                                    'Are you sure you want to delete this user?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirm == true) {
                              await _deleteUser(doc.id);
                            }
                          } else {
                            await _updateRole(doc.id, value);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'admin',
                            child: Text('Make Admin'),
                          ),
                          PopupMenuItem(
                            value: 'supervisor',
                            child: Text('Make Supervisor'),
                          ),
                          PopupMenuItem(
                            value: 'intern',
                            child: Text('Make Intern'),
                          ),
                          PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit User'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete User',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          if (_hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _loadUsers,
                  child: const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}