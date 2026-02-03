import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/language_switcher.dart';
import '../../widgets/theme_toggle.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;
  final String title;

  const DashboardShell({super.key, required this.child, required this.title});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          const LanguageSwitcher(),
          const SizedBox(width: 8),
          const ThemeToggle(),
          const SizedBox(width: 16),
          _buildProfileAvatar(),
          const SizedBox(width: 16),
        ],
      ),
      drawer: isMobile ? _buildDrawer(context, appState) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(context, appState),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryColor, width: 2),
      ),
      child: const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white,
        child: Icon(Icons.person, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, AppState appState) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: _buildNavItems(context, appState),
    );
  }

  Widget _buildDrawer(BuildContext context, AppState appState) {
    return Drawer(child: _buildNavItems(context, appState));
  }

  Widget _buildNavItems(BuildContext context, AppState appState) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Icon(
          Icons.school_rounded,
          size: 64,
          color: AppTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        const Text(
          'NoRa',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 32),
        _buildNavItem(
          context,
          appState,
          Icons.dashboard_rounded,
          appState.translate('dashboard'),
          true,
        ),
        _buildNavItem(
          context,
          appState,
          Icons.task_alt_rounded,
          appState.translate('tasks'),
          false,
        ),
        _buildNavItem(
          context,
          appState,
          Icons.calendar_month_rounded,
          appState.translate('attendance'),
          false,
        ),
        _buildNavItem(
          context,
          appState,
          Icons.folder_copy_rounded,
          appState.translate('documents'),
          false,
        ),
        const Spacer(),
        _buildNavItem(
          context,
          appState,
          Icons.settings_rounded,
          appState.translate('settings'),
          false,
        ),
        _buildNavItem(
          context,
          appState,
          Icons.logout_rounded,
          appState.translate('logout'),
          false,
          color: Colors.red,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    AppState appState,
    IconData icon,
    String label,
    bool isSelected, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          if (label == appState.translate('logout')) {
            appState.setUserRole(null);
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          } else {
            // Future navigation logic can be added here
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? AppTheme.primaryColor
                    : (color ?? Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : (color ?? Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
