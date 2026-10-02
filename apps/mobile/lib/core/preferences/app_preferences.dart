import 'dart:convert';

import 'package:flutter/material.dart';

abstract interface class PreferencesStore {
  Future<String?> read();
  Future<void> write(String value);
}

class MemoryPreferencesStore implements PreferencesStore {
  MemoryPreferencesStore({this.value});
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async => this.value = value;
}

/// Device preferences survive logout; credentials remain in the session store.
class AppPreferences extends ChangeNotifier {
  AppPreferences(this._store);
  final PreferencesStore _store;
  ThemeMode _themeMode = ThemeMode.system;
  bool _reduceMotion = false;
  bool _onboardingComplete = false;
  Future<void> _writes = Future.value();
  ThemeMode get themeMode => _themeMode;
  bool get reduceMotion => _reduceMotion;
  bool get onboardingComplete => _onboardingComplete;

  Future<void> load() async {
    final raw = await _store.read();
    if (raw != null) {
      try {
        final value = jsonDecode(raw);
        if (value is Map<String, dynamic> && value['version'] == 1) {
          _themeMode = switch (value['theme']) {
            'light' => ThemeMode.light,
            'dark' => ThemeMode.dark,
            _ => ThemeMode.system,
          };
          _reduceMotion = value['reduceMotion'] == true;
          _onboardingComplete = value['onboardingComplete'] == true;
        }
      } on FormatException {
        // An invalid preference document is recoverable, not an auth failure.
      }
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) => _save(theme: mode);
  Future<void> setReduceMotion(bool enabled) => _save(motion: enabled);
  Future<void> completeOnboarding() => _save(onboarding: true);

  Future<void> _save({ThemeMode? theme, bool? motion, bool? onboarding}) {
    final operation = _writes.then((_) async {
      final nextTheme = theme ?? _themeMode;
      final nextMotion = motion ?? _reduceMotion;
      final nextOnboarding = onboarding ?? _onboardingComplete;
      await _store.write(
        jsonEncode({
          'version': 1,
          'theme': nextTheme.name,
          'reduceMotion': nextMotion,
          'onboardingComplete': nextOnboarding,
        }),
      );
      _themeMode = nextTheme;
      _reduceMotion = nextMotion;
      _onboardingComplete = nextOnboarding;
      notifyListeners();
    });
    // A failed save is surfaced to its caller without poisoning later saves.
    _writes = operation.catchError((Object _) {});
    return operation;
  }
}
