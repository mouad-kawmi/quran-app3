import 'dart:async';
import 'dart:ui';

import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quran_app/core/habous_prayer_times_service.dart';
import 'package:quran_app/core/prayer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void prayerNotificationCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    DartPluginRegistrant.ensureInitialized();
    return PrayerNotificationService.refreshStoredPrayerReminders();
  });
}

class AdhanSoundOption {
  const AdhanSoundOption({
    required this.id,
    required this.name,
    required this.description,
    required this.channelId,
    required this.channelName,
    this.rawResourceName,
    this.filePath,
  });

  final String id;
  final String name;
  final String description;
  final String channelId;
  final String channelName;
  final String? rawResourceName;
  final String? filePath;

  bool get isCustomFile => filePath != null;
}

class AdhanSettings {
  const AdhanSettings({required this.sound, required this.enabledPrayers});

  final AdhanSoundOption sound;
  final Set<Prayer> enabledPrayers;

  bool isEnabledFor(Prayer prayer) => enabledPrayers.contains(prayer);
}

class NotificationHealthStatus {
  const NotificationHealthStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsEnabled,
    required this.notificationPolicyAccessGranted,
    required this.batteryOptimizationsIgnored,
    required this.hasStoredLocation,
    required this.pendingNotificationCount,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;
  final bool notificationPolicyAccessGranted;
  final bool batteryOptimizationsIgnored;
  final bool hasStoredLocation;
  final int pendingNotificationCount;
}

class PrayerNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _nativeAdhanChannel = MethodChannel(
    'quran_app/native_adhan',
  );

  static const Duration reminderOffset = Duration(minutes: 5);
  static const int _daysToSchedule = 14;
  static const String _refreshTaskUniqueName = 'prayer_reminder_refresh';
  static const String _refreshTaskName = 'refresh_prayer_reminders';
  static const String _channelId = 'prayer_reminders';
  static const String _channelName = 'تنبيهات الصلاة';
  static const String _channelDescription =
      'تنبيهات تظهر قبل وقت الصلاة بخمس دقائق.';
  static const String _adhanChannelDescription =
      'تنبيهات وقت الصلاة مع صوت الأذان المختار.';
  static const String _notificationIconName = 'ic_notification_icon';
  static const String _notificationLargeIconName = 'ic_app_icon';
  static const Color _notificationColor = Color(0xFF004D40);
  static const Duration _adhanElapsedVisibility = Duration(minutes: 30);
  static const String _latitudeKey = 'prayer_reminder_latitude';
  static const String _longitudeKey = 'prayer_reminder_longitude';
  static const String _lastScheduledDayKey = 'prayer_reminder_scheduled_day';
  static const String _lastScheduledLatitudeKey =
      'prayer_reminder_scheduled_latitude';
  static const String _lastScheduledLongitudeKey =
      'prayer_reminder_scheduled_longitude';
  static const String _lastScheduleOfficialKey =
      'prayer_reminder_scheduled_official';
  static const String _adhanSoundKey = 'adhan_sound_id';
  static const String _adhanEnabledPrefix = 'adhan_enabled_';
  static const String _initialAdhanSetupPromptShownKey =
      'initial_adhan_setup_prompt_shown';
  static const String _customAdhanSoundId = 'custom_file';
  static const String _customAdhanSoundNameKey = 'custom_adhan_sound_name';
  static const String _customAdhanSoundPathKey = 'custom_adhan_sound_path';
  static const String _customAdhanChannelId = 'adhan_alerts_custom_file_v1';
  static const List<String> _legacyAdhanChannelIds = [
    'adhan_alerts_makkah_v1',
    'adhan_alerts_madinah_v1',
    'adhan_alerts_abdul_basit_v1',
    'adhan_alerts_minshawi_v1',
    'adhan_alerts_mishary_v1',
    'adhan_alerts_nasser_v1',
    'adhan_alerts_yusuf_islam_v1',
    'adhan_alerts_beautiful_v1',
    'adhan_alerts_system_v1',
    'adhan_alerts_makkah_v2',
    'adhan_alerts_madinah_v2',
    'adhan_alerts_abdul_basit_v2',
    'adhan_alerts_minshawi_v2',
    'adhan_alerts_mishary_v2',
    'adhan_alerts_nasser_v2',
    'adhan_alerts_yusuf_islam_v2',
    'adhan_alerts_beautiful_v2',
    'adhan_alerts_system_v2',
    'adhan_alerts_makkah_v3',
    'adhan_alerts_madinah_v3',
    'adhan_alerts_abdul_basit_v3',
    'adhan_alerts_minshawi_v3',
    'adhan_alerts_mishary_v3',
    'adhan_alerts_nasser_v3',
    'adhan_alerts_yusuf_islam_v3',
    'adhan_alerts_beautiful_v3',
  ];
  static const AdhanSoundOption _defaultAdhanSound = AdhanSoundOption(
    id: 'makkah',
    name: 'أذان مكة',
    description: 'من ملف Adhan-Makkah',
    channelId: 'adhan_alerts_makkah_v4',
    channelName: 'أذان مكة',
    rawResourceName: 'adhan_makkah',
  );
  static const List<AdhanSoundOption> availableAdhanSounds = [
    _defaultAdhanSound,
    AdhanSoundOption(
      id: 'madinah',
      name: 'أذان المدينة',
      description: 'من ملف Adhan-Madinah',
      channelId: 'adhan_alerts_madinah_v4',
      channelName: 'أذان المدينة',
      rawResourceName: 'adhan_madinah',
    ),
    AdhanSoundOption(
      id: 'abdul_basit',
      name: 'عبد الباسط',
      description: 'أذان بصوت عبد الباسط',
      channelId: 'adhan_alerts_abdul_basit_v4',
      channelName: 'أذان عبد الباسط',
      rawResourceName: 'adhan_abdul_basit',
    ),
    AdhanSoundOption(
      id: 'minshawi',
      name: 'المنشاوي',
      description: 'أذان بصوت المنشاوي',
      channelId: 'adhan_alerts_minshawi_v4',
      channelName: 'أذان المنشاوي',
      rawResourceName: 'adhan_minshawi',
    ),
    AdhanSoundOption(
      id: 'mishary',
      name: 'مشاري راشد العفاسي',
      description: 'أذان بصوت مشاري راشد العفاسي',
      channelId: 'adhan_alerts_mishary_v4',
      channelName: 'أذان مشاري راشد العفاسي',
      rawResourceName: 'adhan_mishary_rashid_alafasy',
    ),
    AdhanSoundOption(
      id: 'nasser',
      name: 'ناصر القطامي',
      description: 'أذان بصوت ناصر القطامي',
      channelId: 'adhan_alerts_nasser_v4',
      channelName: 'أذان ناصر القطامي',
      rawResourceName: 'adhan_nasser_al_qatami',
    ),
    AdhanSoundOption(
      id: 'yusuf_islam',
      name: 'يوسف إسلام',
      description: 'من ملف Yusuf-Islam',
      channelId: 'adhan_alerts_yusuf_islam_v4',
      channelName: 'أذان يوسف إسلام',
      rawResourceName: 'adhan_yusuf_islam',
    ),
    AdhanSoundOption(
      id: 'beautiful',
      name: 'أذان جميل',
      description: 'من ملف Beautiful-adhan',
      channelId: 'adhan_alerts_beautiful_v4',
      channelName: 'أذان جميل',
      rawResourceName: 'adhan_beautiful',
    ),
  ];
  static const List<Prayer> _notificationPrayers = [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  static bool _notificationsInitialized = false;
  static bool _backgroundRefreshInitialized = false;
  static Future<void>? _notificationsInitialization;
  static Future<void>? _backgroundRefreshInitialization;
  static bool _legacyChannelsDeleted = false;
  static bool _startupRefreshQueued = false;
  static bool _adhanRefreshInProgress = false;
  static Set<Prayer>? _queuedAdhanRefreshPrayers;

  static Future<void> initialize({
    bool requestPermissions = false,
    bool refreshReminders = false,
  }) async {
    if (kIsWeb) {
      return;
    }

    await _initializeNotifications(requestPermissions: requestPermissions);
    await _initializeBackgroundRefresh();
    if (refreshReminders && !_startupRefreshQueued) {
      _startupRefreshQueued = true;
      unawaited(refreshStoredPrayerReminders());
    }
  }

  static Future<void> schedulePrayerReminders(
    Coordinates coordinates, {
    DateTime? from,
    bool force = false,
  }) async {
    if (kIsWeb) {
      return;
    }

    await initialize();
    await _saveCoordinates(coordinates);
    if (!force && await _hasFreshSchedule(coordinates, from ?? DateTime.now())) {
      return;
    }

    final scheduleDate = from ?? DateTime.now();
    final scheduledWithOfficialTimes = await _schedulePrayerReminders(
      coordinates,
      from: from,
    );
    await _saveScheduleMetadata(
      coordinates,
      scheduleDate,
      isOfficial: scheduledWithOfficialTimes,
    );
  }

  static Future<AdhanSettings> loadAdhanSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final soundId = prefs.getString(_adhanSoundKey);
    final customSound = await loadCustomAdhanSound();
    final sound = soundId == _customAdhanSoundId && customSound != null
        ? customSound
        : adhanSoundById(soundId);
    final enabledPrayers = <Prayer>{};

    for (final prayer in _notificationPrayers) {
      final enabled = prefs.getBool(_adhanEnabledKey(prayer)) ?? true;
      if (enabled) {
        enabledPrayers.add(prayer);
      }
    }

    return AdhanSettings(sound: sound, enabledPrayers: enabledPrayers);
  }

  static Future<void> saveAdhanSound(String soundId) async {
    final prefs = await SharedPreferences.getInstance();
    if (soundId == _customAdhanSoundId) {
      final customSound = await loadCustomAdhanSound();
      await prefs.setString(
        _adhanSoundKey,
        customSound == null ? _defaultAdhanSound.id : customSound.id,
      );
    } else {
      await prefs.setString(_adhanSoundKey, adhanSoundById(soundId).id);
    }
    _queueAdhanRefresh();
  }

  static Future<List<AdhanSoundOption>> loadAvailableAdhanSounds() async {
    final customSound = await loadCustomAdhanSound();
    final customSounds = customSound == null ? null : [customSound];
    return [
      ...availableAdhanSounds,
      ...?customSounds,
    ];
  }

  static Future<AdhanSoundOption?> loadCustomAdhanSound() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_customAdhanSoundPathKey);
    if (path == null || path.isEmpty) {
      return null;
    }

    final name =
        prefs.getString(_customAdhanSoundNameKey) ?? 'أذان من الهاتف';
    return AdhanSoundOption(
      id: _customAdhanSoundId,
      name: name,
      description: 'ملف صوتي من الهاتف',
      channelId: _customAdhanChannelId,
      channelName: 'أذان مخصص',
      filePath: path,
    );
  }

  static Future<AdhanSoundOption?> pickCustomAdhanSound() async {
    if (!_isAndroid) {
      return null;
    }

    final selected = await _nativeAdhanChannel
        .invokeMapMethod<String, Object?>('pickAdhanAudio');
    if (selected == null) {
      return null;
    }

    final path = selected['path'] as String?;
    if (path == null || path.isEmpty) {
      return null;
    }

    final name = selected['name'] as String? ?? 'أذان من الهاتف';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_customAdhanSoundNameKey, name);
    await prefs.setString(_customAdhanSoundPathKey, path);
    await prefs.setString(_adhanSoundKey, _customAdhanSoundId);

    _queueAdhanRefresh();
    return loadCustomAdhanSound();
  }

  static Future<void> setPrayerAdhanEnabled(Prayer prayer, bool enabled) async {
    if (!_notificationPrayers.contains(prayer)) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adhanEnabledKey(prayer), enabled);
    _queueAdhanRefresh(prayers: {prayer});
  }

  static Future<NotificationHealthStatus> loadNotificationHealth() async {
    if (kIsWeb) {
      return const NotificationHealthStatus(
        notificationsEnabled: false,
        exactAlarmsEnabled: false,
        notificationPolicyAccessGranted: false,
        batteryOptimizationsIgnored: false,
        hasStoredLocation: false,
        pendingNotificationCount: 0,
      );
    }

    await _initializeNotifications(requestPermissions: false);
    final pending = await _notifications.pendingNotificationRequests();
    final hasStoredLocation = await _loadCoordinates() != null;

    if (!_isAndroid) {
      return NotificationHealthStatus(
        notificationsEnabled: true,
        exactAlarmsEnabled: true,
        notificationPolicyAccessGranted: true,
        batteryOptimizationsIgnored: true,
        hasStoredLocation: hasStoredLocation,
        pendingNotificationCount: pending.length,
      );
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final notificationsEnabled =
        await android?.areNotificationsEnabled() ?? false;
    final exactAlarmsEnabled =
        await android?.canScheduleExactNotifications() ?? false;
    final notificationPolicyAccessGranted =
        await android?.hasNotificationPolicyAccess() ?? false;
    final batteryOptimizationsIgnored =
        await Permission.ignoreBatteryOptimizations.isGranted;

    return NotificationHealthStatus(
      notificationsEnabled: notificationsEnabled,
      exactAlarmsEnabled: exactAlarmsEnabled,
      notificationPolicyAccessGranted: notificationPolicyAccessGranted,
      batteryOptimizationsIgnored: batteryOptimizationsIgnored,
      hasStoredLocation: hasStoredLocation,
      pendingNotificationCount: pending.length,
    );
  }

  static bool isAdhanSetupReady(NotificationHealthStatus health) {
    return health.notificationsEnabled &&
        health.exactAlarmsEnabled &&
        health.batteryOptimizationsIgnored &&
        health.hasStoredLocation &&
        health.pendingNotificationCount > 0;
  }

  static bool needsAdhanSetup(NotificationHealthStatus health) {
    return !isAdhanSetupReady(health);
  }

  static Future<bool> shouldShowInitialAdhanSetupPrompt(
    NotificationHealthStatus health,
  ) async {
    if (!needsAdhanSetup(health)) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_initialAdhanSetupPromptShownKey) ?? false);
  }

  static Future<void> markInitialAdhanSetupPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_initialAdhanSetupPromptShownKey, true);
  }

  static Future<bool?> requestNotificationsPermission() async {
    await _initializeNotifications(requestPermissions: false);

    if (_isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      if (granted == true) {
        unawaited(refreshStoredPrayerReminders(force: true));
      }
      return granted;
    }

    if (_isIOS) {
      return _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    if (_isMacOS) {
      return _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    return null;
  }

  static Future<bool?> requestExactAlarmPermission() async {
    await _initializeNotifications(requestPermissions: false);

    if (!_isAndroid) {
      return true;
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestExactAlarmsPermission();
    if (granted == true) {
      unawaited(refreshStoredPrayerReminders(force: true));
    }
    return granted;
  }

  static Future<bool?> requestNotificationPolicyAccess() async {
    await _initializeNotifications(requestPermissions: false);

    if (!_isAndroid) {
      return true;
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationPolicyAccess();
    unawaited(refreshStoredPrayerReminders(force: true));
    return granted;
  }

  static Future<bool> requestBatteryOptimizationBypass() async {
    if (!_isAndroid) {
      return true;
    }

    final status = await Permission.ignoreBatteryOptimizations.request();
    final granted = status.isGranted;
    if (granted) {
      unawaited(refreshStoredPrayerReminders(force: true));
    }
    return granted;
  }

  static AdhanSoundOption adhanSoundById(String? soundId) {
    return availableAdhanSounds.firstWhere(
      (sound) => sound.id == soundId,
      orElse: () => _defaultAdhanSound,
    );
  }

  static Future<bool> refreshStoredPrayerReminders({bool force = false}) async {
    if (kIsWeb) {
      return true;
    }

    final coordinates = await _loadCoordinates();
    if (coordinates == null) {
      return true;
    }

    await _initializeNotifications(requestPermissions: false);
    if (!force && await _hasFreshSchedule(coordinates, DateTime.now())) {
      return true;
    }

    final now = DateTime.now();
    final scheduledWithOfficialTimes = await _schedulePrayerReminders(
      coordinates,
      from: now,
    );
    await _saveScheduleMetadata(
      coordinates,
      now,
      isOfficial: scheduledWithOfficialTimes,
    );
    return true;
  }

  static Future<bool> _schedulePrayerReminders(
    Coordinates coordinates, {
    DateTime? from,
  }) async {
    final now = from ?? DateTime.now();
    final androidScheduleMode = await _androidScheduleMode();
    final adhanSettings = await loadAdhanSettings();
    final location = _locationFromCoordinates(coordinates);
    final reminderDetails = _reminderNotificationDetails();

    await _cancelExistingPrayerReminders(now);
    await _cancelExistingAdhanAlerts(now);

    var scheduleUsedOfficialTimes = true;
    for (var dayOffset = 0; dayOffset < _daysToSchedule; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final display = await HabousPrayerTimesService.getTodayPrayerTimes(
        location,
        date: date,
      );
      if (!display.isOfficial) {
        scheduleUsedOfficialTimes = false;
      }
      final moments = HabousPrayerTimesService.momentsFromDisplay(display);

      for (final moment in moments) {
        final reminderTime = moment.time.subtract(reminderOffset);
        if (!reminderTime.isAfter(now)) {
          continue;
        }

        await _notifications.zonedSchedule(
          id: _notificationId(reminderTime, moment.prayer),
          title: 'تبقت 5 دقائق على الصلاة',
          body:
              'تبقت 5 دقائق على صلاة ${PrayerService.getPrayerName(moment.prayer)}',
          scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
          notificationDetails: reminderDetails,
          androidScheduleMode: androidScheduleMode,
          payload: moment.prayer.name,
        );

        if (adhanSettings.isEnabledFor(moment.prayer)) {
          final adhanId = _adhanNotificationId(moment.time, moment.prayer);
          final prayerName = PrayerService.getPrayerName(moment.prayer);
          final adhanDetails = await _adhanNotificationDetails(
            adhanSettings.sound,
            prayerTime: moment.time,
          );
          await _notifications.zonedSchedule(
            id: adhanId,
            title: 'حان وقت الصلاة',
            body: 'حان وقت صلاة $prayerName',
            scheduledDate: tz.TZDateTime.from(moment.time, tz.local),
            notificationDetails: adhanDetails,
            androidScheduleMode: androidScheduleMode,
            payload: 'adhan:${moment.prayer.name}',
          );
          await _scheduleNativeAdhan(
            id: adhanId,
            time: moment.time,
            prayerName: prayerName,
            sound: adhanSettings.sound,
          );
        }
      }
    }

    return scheduleUsedOfficialTimes;
  }

  static void _queueAdhanRefresh({Set<Prayer>? prayers}) {
    _queuedAdhanRefreshPrayers = _mergePrayerSets(
      _queuedAdhanRefreshPrayers,
      prayers,
    );
    unawaited(_runQueuedAdhanRefresh());
  }

  static Future<void> _runQueuedAdhanRefresh() async {
    if (_adhanRefreshInProgress) {
      return;
    }

    _adhanRefreshInProgress = true;
    try {
      while (_queuedAdhanRefreshPrayers != null) {
        final prayers = _queuedAdhanRefreshPrayers;
        _queuedAdhanRefreshPrayers = null;
        await _rescheduleStoredAdhanAlerts(prayers: prayers);
      }
    } finally {
      _adhanRefreshInProgress = false;
    }
  }

  static Set<Prayer>? _mergePrayerSets(
    Set<Prayer>? current,
    Set<Prayer>? next,
  ) {
    if (current == null || next == null) {
      return null;
    }
    return {...current, ...next};
  }

  static Future<void> _rescheduleStoredAdhanAlerts({
    Set<Prayer>? prayers,
  }) async {
    final coordinates = await _loadCoordinates();
    if (coordinates == null) {
      return;
    }

    await _initializeNotifications(requestPermissions: false);

    final now = DateTime.now();
    final androidScheduleMode = await _androidScheduleMode();
    final adhanSettings = await loadAdhanSettings();
    final location = _locationFromCoordinates(coordinates);

    await _cancelExistingAdhanAlerts(now, prayers: prayers);

    for (var dayOffset = 0; dayOffset < _daysToSchedule; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final moments = await HabousPrayerTimesService.getPrayerMoments(
        location,
        date,
      );

      for (final moment in moments) {
        if (prayers != null && !prayers.contains(moment.prayer)) {
          continue;
        }

        if (!moment.time.isAfter(now) ||
            !adhanSettings.isEnabledFor(moment.prayer)) {
          continue;
        }

        final adhanId = _adhanNotificationId(moment.time, moment.prayer);
        final prayerName = PrayerService.getPrayerName(moment.prayer);
        final adhanDetails = await _adhanNotificationDetails(
          adhanSettings.sound,
          prayerTime: moment.time,
        );
        await _notifications.zonedSchedule(
          id: adhanId,
          title: 'حان وقت الصلاة',
          body: 'حان وقت صلاة $prayerName',
          scheduledDate: tz.TZDateTime.from(moment.time, tz.local),
          notificationDetails: adhanDetails,
          androidScheduleMode: androidScheduleMode,
          payload: 'adhan:${moment.prayer.name}',
        );
        await _scheduleNativeAdhan(
          id: adhanId,
          time: moment.time,
          prayerName: prayerName,
          sound: adhanSettings.sound,
        );
      }
    }
  }

  static Future<void> _initializeNotifications({
    required bool requestPermissions,
  }) async {
    if (!_notificationsInitialized) {
      _notificationsInitialization ??= _initializeNotificationsCore();
      try {
        await _notificationsInitialization;
      } catch (_) {
        _notificationsInitialization = null;
        rethrow;
      }
    }

    if (requestPermissions) {
      await _requestPermissions();
    }
  }

  static Future<void> _initializeNotificationsCore() async {
    await _configureLocalTimeZone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification_icon'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(settings: initializationSettings);
    await _deleteLegacyAdhanChannels();
    _notificationsInitialized = true;
  }

  static Future<void> _initializeBackgroundRefresh() async {
    if (!_isAndroid) {
      return;
    }

    if (_backgroundRefreshInitialized) {
      return;
    }

    _backgroundRefreshInitialization ??= _initializeBackgroundRefreshCore();
    try {
      await _backgroundRefreshInitialization;
    } catch (_) {
      _backgroundRefreshInitialization = null;
      rethrow;
    }
  }

  static Future<void> _initializeBackgroundRefreshCore() async {
    await Workmanager().initialize(prayerNotificationCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      _refreshTaskUniqueName,
      _refreshTaskName,
      frequency: const Duration(hours: 12),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
    _backgroundRefreshInitialized = true;
  }

  static Future<void> _deleteLegacyAdhanChannels() async {
    if (_legacyChannelsDeleted || !_isAndroid) {
      return;
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    for (final channelId in _legacyAdhanChannelIds) {
      await android?.deleteNotificationChannel(channelId: channelId);
    }
    _legacyChannelsDeleted = true;
  }

  static Future<void> _configureLocalTimeZone() async {
    tz_data.initializeTimeZones();

    if (_isLinux || _isWindows) {
      return;
    }

    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
  }

  static Future<bool> _hasFreshSchedule(
    Coordinates coordinates,
    DateTime now,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final scheduledDay = prefs.getInt(_lastScheduledDayKey);
    final scheduledLatitude = prefs.getDouble(_lastScheduledLatitudeKey);
    final scheduledLongitude = prefs.getDouble(_lastScheduledLongitudeKey);
    final scheduledOfficial = prefs.getBool(_lastScheduleOfficialKey) ?? false;

    if (scheduledDay == null ||
        scheduledLatitude == null ||
        scheduledLongitude == null ||
        !scheduledOfficial) {
      return false;
    }

    return scheduledDay == _scheduleDayId(now) &&
        _coordinatesClose(
          coordinates,
          Coordinates(scheduledLatitude, scheduledLongitude),
        );
  }

  static Future<void> _saveScheduleMetadata(
    Coordinates coordinates,
    DateTime now, {
    required bool isOfficial,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastScheduledDayKey, _scheduleDayId(now));
    await prefs.setDouble(_lastScheduledLatitudeKey, coordinates.latitude);
    await prefs.setDouble(_lastScheduledLongitudeKey, coordinates.longitude);
    await prefs.setBool(_lastScheduleOfficialKey, isOfficial);
  }

  static int _scheduleDayId(DateTime date) {
    return date.year * 10000 + date.month * 100 + date.day;
  }

  static bool _coordinatesClose(Coordinates a, Coordinates b) {
    const tolerance = 0.03;
    return (a.latitude - b.latitude).abs() <= tolerance &&
        (a.longitude - b.longitude).abs() <= tolerance;
  }

  static Future<void> _saveCoordinates(Coordinates coordinates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latitudeKey, coordinates.latitude);
    await prefs.setDouble(_longitudeKey, coordinates.longitude);
  }

  static PrayerLocation _locationFromCoordinates(Coordinates coordinates) {
    return PrayerLocation(
      coordinates: coordinates,
      name: 'الموقع المحفوظ',
      accuracy: 0,
      isStored: true,
    );
  }

  static Future<Coordinates?> _loadCoordinates() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);
    if (latitude == null || longitude == null) {
      return null;
    }
    return Coordinates(latitude, longitude);
  }

  static Future<void> _cancelExistingPrayerReminders(DateTime now) async {
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));

    for (var dayOffset = 0; dayOffset <= _daysToSchedule + 1; dayOffset++) {
      final date = startDate.add(Duration(days: dayOffset));
      for (final prayer in _notificationPrayers) {
        await _notifications.cancel(id: _notificationId(date, prayer));
      }
    }
  }

  static Future<void> _cancelExistingAdhanAlerts(
    DateTime now, {
    Set<Prayer>? prayers,
  }) async {
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));

    for (var dayOffset = 0; dayOffset <= _daysToSchedule + 1; dayOffset++) {
      final date = startDate.add(Duration(days: dayOffset));
      for (final prayer in _notificationPrayers) {
        if (prayers != null && !prayers.contains(prayer)) {
          continue;
        }
        final adhanId = _adhanNotificationId(date, prayer);
        await _notifications.cancel(id: adhanId);
        await _cancelNativeAdhan(adhanId);
      }
    }
  }

  static Future<void> _requestPermissions() async {
    if (kIsWeb) {
      return;
    }

    if (_isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      return;
    }

    if (_isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return;
    }

    if (_isMacOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  static Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (kIsWeb || !_isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canScheduleExact = await android?.canScheduleExactNotifications();
    return canScheduleExact ?? false
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  static int _notificationId(DateTime reminderTime, Prayer prayer) {
    final datePart =
        reminderTime.year * 10000 + reminderTime.month * 100 + reminderTime.day;
    return datePart * 10 + prayer.index;
  }

  static int _adhanNotificationId(DateTime prayerTime, Prayer prayer) {
    final datePart =
        prayerTime.year * 10000 + prayerTime.month * 100 + prayerTime.day;
    return datePart * 100 + 50 + prayer.index;
  }

  static Future<void> _scheduleNativeAdhan({
    required int id,
    required DateTime time,
    required String prayerName,
    required AdhanSoundOption sound,
  }) async {
    if (!_isAndroid ||
        (sound.rawResourceName == null && sound.filePath == null)) {
      return;
    }

    try {
      await _nativeAdhanChannel.invokeMethod<bool>('schedule', {
        'id': id,
        'triggerAtMillis': time.millisecondsSinceEpoch,
        'prayerName': prayerName,
        'rawResourceName': sound.rawResourceName,
        'filePath': sound.filePath,
      });
    } catch (_) {
      // The visible notification still fires if native playback cannot schedule.
    }
  }

  static Future<void> _cancelNativeAdhan(int id) async {
    if (!_isAndroid) {
      return;
    }

    try {
      await _nativeAdhanChannel.invokeMethod<bool>('cancel', {'id': id});
    } catch (_) {
      // No-op: cancelling the Flutter notification remains the source of truth.
    }
  }

  static NotificationDetails _reminderNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: _notificationIconName,
        largeIcon: DrawableResourceAndroidBitmap(_notificationLargeIconName),
        color: _notificationColor,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
  }

  static Future<NotificationDetails> _adhanNotificationDetails(
    AdhanSoundOption sound, {
    required DateTime prayerTime,
  }) async {
    final bypassDnd = await _canBypassDnd();
    return NotificationDetails(
      android: _adhanAndroidDetails(
        sound,
        prayerTime: prayerTime,
        bypassDnd: bypassDnd,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
  }

  static Future<bool> _canBypassDnd() async {
    if (!_isAndroid) {
      return false;
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.hasNotificationPolicyAccess() ?? false;
  }

  static AndroidNotificationDetails _adhanAndroidDetails(
    AdhanSoundOption sound, {
    required DateTime prayerTime,
    required bool bypassDnd,
  }) {
    final channelId = bypassDnd
        ? '${sound.channelId}_bypass_silent'
        : sound.channelId;
    final channelName = bypassDnd
        ? '${sound.channelName} - يتجاوز الصامت'
        : sound.channelName;

    return AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: _adhanChannelDescription,
      icon: _notificationIconName,
      largeIcon: const DrawableResourceAndroidBitmap(_notificationLargeIconName),
      color: _notificationColor,
      importance: Importance.max,
      channelBypassDnd: bypassDnd,
      priority: Priority.max,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      showWhen: true,
      when: prayerTime.millisecondsSinceEpoch,
      usesChronometer: true,
      chronometerCountDown: false,
      timeoutAfter: _adhanElapsedVisibility.inMilliseconds,
      playSound: !sound.isCustomFile,
      sound: !sound.isCustomFile && sound.rawResourceName != null
          ? RawResourceAndroidNotificationSound(sound.rawResourceName!)
          : null,
    );
  }

  static String _adhanEnabledKey(Prayer prayer) {
    return '$_adhanEnabledPrefix${prayer.name}';
  }

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

  static bool get _isLinux => defaultTargetPlatform == TargetPlatform.linux;

  static bool get _isWindows => defaultTargetPlatform == TargetPlatform.windows;
}
