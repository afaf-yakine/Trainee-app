import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'assignments_page.dart';

import '../../providers/app_state.dart';
import 'dashboard_shell.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  static const int _pageSize = 10;

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _users = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastUserDoc;
  bool _usersLoading = false;
  bool _usersHasMore = true;

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
      _users.clear();
      _lastUserDoc = null;
      _usersHasMore = true;
      _usersLoading = true;
    });

    await Future.wait([
      _loadStats(),
      _loadUsers(reset: true),
    ]);

    if (mounted) setState(() => _usersLoading = false);
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

  Query<Map<String, dynamic>> _buildUsersQuery() {
    return _firestore.collection('users').orderBy('name');
  }

  Future<void> _loadUsers({bool reset = false}) async {
    if (_usersLoading || (!_usersHasMore && !reset)) return;

    setState(() => _usersLoading = true);

    Query<Map<String, dynamic>> query = _buildUsersQuery().limit(_pageSize);

    if (!reset && _lastUserDoc != null) {
      query = query.startAfterDocument(_lastUserDoc!);
    }

    final snapshot = await query.get();

    if (snapshot.docs.isEmpty) {
      _usersHasMore = false;
    } else {
      _lastUserDoc = snapshot.docs.last;
      _users.addAll(snapshot.docs);
      if (snapshot.docs.length < _pageSize) {
        _usersHasMore = false;
      }
    }

    if (mounted) setState(() => _usersLoading = false);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    const delta = 200.0;

    if (maxScroll - currentScroll <= delta && _usersHasMore && !_usersLoading) {
      _loadUsers();
    }
  }

  Future<void> _updateRole(String uid, String newRole) async {
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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _getDepartments() async {
    final snapshot =
        await _firestore.collection('departments').orderBy('name').get();
    return snapshot.docs;
  }

  Future<void> _openUserEditDialog(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();

    final firstNameController =
        TextEditingController(text: (data['firstName'] ?? '').toString());
    final lastNameController =
        TextEditingController(text: (data['lastName'] ?? '').toString());
    final emailController =
        TextEditingController(text: (data['email'] ?? '').toString());
    final specializationController = TextEditingController(
      text: (data['specialization'] ?? data['specialty'] ?? '').toString(),
    );

    String selectedRole = (data['role'] ?? 'intern').toString();
    String? selectedDepartmentId = data['departmentId']?.toString();
    String selectedDepartmentName = (data['departmentName'] ?? '').toString();

    final departments = await _getDepartments();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: firstNameController,
                      decoration:
                          const InputDecoration(labelText: 'First Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: specializationController,
                      decoration:
                          const InputDecoration(labelText: 'Specialization'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                            value: 'supervisor', child: Text('Supervisor')),
                        DropdownMenuItem(
                            value: 'intern', child: Text('Intern')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedRole = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedDepartmentId,
                      decoration:
                          const InputDecoration(labelText: 'Department'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No department'),
                        ),
                        ...departments.map((dept) {
                          final deptData = dept.data();
                          return DropdownMenuItem<String>(
                            value: dept.id,
                            child: Text(
                                (deptData['name'] ?? 'Unnamed').toString()),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          setDialogState(() {
                            selectedDepartmentId = null;
                            selectedDepartmentName = '';
                          });
                          return;
                        }

                        final dept =
                            departments.firstWhere((d) => d.id == value);
                        final deptData = dept.data();

                        setDialogState(() {
                          selectedDepartmentId = value;
                          selectedDepartmentName =
                              (deptData['name'] ?? '').toString();
                        });
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
                    final firstName = firstNameController.text.trim();
                    final lastName = lastNameController.text.trim();
                    final fullName = '$firstName $lastName'.trim();

                    await _firestore.collection('users').doc(doc.id).update({
                      'firstName': firstName,
                      'lastName': lastName,
                      'name': fullName,
                      'fullName': fullName,
                      'fullNameLower': fullName.toLowerCase(),
                      'email': emailController.text.trim(),
                      'specialization': specializationController.text.trim(),
                      'role': selectedRole,
                      'departmentId': selectedDepartmentId,
                      'departmentName': selectedDepartmentName,
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
      },
    );
  }

  Future<void> _openDepartmentDialog({
    DocumentSnapshot<Map<String, dynamic>>? departmentDoc,
  }) async {
    final nameController = TextEditingController(
      text: departmentDoc?.data()?['name']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: departmentDoc?.data()?['description']?.toString() ?? '',
    );

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
              departmentDoc == null ? 'Add Department' : 'Edit Department'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();

                if (name.isEmpty) return;

                final payload = {
                  'name': name,
                  'description': description,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (departmentDoc == null) {
                  await _firestore.collection('departments').add({
                    ...payload,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                } else {
                  await _firestore
                      .collection('departments')
                      .doc(departmentDoc.id)
                      .update(payload);
                }

                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteDepartment(String departmentId) async {
    await _firestore.collection('departments').doc(departmentId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    final pages = [
      SingleChildScrollView(
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
            _buildDepartmentsSection(),
            const SizedBox(height: 32),
            _buildUserManagementSection(),
          ],
        ),
      ),
      const AssignmentsPage(),
      const Center(
        child: Text(
          'PROFILE PLACEHOLDER',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    ];

    return DashboardShell(
      title: appState.translate('admin'),
      pages: pages,
      initialIndex: 0,
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

  Widget _buildDepartmentsSection() {
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
              const Text(
                'Departments',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1F44),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _openDepartmentDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A1F44),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Department'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('departments')
                .orderBy('name')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final departments = snapshot.data!.docs;

              if (departments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No departments found'),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: departments.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final dept = departments[index];
                  final data = dept.data();
                  final name = (data['name'] ?? '').toString();
                  final description = (data['description'] ?? '').toString();

                  return ListTile(
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              _openDepartmentDialog(departmentDoc: dept),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () async {
                            await _deleteDepartment(dept.id);
                          },
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
    );
  }

  Widget _buildUserManagementSection() {
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
                'Users (${_users.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1F44),
                ),
              ),
              IconButton(
                onPressed: _usersLoading ? null : _loadInitialData,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _users.isEmpty && _usersLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _users.length + (_usersHasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    if (index == _users.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: _usersLoading
                              ? const CircularProgressIndicator()
                              : const SizedBox.shrink(),
                        ),
                      );
                    }

                    final doc = _users[index];
                    final data = doc.data();
                    final role = (data['role'] ?? 'intern').toString();
                    final fullName =
                        (data['name'] ?? data['fullName'] ?? 'No Name')
                            .toString();
                    final email = (data['email'] ?? '').toString();
                    final departmentName =
                        (data['departmentName'] ?? 'No department').toString();

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFF5F5F5),
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Color(0xFF0A1F44)),
                        ),
                      ),
                      title: Text(
                        fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                          '$email\nRole: $role\nDepartment: $departmentName'),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            await _openUserEditDialog(context, doc);
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
          if (_usersHasMore)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: OutlinedButton(
                  onPressed: _usersLoading ? null : _loadUsers,
                  child: const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
