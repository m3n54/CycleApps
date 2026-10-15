import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DayLogScreen extends ConsumerStatefulWidget {
  const DayLogScreen({super.key, required this.date});
  final DateTime date;

  @override
  ConsumerState<DayLogScreen> createState() => _DayLogScreenState();
}

class _DayLogScreenState extends ConsumerState<DayLogScreen> {
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Catat hari')));
}
