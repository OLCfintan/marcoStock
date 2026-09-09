import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart' as drift;

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/database/providers.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialized in main');
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(
    ref.watch(sharedPreferencesProvider),
    ref.watch(databaseProvider),
  );
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(settingsServiceProvider));
});

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref.watch(settingsServiceProvider));
});

class SettingsService {
  final SharedPreferences _prefs;
  final AppDatabase _db;
  SettingsService(this._prefs, this._db);

  ThemeMode getThemeMode() {
    final val = _prefs.getString('themeMode') ?? 'system';
    if (val == 'light') return ThemeMode.light;
    if (val == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString('themeMode', mode.name);
  }

  Locale getLocale() {
    final val = _prefs.getString('locale') ?? 'en';
    return Locale(val);
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString('locale', locale.languageCode);
  }

  Future<String?> getSetting(String key) async {
    final query = _db.select(_db.settings)..where((tbl) => tbl.key.equals(key));
    final result = await query.getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) async {
    await _db.into(_db.settings).insertOnConflictUpdate(
      SettingsCompanion.insert(key: key, value: drift.Value(value)),
    );
  }

  Future<Map<String, String>> getAllCompanySettings() async {
    final keys = ['companyName', 'companyAddress', 'companyTaxId', 'companyTaxRate', 'companyLogoPath'];
    final query = _db.select(_db.settings)..where((tbl) => tbl.key.isIn(keys));
    final results = await query.get();
    return { for (var e in results) e.key : e.value ?? '' };
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsService _service;
  ThemeModeNotifier(this._service) : super(_service.getThemeMode());

  void setMode(ThemeMode mode) {
    state = mode;
    _service.setThemeMode(mode);
  }
}

class LocaleNotifier extends StateNotifier<Locale> {
  final SettingsService _service;
  LocaleNotifier(this._service) : super(_service.getLocale());

  void setLocale(Locale locale) {
    state = locale;
    _service.setLocale(locale);
  }
}
