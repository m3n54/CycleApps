import 'package:flutter/material.dart';

import '../../theme/cycle_theme.dart';
import '../calendar/calendar_screen.dart';
import '../insights/insights_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          CalendarScreen(),
          InsightsScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: isDark ? CycleColors.surfaceDark : CycleColors.surfaceLight,
        indicatorColor: CycleColors.primary.withValues(alpha: 0.14),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa, color: CycleColors.primary),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: CycleColors.primary),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: CycleColors.primary),
            label: 'Insight',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: CycleColors.primary),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
