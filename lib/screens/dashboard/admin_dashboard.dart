import 'package:aoo/screens/dashboard/assignments_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../dashboard/dashboard_shell.dart';
import 'supervisor_dashboard.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  String? get _adminId => FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    final List<Widget> pages = [
      _buildHomePage(appState), // 0
      const AssignmentsPage(),  // 1
      const AdminUsersPage(),   // 2
      const InternshipsManagementPage(), // 3
      const AdminAttendancePage(),       // 4
      const AdminSettingsPage(),         // 5
    ];

    final titles = [
      'Admin Dashboard',
      'Assignments',
      'Users',
      'Internships',
      'Attendance',
      'Settings',
    ];

    return DashboardShell(
      title: titles[_selectedIndex],
      pages: pages,
      selectedIndex: _selectedIndex,
      initialIndex: 0,
      onItemSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      child: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
    );
  }

  Widget _buildHomePage(AppState appState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${appState.currentUserName}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Manage internships, assignments, tasks, and users',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
              const SizedBox(height: 24),
              FutureBuilder<List<int>>(
                future: Future.wait([
                  _countUsers('intern'),
                  _countUsers('supervisor'),
                  _countInternships(),
                ]),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? [0, 0, 0];

                  final cards = [
                    _summaryCard(
                      'Interns',
                      '${data[0]}',
                      Icons.people_outline,
                      Colors.blue,
                    ),
                    _summaryCard(
                      'Supervisors',
                      '${data[1]}',
                      Icons.person_outline,
                      Colors.orange,
                    ),
                    _summaryCard(
                      'Internships',
                      '${data[2]}',
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
                          ],
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _buildRecentAssignments(),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title, style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
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
            stream: FirebaseFirestore.instance
                .collection('internship_assignments')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
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
                      final supervisorName =
                          supervisorSnapshot.data ?? 'Loading...';

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
                              child: Icon(Icons.assignment_ind,
                                  color: Colors.white),
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
                                    style:
                                        const TextStyle(color: Colors.black54),
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
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

  Future<String> _getUserNameById(String userId) async {
    if (userId.isEmpty) return 'Unknown';
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!doc.exists) return 'Unknown';
    final data = doc.data() ?? {};
    final name = (data['name'] ??
            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}')
        .toString()
        .trim();
    return name.isEmpty ? 'Unknown' : name;
  }

  Future<int> _countUsers(String role) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: role)
        .get();
    return snapshot.size;
  }

  Future<int> _countInternships() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('internships').get();
    return snapshot.size;
  }
}

class InternshipsManagementPage extends StatelessWidget {
  const InternshipsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child:
          Text('Internships Management', style: TextStyle(color: Colors.white)),
    );
  }
}

class AdminAttendancePage extends StatelessWidget {
  const AdminAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Attendance Management', style: TextStyle(color: Colors.white)),
    );
  }
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final int _pageSize = 15;

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _users = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;

  @override
  void initState() {
    super.initState();
    _loadMoreUsers();
  }

  String _displayName(Map<String, dynamic> data) {
    final name = (data['name'] ??
            '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}')
        .toString()
        .trim();
    return name.isEmpty ? 'No Name' : name;
  }

  Future<void> _loadMoreUsers() async {
    if (_loadingMore || (!_hasMore && _users.isNotEmpty)) return;

    setState(() {
      if (_users.isEmpty) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
    });

    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snap = await query.get();

      if (snap.docs.isNotEmpty) {
        _lastDoc = snap.docs.last;
      }

      setState(() {
        _users.addAll(snap.docs);
        _hasMore = snap.docs.length == _pageSize;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Load users error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _updateRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).set(
      {
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User role changed to $role')),
      );
    }
  }

  Future<void> _deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();

    if (mounted) {
      setState(() {
        _users.removeWhere((u) => u.id == uid);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted')),
      );
    }
  }

  Widget _userCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final name = _displayName(data);
    final email = (data['email'] ?? '').toString();
    final role = (data['role'] ?? 'unknown').toString();

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
            child: Icon(Icons.person),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  email.isEmpty ? 'No email' : email,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  'Role: $role',
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'intern') {
                await _updateRole(doc.id, 'intern');
              } else if (value == 'supervisor') {
                await _updateRole(doc.id, 'supervisor');
              } else if (value == 'admin') {
                await _updateRole(doc.id, 'admin');
              } else if (value == 'delete') {
                await _deleteUser(doc.id);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'intern', child: Text('Make intern')),
              PopupMenuItem(
                  value: 'supervisor', child: Text('Make supervisor')),
              PopupMenuItem(value: 'admin', child: Text('Make admin')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'delete', child: Text('Delete user')),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
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
              'Users',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1F44),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading && _users.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (_users.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No users found'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _userCard(_users[index]),
              ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: (_loadingMore || !_hasMore) ? null : _loadMoreUsers,
                icon: _loadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.more_horiz),
                label: Text(_hasMore ? 'Load more' : 'No more users'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminSettingsPage extends StatelessWidget {
  const AdminSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings', style: TextStyle(color: Colors.white)),
    );
  }
}