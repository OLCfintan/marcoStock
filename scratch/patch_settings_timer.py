import re

with open('lib/src/application/settings/settings_service.dart', 'r') as f:
    content = f.read()

# Add Notifier Provider
import_str = "final magnifierZoomProvider = StateNotifierProvider<MagnifierZoomNotifier, double>((ref) {"
new_import = """final sleepDelayProvider = StateNotifierProvider<SleepDelayNotifier, int>((ref) {
  return SleepDelayNotifier(ref.watch(settingsServiceProvider));
});

final magnifierZoomProvider = StateNotifierProvider<MagnifierZoomNotifier, double>((ref) {"""
content = content.replace(import_str, new_import)

# Add methods to SettingsService
old_svc = """  Future<void> setMagnifierZoom(double zoom) async {
    await _prefs.setDouble('magnifierZoom', zoom);
  }"""
new_svc = """  Future<void> setMagnifierZoom(double zoom) async {
    await _prefs.setDouble('magnifierZoom', zoom);
  }

  int getSleepDelay() {
    return _prefs.getInt('sleepDelay') ?? 5; // Default 5 minutes
  }

  Future<void> setSleepDelay(int minutes) async {
    await _prefs.setInt('sleepDelay', minutes);
  }"""
content = content.replace(old_svc, new_svc)

# Add Notifier Class
old_not = """class MagnifierZoomNotifier extends StateNotifier<double> {
  final SettingsService _service;
  MagnifierZoomNotifier(this._service) : super(_service.getMagnifierZoom());

  void setZoom(double zoom) {
    state = zoom;
    _service.setMagnifierZoom(zoom);
  }
}"""
new_not = """class MagnifierZoomNotifier extends StateNotifier<double> {
  final SettingsService _service;
  MagnifierZoomNotifier(this._service) : super(_service.getMagnifierZoom());

  void setZoom(double zoom) {
    state = zoom;
    _service.setMagnifierZoom(zoom);
  }
}

class SleepDelayNotifier extends StateNotifier<int> {
  final SettingsService _service;
  SleepDelayNotifier(this._service) : super(_service.getSleepDelay());

  void setDelay(int minutes) {
    state = minutes;
    _service.setSleepDelay(minutes);
  }
}"""
content = content.replace(old_not, new_not)

with open('lib/src/application/settings/settings_service.dart', 'w') as f:
    f.write(content)
print('SettingsService patched.')
