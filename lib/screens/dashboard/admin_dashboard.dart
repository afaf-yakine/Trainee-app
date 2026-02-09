import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import 'dashboard_shell.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return DashboardShell(
      title: appState.translate('admin'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appState.translate('admin_control_panel'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatsGrid(appState, constraints.maxWidth),
                const SizedBox(height: 32),
                _buildUserManagementSection(appState),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(AppState appState, double width) {
    int crossAxisCount = width < 600 ? 1 : (width < 1000 ? 2 : 4);
    double aspectRatio = width < 600 ? 2.5 : 1.5;

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
          '1,240',
          Icons.people,
          Colors.indigo,
        ),
        _buildAdminStatCard(
          appState.translate('active_sessions'),
          '342',
          Icons.login_rounded,
          Colors.teal,
        ),
        _buildAdminStatCard(
          appState.translate('new_requests'),
          '18',
          Icons.pending_actions_rounded,
          Colors.amber,
        ),
        _buildAdminStatCard(
          appState.translate('system_health'),
          appState.translate('good'),
          Icons.health_and_safety_outlined,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildAdminStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(title, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserManagementSection(AppState appState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: Text(appState.translate('add_user')),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildUserList(appState),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(AppState appState) {
    final roles = [
      appState.translate('supervisor'),
      appState.translate('intern')
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text('${appState.translate('user')} ${index + 1}'),
          subtitle: Text('${appState.translate('role')}: ${roles[index % 2]}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {},
                tooltip: appState.translate('edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {},
                tooltip: appState.translate('delete'),
              ),
            ],
          ),
        );
      },
    );
  }
}
