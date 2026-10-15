import 'package:flutter/material.dart';

import 'features/auth/auth_gate.dart';
import 'theme/cycle_theme.dart';

class CycleApp extends StatelessWidget {
  const CycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CycleApp',
      debugShowCheckedModeBanner: false,
      theme: CycleTheme.lightTheme,
      darkTheme: CycleTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

typedef SiklusApp = CycleApp;
