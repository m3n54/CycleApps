import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/features/common/widgets/cycle_logo.dart';

void main() {
  testWidgets('CycleLogo renders with default size and gradient badge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: CycleLogo()),
        ),
      ),
    );

    expect(find.byType(CycleLogo), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    final logoFinder = find.byType(CycleLogo);
    final size = tester.getSize(logoFinder);
    expect(size.width, 64.0);
    expect(size.height, 64.0);
  });

  testWidgets('CycleLogo supports custom size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: CycleLogo(size: 96)),
        ),
      ),
    );

    final logoFinder = find.byType(CycleLogo);
    expect(logoFinder, findsOneWidget);
    final size = tester.getSize(logoFinder);
    expect(size.width, 96.0);
    expect(size.height, 96.0);
  });
}
