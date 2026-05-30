import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _fontScaleKey = 'app_font_scale';
  static const double minFontScale = 0.9;
  static const double maxFontScale = 1.28;

  ThemeMode _themeMode = ThemeMode.light;
  double _fontScale = 1;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;

  String get themeLabel {
    return switch (_themeMode) {
      ThemeMode.dark => 'الوضع الليلي',
      ThemeMode.system => 'حسب إعدادات الجهاز',
      ThemeMode.light => 'الوضع النهاري',
    };
  }

  String get fontScaleLabel {
    if (_fontScale < 0.98) return 'صغير';
    if (_fontScale > 1.14) return 'كبير';
    if (_fontScale > 1.04) return 'متوسط';
    return 'عادي';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _themeModeFromName(prefs.getString(_themeModeKey));
    _fontScale =
        (prefs.getDouble(_fontScaleKey) ?? 1).clamp(minFontScale, maxFontScale);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setFontScale(double scale) async {
    final nextScale = scale.clamp(minFontScale, maxFontScale);
    if ((_fontScale - nextScale).abs() < 0.001) return;
    _fontScale = nextScale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, nextScale);
  }

  static ThemeMode _themeModeFromName(String? value) {
    return switch (value) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettingsController watch(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
