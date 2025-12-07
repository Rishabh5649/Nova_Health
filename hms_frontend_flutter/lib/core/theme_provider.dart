// lib/core/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ThemeMode provider (runtime only). Defaults to dark.
final themeModeProvider = StateProvider<ThemeMode>((_) => ThemeMode.dark);

/// Helper to toggle ThemeMode
extension ThemeModeToggle on StateController<ThemeMode> {
  void toggle() {
    state = (state == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;
  }
}
