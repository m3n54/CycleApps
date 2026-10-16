import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_gate.dart';
import 'state/providers.dart';
import 'theme/cycle_theme.dart';

class CycleApp extends ConsumerWidget {
  const CycleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'CycleApp',
      debugShowCheckedModeBanner: false,
      theme: CycleTheme.lightTheme,
      darkTheme: CycleTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
    );
  }
}

typedef SiklusApp = CycleApp;
