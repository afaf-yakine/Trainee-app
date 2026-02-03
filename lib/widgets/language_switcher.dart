import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    return DropdownButton<String>(
      value: appState.locale.languageCode,
      onChanged: (String? newValue) {
        if (newValue != null) {
          appState.setLocale(newValue);
        }
      },
      underline: const SizedBox(),
      items: [
        DropdownMenuItem(value: 'en', child: Text('🇬🇧 English')),
        DropdownMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
        DropdownMenuItem(value: 'ar', child: Text('🇩🇿 العربية')),
      ],
    );
  }
}
