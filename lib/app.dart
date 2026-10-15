import 'package:flutter/material.dart';

class SiklusApp extends StatelessWidget {
  const SiklusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Siklus terhubung ke Firebase'))),
    );
  }
}
