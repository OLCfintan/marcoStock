import re

with open('lib/src/application/settings/settings_service.dart', 'r') as f:
    content = f.read()

# Add Notifier Provider
import_str = "final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {"
new_import = """final magnifierZoomProvider = StateNotifierProvider<MagnifierZoomNotifier, double>((ref) {
  return MagnifierZoomNotifier(ref.watch(settingsServiceProvider));
});

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {"""
content = content.replace(import_str, new_import)

# Add methods to SettingsService
old_svc = """  Future<void> setLocale(Locale locale) async {
    await _prefs.setString('locale', locale.languageCode);
  }"""
new_svc = """  Future<void> setLocale(Locale locale) async {
    await _prefs.setString('locale', locale.languageCode);
  }

  double getMagnifierZoom() {
    return _prefs.getDouble('magnifierZoom') ?? 1.25;
  }

  Future<void> setMagnifierZoom(double zoom) async {
    await _prefs.setDouble('magnifierZoom', zoom);
  }"""
content = content.replace(old_svc, new_svc)

# Add Notifier Class
old_not = """class LocaleNotifier extends StateNotifier<Locale> {
  final SettingsService _service;
  LocaleNotifier(this._service) : super(_service.getLocale());

  void setLocale(Locale locale) {
    state = locale;
    _service.setLocale(locale);
  }
}"""
new_not = """class LocaleNotifier extends StateNotifier<Locale> {
  final SettingsService _service;
  LocaleNotifier(this._service) : super(_service.getLocale());

  void setLocale(Locale locale) {
    state = locale;
    _service.setLocale(locale);
  }
}

class MagnifierZoomNotifier extends StateNotifier<double> {
  final SettingsService _service;
  MagnifierZoomNotifier(this._service) : super(_service.getMagnifierZoom());

  void setZoom(double zoom) {
    state = zoom;
    _service.setMagnifierZoom(zoom);
  }
}"""
content = content.replace(old_not, new_not)

with open('lib/src/application/settings/settings_service.dart', 'w') as f:
    f.write(content)
print('SettingsService patched.')
