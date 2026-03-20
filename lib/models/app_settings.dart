import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const _keyAutoDock = 'auto_dock_enabled';
  static const _keyShowSeconds = 'show_seconds';
  static const _keyShow24h = 'show_24h';
  static const _keyShowDate = 'show_date';
  static const _keyScreenBrightness = 'screen_brightness';
  static const _keyLandscapeThreshold = 'landscape_threshold';

  // for widget
  static const _keyWidgetShow24h = 'widget_show_24h';
  static const _keyWidgetShowSeconds = 'widget_show_seconds';
  static const _keyWidgetShowDate = 'widget_show_date';
  static const _keyWidgetShowDay = 'widget_show_day';

  bool _autoDockEnabled = true;
  bool _showSeconds = true;
  bool _show24h = true;
  bool _showDate = true;
  double _screenBrightness = 0.5;
  double _landscapeThreshold = 1.3;

  bool _widgetShow24h = true;
  bool _widgetShowSeconds = true;
  bool _widgetShowDate = true;
  bool _widgetShowDay = true;

  bool get autoDockEnabled => _autoDockEnabled;
  bool get showSeconds => _showSeconds;
  bool get show24h => _show24h;
  bool get showDate => _showDate;
  double get screenBrightness => _screenBrightness;
  double get landscapeThreshold => _landscapeThreshold;

  bool get widgetShow24h => _widgetShow24h;
  bool get widgetShowSeconds => _widgetShowSeconds;
  bool get widgetShowDate => _widgetShowDate;
  bool get widgetShowDay => _widgetShowDay;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _autoDockEnabled = prefs.getBool(_keyAutoDock) ?? true;
    _showSeconds = prefs.getBool(_keyShowSeconds) ?? true;
    _show24h = prefs.getBool(_keyShow24h) ?? true;
    _showDate = prefs.getBool(_keyShowDate) ?? true;
    _screenBrightness = prefs.getDouble(_keyScreenBrightness) ?? 0.5;
    _landscapeThreshold = prefs.getDouble(_keyLandscapeThreshold) ?? 1.3;

    // for widget
    _widgetShow24h = prefs.getBool(_keyWidgetShow24h) ?? true;
    _widgetShowSeconds = prefs.getBool(_keyWidgetShowSeconds) ?? true;
    _widgetShowDate = prefs.getBool(_keyWidgetShowDate) ?? true;
    _widgetShowDay = prefs.getBool(_keyWidgetShowDay) ?? true;
    notifyListeners();
  }

  Future<void> setAutoDock(bool val) async {
    _autoDockEnabled = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoDock, val);
  }

  Future<void> setShowSeconds(bool val) async {
    _showSeconds = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowSeconds, val);
  }

  Future<void> setShow24h(bool val) async {
    _show24h = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShow24h, val);
  }

  Future<void> setShowDate(bool val) async {
    _showDate = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowDate, val);
  }

  Future<void> setScreenBrightness(double val) async {
    _screenBrightness = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyScreenBrightness, val);
  }

  Future<void> setLandscapeThreshold(double val) async {
    _landscapeThreshold = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLandscapeThreshold, val);
  }

  // for widget
  Future<void> setWidgetShow24h(bool v) async {
    _widgetShow24h = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyWidgetShow24h, v);
  }

  Future<void> setWidgetShowSeconds(bool v) async {
    _widgetShowSeconds = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyWidgetShowSeconds, v);
  }

  Future<void> setWidgetShowDate(bool v) async {
    _widgetShowDate = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyWidgetShowDate, v);
  }

  Future<void> setWidgetShowDay(bool v) async {
    _widgetShowDay = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyWidgetShowDay, v);
  }
}
