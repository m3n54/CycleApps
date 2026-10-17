import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../../theme/cycle_theme.dart';
import '../calendar/calendar_screen.dart';
import '../couple/couple_space_screen.dart';
import '../settings/settings_screen.dart';
import 'home_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = ref.watch(unreadCoupleInteractionsCountProvider);

    final Widget coupleIcon = unreadCount > 0
        ? const Badge(child: Icon(Icons.favorite_border_rounded))
        : const Icon(Icons.favorite_border_rounded);

    final Widget coupleSelectedIcon = unreadCount > 0
        ? const Badge(
            child: Icon(Icons.favorite_rounded, color: CycleColors.primary),
          )
        : const Icon(Icons.favorite_rounded, color: CycleColors.primary);

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          CalendarScreen(),
          CoupleSpaceScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: isDark ? CycleColors.surfaceDark : CycleColors.surfaceLight,
        indicatorColor: CycleColors.primary.withValues(alpha: 0.14),
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.spa_outlined),
            selectedIcon: Icon(Icons.spa, color: CycleColors.primary),
            label: 'Beranda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month, color: CycleColors.primary),
            label: 'Kalender',
          ),
          NavigationDestination(
            icon: coupleIcon,
            selectedIcon: coupleSelectedIcon,
            label: 'Ruang Pasangan',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: CycleColors.primary),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
