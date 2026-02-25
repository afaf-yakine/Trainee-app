import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/app_state.dart';

class DashboardShell extends StatefulWidget {
  final Widget child;
  final String title;
  final List<Widget>? pages;
  final int selectedIndex;
  final Function(int)? onItemSelected;

  const DashboardShell({
    super.key,
    required this.child,
    required this.title,
    this.pages,
    this.selectedIndex = 0,
    this.onItemSelected,
  });

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  final GlobalKey _notificationKey = GlobalKey();

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

    // Fetch unread notifications from Firestore and mark as read
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
                        fontSize: 18),
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
                        child: Text('No notifications',
                            style: TextStyle(color: Colors.white70)),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['title'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14)),
                          subtitle: Text(data['message'] ?? '',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
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

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A1F44), Color(0xFF1E3C72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Let gradient show through
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: Text(
            widget.title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white),
          ),
          actions: [
            // Notification Bell
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .collection('notifications')
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount =
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
                                fontWeight: FontWeight.bold),
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
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
                const PopupMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
                const PopupMenuItem(value: 'ar', child: Text('🇸🇦 العربية')),
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
                child: _buildNavItems(context, appState),
              ))
            : null,
        body: Row(
          children: [
            if (!isMobile) _buildSidebar(context, appState),
            Expanded(
              child: widget.pages != null
                  ? widget.pages![widget.selectedIndex]
                  : widget.child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AppState appState) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2), // Subtle overlay on gradient
        border: const Border(right: BorderSide(color: Colors.white10)),
      ),
      child: _buildNavItems(context, appState),
    );
  }

  Widget _buildNavItems(BuildContext context, AppState appState) {
    return Column(
      children: [
        const SizedBox(height: 40),
        // Custom Application Logo
        Image.asset(
          'assets/images/logo.png',
          width: 80,
          height: 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.school, size: 60, color: Colors.white),
        ),
        const SizedBox(height: 40),
        _navItem(context, appState, Icons.dashboard, 'dashboard', 0),
        _navItem(context, appState, Icons.task_alt, 'tasks', 1),
        _navItem(context, appState, Icons.calendar_month, 'attendance', 2),
        _navItem(context, appState, Icons.folder, 'documents', 3),
        const Spacer(),
        _navItem(context, appState, Icons.person, 'profile', 4),
        _logoutItem(context, appState),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _navItem(
    BuildContext context,
    AppState appState,
    IconData icon,
    String key,
    int index,
  ) {
    final isSelected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          if (widget.onItemSelected != null) {
            widget.onItemSelected!(index);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: Colors.white24) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.white70,
              ),
              const SizedBox(width: 16),
              Text(
                appState.translate(key),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutItem(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          appState.setUserRole(null);
          Navigator.pushNamedAndRemoveUntil(
              context, '/login', (route) => false);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: const [
              Icon(Icons.logout, color: Colors.redAccent),
              SizedBox(width: 16),
              Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
