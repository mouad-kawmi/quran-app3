import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _fontScaleKey = 'app_font_scale';
  static const String _useQcfFontKey = 'app_use_qcf_font';
  static const String _useTajweedColorsKey = 'app_use_tajweed_colors';
  static const String _quranNormalFontSizeKey = 'app_quran_normal_font';
  static const double minFontScale = 0.9;
  static const double maxFontScale = 1.28;
  static const String _localeKey = 'app_locale';

  ThemeMode _themeMode = ThemeMode.light;
  double _fontScale = 1;
  bool _useQcfFont = true;
  bool _useTajweedColors = false;
  double _quranNormalFontSize = 24.0;
  Locale _locale = const Locale('ar');

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  bool get useQcfFont => _useQcfFont;
  bool get useTajweedColors => _useTajweedColors;
  double get quranNormalFontSize => _quranNormalFontSize;
  Locale get locale => _locale;

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
    _useQcfFont = prefs.getBool(_useQcfFontKey) ?? true;
    _useTajweedColors = prefs.getBool(_useTajweedColorsKey) ?? false;
    _quranNormalFontSize = prefs.getDouble(_quranNormalFontSizeKey) ?? 24.0;
    
    final localeStr = prefs.getString(_localeKey);
    if (localeStr != null) {
      _locale = Locale(localeStr);
    }
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> setLocale(Locale loc) async {
    if (_locale == loc) return;
    _locale = loc;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, loc.languageCode);
  }

  Future<void> setFontScale(double scale) async {
    final nextScale = scale.clamp(minFontScale, maxFontScale);
    if ((_fontScale - nextScale).abs() < 0.001) return;
    _fontScale = nextScale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, nextScale);
  }

  Future<void> setUseQcfFont(bool value) async {
    if (_useQcfFont == value) return;
    _useQcfFont = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useQcfFontKey, value);
  }

  Future<void> setUseTajweedColors(bool value) async {
    if (_useTajweedColors == value) return;
    _useTajweedColors = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useTajweedColorsKey, value);
  }

  Future<void> setQuranNormalFontSize(double size) async {
    final nextSize = size.clamp(16.0, 60.0);
    if ((_quranNormalFontSize - nextSize).abs() < 0.001) return;
    _quranNormalFontSize = nextSize;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_quranNormalFontSizeKey, nextSize);
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
