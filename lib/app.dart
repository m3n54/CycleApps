import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_gate.dart';
import 'features/common/widgets/responsive_bounds.dart';
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
      builder: (context, child) => ResponsiveBounds(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const AuthGate(),
    );
  }
}

typedef SiklusApp = CycleApp;
