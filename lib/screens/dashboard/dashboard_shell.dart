import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/app_state.dart';

class DashboardShell extends StatefulWidget {
  final Widget? child;
  final String title;
  final List<Widget>? pages;
  final int selectedIndex;
  final Function(int)? onItemSelected;
  final int initialIndex;

  const DashboardShell({
    super.key,
    required this.title,
    this.child,
    this.pages,
    this.selectedIndex = 0,
    this.onItemSelected,
    this.initialIndex = 0,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _NavItemData {
  final IconData icon;
  final String labelKey;

  const _NavItemData(this.icon, this.labelKey);
}

class _DashboardShellState extends State<DashboardShell> {
  final GlobalKey _notificationKey = GlobalKey();
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.pages != null ? widget.initialIndex : widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant DashboardShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pages != null && oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex;
    }
    if (widget.pages == null &&
        oldWidget.selectedIndex != widget.selectedIndex) {
      _currentIndex = widget.selectedIndex;
    }
  }

  void _showNotificationsPanel(BuildContext context, AppState appState) async {
    final RenderBox button =
        _notificationKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final batch = FirebaseFirestore.instance.batch();
      final notifications = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }

    if (!mounted) return;

    showMenu(
      context: context,
      position: position,
      color: const Color(0xFF0A1F44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      items: [
        PopupMenuItem(
          enabled: false,
          child: SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    appState.translate('notifications'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('notifications')
                      .orderBy('timestamp', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No notifications',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(
                            data['title'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            data['message'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_NavItemData> _buildMenu(AppState appState) {
    final items = <_NavItemData>[
      const _NavItemData(Icons.dashboard, 'dashboard'),
    ];

    if (appState.userRole == 'admin') {
      items.add(const _NavItemData(Icons.assignment, 'assignments'));
      items.add(const _NavItemData(Icons.people, 'users'));
    }

    if (appState.userRole == 'supervisor') {
      items.add(const _NavItemData(Icons.assignment, 'internships'));
      items.add(const _NavItemData(Icons.assignment, 'tasks'));
      items.add(const _NavItemData(Icons.assignment, 'attendances'));
    }

    if (appState.userRole == 'intern') {
      items.add(const _NavItemData(Icons.assignment, 'tasks'));
    }

    items.add(const _NavItemData(Icons.person, 'profile'));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    final pages = widget.pages;
    final safeIndex = _currentIndex.clamp(
      0,
      pages != null && pages.isNotEmpty ? pages.length - 1 : 0,
    );

    final displayedPage =
        pages != null && pages.isNotEmpty ? pages[safeIndex] : widget.child;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1F44), Color(0xFF1E3C72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: Text(
            widget.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('notifications')
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                final unreadCount =
                    snapshot.hasData ? snapshot.data!.docs.length : 0;

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      key: _notificationKey,
                      icon:
                          const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () =>
                          _showNotificationsPanel(context, appState),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints:
                              const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: const Icon(Icons.language, color: Colors.white),
              onSelected: (code) => appState.setLocale(code),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
                PopupMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
                PopupMenuItem(value: 'ar', child: Text('🇸🇦 العربية')),
              ],
            ),
            const SizedBox(width: 16),
          ],
        ),
        drawer: isMobile
            ? Drawer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0A1F44), Color(0xFF1E3C72)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: _buildSidebar(context, appState, isDrawer: true),
                ),
              )
            : null,
        body: Row(
          children: [
            if (!isMobile) _buildSidebar(context, appState, isDrawer: false),
            Expanded(
              child: displayedPage ?? const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    AppState appState, {
    required bool isDrawer,
  }) {
    final menu = _buildMenu(appState);

    return Container(
      width: isDrawer ? double.infinity : 260,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: isDrawer
            ? null
            : const Border(right: BorderSide(color: Colors.white10)),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 40),
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.school, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 40),
          ...menu.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _currentIndex == index;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                selected: isSelected,
                selectedTileColor: Colors.white.withOpacity(0.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(
                  item.icon,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
                title: Text(
                  appState.translate(item.labelKey),
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _currentIndex = index;
                  });

                  final onItemSelected = widget.onItemSelected;
                  if (onItemSelected != null) {
                    onItemSelected(index);
                  }

                  if (isDrawer && Navigator.of(context).canPop()) {
                    Navigator.pop(context);
                  }
                },
              ),
            );
          }),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                appState.setUserRole(null);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}