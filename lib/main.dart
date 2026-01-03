import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/title_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: GungiApp()));
}

class GungiApp extends StatelessWidget {
  const GungiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '軍儀',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const TitleScreen(),
    );
  }
}
