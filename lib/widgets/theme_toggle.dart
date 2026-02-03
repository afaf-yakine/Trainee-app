import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return IconButton(
      icon: Icon(
        appState.themeMode == ThemeMode.light
            ? Icons.dark_mode
            : Icons.light_mode,
      ),
      onPressed: () => appState.toggleTheme(),
    );
  }
}
