import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:siklus/theme/cycle_theme.dart';

void main() {
  test('CycleTheme provides distinct light and dark themes with custom colors', () {
    final light = CycleTheme.lightTheme;
    final dark = CycleTheme.darkTheme;

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.colorScheme.primary, const Color(0xFFBE185D));
    expect(dark.colorScheme.primary, const Color(0xFFF472B6));
    expect(CycleColors.phaseMenstrual, const Color(0xFFE11D48));
    expect(CycleColors.phaseOvulation, const Color(0xFF7C3AED));
  });
}
