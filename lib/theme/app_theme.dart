import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

final ValueNotifier<bool> isDarkMode = ValueNotifier(false);

Future<void> loadSavedTheme() async {
  final settingsBox = Hive.box('settingsBox');
  final saved = settingsBox.get('isDarkMode', defaultValue: false);
  isDarkMode.value = saved;
}

void toggleTheme(bool value) {
  isDarkMode.value = value;
  final settingsBox = Hive.box('settingsBox');
  settingsBox.put('isDarkMode', value);
}

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xFFB185A7),
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFFFF8F5),
  fontFamily: 'Roboto',
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xFFB185A7),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xFF1A1618),
  fontFamily: 'Roboto',
);