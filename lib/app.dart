import 'package:flutter/material.dart';

import 'features/auth/auth_gate.dart';

class SiklusApp extends StatelessWidget {
  const SiklusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Siklus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFFD9475B), useMaterial3: true),
      home: const AuthGate(),
    );
  }
}
