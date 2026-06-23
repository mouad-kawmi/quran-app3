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
    try {
      DartPluginRegistrant.ensureInitialized();
      final result = await PrayerNotificationService.refreshStoredPrayerReminders(force: true);
      return Future.value(result);
    } catch (_) {
      return Future.value(false);
    }
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
  const AdhanSettings({
    required this.sound,
    required this.enabledPrayers,
    required this.volume,
  });

  final AdhanSoundOption sound;
  final Set<Prayer> enabledPrayers;
  final double volume;

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
  static const String _notificationIconName = 'ic_notif_prayer';
  static const String _notificationLargeIconName = 'nor_quran_2';
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
  static const String _lastScheduleAdhanSoundKey =
      'prayer_reminder_scheduled_adhan_sound';
  static const String _lastScheduleAdhanVolumeKey =
      'prayer_reminder_scheduled_adhan_volume';
  static const String _adhanSoundKey = 'adhan_sound_id';
  static const String _adhanVolumeKey = 'adhan_volume';
  static const String _adhanEnabledPrefix = 'adhan_enabled_';
  static const String _initialAdhanSetupPromptShownKey =
      'initial_adhan_setup_prompt_shown';
  static const String _customAdhanSoundId = 'custom_file';
  static const String _customAdhanSoundNameKey = 'custom_adhan_sound_name';
  static const String _customAdhanSoundPathKey = 'custom_adhan_sound_path';
  static const String _customAdhanChannelId = 'adhan_alerts_custom_file_v1';
  static const String _nativeAdhanNotificationChannelId =
      'adhan_alerts_native_silent_v1';
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
    'adhan_alerts_makkah_v4',
    'adhan_alerts_madinah_v4',
    'adhan_alerts_abdul_basit_v4',
    'adhan_alerts_minshawi_v4',
    'adhan_alerts_mishary_v4',
    'adhan_alerts_nasser_v4',
    'adhan_alerts_yusuf_islam_v4',
    'adhan_alerts_beautiful_v4',
    'adhan_alerts_custom_file_v1',
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
  static const double defaultAdhanVolume = 0.40;

  static bool _notificationsInitialized = false;
  static bool _backgroundRefreshInitialized = false;
  static Future<void>? _notificationsInitialization;
  static Future<void>? _backgroundRefreshInitialization;
  static bool _legacyChannelsDeleted = false;
  static bool _startupRefreshQueued = false;
  static bool _adhanRefreshInProgress = false;
  static bool _hasQueuedAdhanRefresh = false;
  static Future<void>? _adhanRefreshTask;
  static Set<Prayer>? _queuedAdhanRefreshPrayers;

  /// Stream of payloads from clicked notifications
  static final StreamController<String> _onNotificationClick =
      StreamController<String>.broadcast();
  static Stream<String> get onNotificationClick => _onNotificationClick.stream;

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
      unawaited(refreshStoredPrayerReminders(force: true));
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
    final volume = _sanitizeAdhanVolume(
      prefs.getDouble(_adhanVolumeKey) ?? defaultAdhanVolume,
    );
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

    return AdhanSettings(
      sound: sound,
      enabledPrayers: enabledPrayers,
      volume: volume,
    );
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
    await _rescheduleStoredAdhanAlerts();
  }

  static Future<void> saveAdhanVolume(double volume) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_adhanVolumeKey, _sanitizeAdhanVolume(volume));
    await _rescheduleStoredAdhanAlerts();
  }

  static void setAdhanPreviewCompletedHandler(VoidCallback? handler) {
    if (handler == null) {
      _nativeAdhanChannel.setMethodCallHandler(null);
      return;
    }

    _nativeAdhanChannel.setMethodCallHandler((call) async {
      if (call.method == 'adhanPreviewCompleted') {
        handler();
      }
    });
  }

  static Future<void> previewAdhanSound(
    AdhanSoundOption sound, {
    required double volume,
  }) async {
    if (!_isAndroid ||
        (sound.rawResourceName == null && sound.filePath == null)) {
      return;
    }

    await _nativeAdhanChannel.invokeMethod<bool>('preview', {
      'rawResourceName': sound.rawResourceName,
      'filePath': sound.filePath,
      'volume': _sanitizeAdhanVolume(volume),
    });
  }

  static Future<void> stopAdhanPreview() async {
    if (!_isAndroid) {
      return;
    }

    await _nativeAdhanChannel.invokeMethod<bool>('stopPreview');
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

    await _rescheduleStoredAdhanAlerts();
    return loadCustomAdhanSound();
  }

  static Future<void> setPrayerAdhanEnabled(Prayer prayer, bool enabled) async {
    if (!_notificationPrayers.contains(prayer)) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adhanEnabledKey(prayer), enabled);
    await _queueAdhanRefresh(prayers: {prayer});
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
    final nativePending = await _nativePendingScheduledCount();
    final pendingNotificationCount = pending.length + nativePending;
    final hasStoredLocation = await _loadCoordinates() != null;

    if (!_isAndroid) {
      return NotificationHealthStatus(
        notificationsEnabled: true,
        exactAlarmsEnabled: true,
        notificationPolicyAccessGranted: true,
        batteryOptimizationsIgnored: true,
        hasStoredLocation: hasStoredLocation,
        pendingNotificationCount: pendingNotificationCount,
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
      pendingNotificationCount: pendingNotificationCount,
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

    await _prefetchOfficialTimesIfPossible(location);

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
        // ─── الحالة 1 و 2 و 3: notification 5 دقائق ───
        // تُجدول فقط إذا وقتها لم يمُر بعد
        final reminderTime = moment.time.subtract(reminderOffset);
        if (reminderTime.isAfter(now)) {
          final reminderId = _notificationId(reminderTime, moment.prayer);
          final reminderTitle = 'تبقت 5 دقائق على الصلاة';
          final reminderBody =
              'تبقت 5 دقائق على صلاة ${PrayerService.getPrayerName(moment.prayer)}';
          final scheduledNatively = await _scheduleNativeNotification(
            id: reminderId,
            time: reminderTime,
            title: reminderTitle,
            body: reminderBody,
            timeoutAfter: reminderOffset,
          );

          if (!scheduledNatively) {
            await _notifications.zonedSchedule(
              id: reminderId,
              title: reminderTitle,
              body: reminderBody,
              scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
              notificationDetails: reminderDetails,
              androidScheduleMode: androidScheduleMode,
              payload: moment.prayer.name,
            );
          }
        }

        // تخطى الصلاة إذا وقتها مر (لا داعي لجدولة notification الصلاة)
        if (!moment.time.isAfter(now)) {
          continue;
        }

        // ─── الحالة 1: أذان مفعّل → notification صلاة + أذان ───
        // ─── الحالة 2: أذان مُعطَّل → notification صلاة فقط (بلا أذان) ───
        // ─── الحالة 3: مُعطَّل ثم مُفعَّل → نفس الحالة 1 ───
        final isAdhanEnabled = adhanSettings.isEnabledFor(moment.prayer);
        final adhanId = _adhanNotificationId(moment.time, moment.prayer);
        final prayerName = PrayerService.getPrayerName(moment.prayer);
        final prayerTitle = 'حان وقت الصلاة';
        final prayerBody = 'حان وقت صلاة $prayerName';

        final details = isAdhanEnabled
            ? await _adhanNotificationDetails(prayerTime: moment.time)
            : _prayerTimeNotificationDetails(moment.time);

        // الأذان native فقط إذا مفعّل
        var visibleAlertScheduledNatively = false;
        if (isAdhanEnabled) {
          visibleAlertScheduledNatively = await _scheduleNativeAdhan(
            id: adhanId,
            time: moment.time,
            prayerName: prayerName,
            sound: adhanSettings.sound,
            volume: adhanSettings.volume,
          );
        } else {
          visibleAlertScheduledNatively = await _scheduleNativeNotification(
            id: adhanId,
            time: moment.time,
            title: prayerTitle,
            body: prayerBody,
            timeoutAfter: _adhanElapsedVisibility,
          );
          await _cancelNativeAdhan(adhanId);
        }

        // notification وقت الصلاة دائماً (سواء الأذان مفعّل أو لا)
        if (!visibleAlertScheduledNatively) {
          await _notifications.zonedSchedule(
            id: adhanId,
            title: prayerTitle,
            body: prayerBody,
            scheduledDate: tz.TZDateTime.from(moment.time, tz.local),
            notificationDetails: details,
            androidScheduleMode: androidScheduleMode,
            payload: 'adhan:${moment.prayer.name}',
          );
        }
      }
    }

    return scheduleUsedOfficialTimes;
  }

  static Future<void> _queueAdhanRefresh({Set<Prayer>? prayers}) {
    if (!_hasQueuedAdhanRefresh ||
        _queuedAdhanRefreshPrayers == null ||
        prayers == null) {
      _queuedAdhanRefreshPrayers = prayers;
    } else {
      _queuedAdhanRefreshPrayers = {
        ..._queuedAdhanRefreshPrayers!,
        ...prayers,
      };
    }
    _hasQueuedAdhanRefresh = true;
    _adhanRefreshTask ??= _runQueuedAdhanRefresh();
    return _adhanRefreshTask!;
  }

  static Future<void> _runQueuedAdhanRefresh() async {
    if (_adhanRefreshInProgress) {
      return;
    }

    _adhanRefreshInProgress = true;
    try {
      while (_hasQueuedAdhanRefresh) {
        final prayers = _queuedAdhanRefreshPrayers;
        _queuedAdhanRefreshPrayers = null;
        _hasQueuedAdhanRefresh = false;
        await _rescheduleStoredAdhanAlerts(prayers: prayers);
      }
    } finally {
      _adhanRefreshInProgress = false;
      _adhanRefreshTask = null;
    }
  }

  static Future<void> _prefetchOfficialTimesIfPossible(
    PrayerLocation location,
  ) async {
    if (!PrayerService.isInMorocco(location.coordinates)) {
      return;
    }

    try {
      await HabousPrayerTimesService.prefetchOfficialTimes(location);
    } catch (_) {
      // Scheduling remains available through existing cache or local fallback.
    }
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

    await _prefetchOfficialTimesIfPossible(location);

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

        if (!moment.time.isAfter(now)) {
          continue;
        }

        final isAdhanEnabled = adhanSettings.isEnabledFor(moment.prayer);
        final adhanId = _adhanNotificationId(moment.time, moment.prayer);
        final prayerName = PrayerService.getPrayerName(moment.prayer);
        final prayerTitle = 'حان وقت الصلاة';
        final prayerBody = 'حان وقت صلاة $prayerName';

        final details = isAdhanEnabled
            ? await _adhanNotificationDetails(prayerTime: moment.time)
            : _prayerTimeNotificationDetails(moment.time);

        var visibleAlertScheduledNatively = false;
        if (isAdhanEnabled) {
          visibleAlertScheduledNatively = await _scheduleNativeAdhan(
            id: adhanId,
            time: moment.time,
            prayerName: prayerName,
            sound: adhanSettings.sound,
            volume: adhanSettings.volume,
          );
        } else {
          visibleAlertScheduledNatively = await _scheduleNativeNotification(
            id: adhanId,
            time: moment.time,
            title: prayerTitle,
            body: prayerBody,
            timeoutAfter: _adhanElapsedVisibility,
          );
          await _cancelNativeAdhan(adhanId);
        }

        if (!visibleAlertScheduledNatively) {
          await _notifications.zonedSchedule(
            id: adhanId,
            title: prayerTitle,
            body: prayerBody,
            scheduledDate: tz.TZDateTime.from(moment.time, tz.local),
            notificationDetails: details,
            androidScheduleMode: androidScheduleMode,
            payload: 'adhan:${moment.prayer.name}',
          );
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastScheduleAdhanSoundKey, adhanSettings.sound.id);
    await prefs.setDouble(_lastScheduleAdhanVolumeKey, adhanSettings.volume);
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
      android: AndroidInitializationSettings('@drawable/ic_notif_prayer'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _notifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          _onNotificationClick.add(response.payload!);
        }
      },
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );
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

    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // Fallback to UTC if timezone detection fails
      tz.setLocalLocation(tz.UTC);
    }
  }

  static Future<bool> _hasFreshSchedule(
    Coordinates coordinates,
    DateTime now,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final scheduledDay = prefs.getInt(_lastScheduledDayKey);
    final scheduledLatitude = prefs.getDouble(_lastScheduledLatitudeKey);
    final scheduledLongitude = prefs.getDouble(_lastScheduledLongitudeKey);
    final lastScheduleWasOfficial = prefs.getBool(_lastScheduleOfficialKey);
    final scheduledAdhanSound = prefs.getString(_lastScheduleAdhanSoundKey);
    final scheduledAdhanVolume = prefs.getDouble(_lastScheduleAdhanVolumeKey);
    final currentAdhanSettings = await loadAdhanSettings();
    final currentAdhanSound = currentAdhanSettings.sound.id;
    final currentAdhanVolume = currentAdhanSettings.volume;

    if (scheduledDay == null ||
        scheduledLatitude == null ||
        scheduledLongitude == null ||
        scheduledAdhanSound != currentAdhanSound ||
        scheduledAdhanVolume != currentAdhanVolume) {
      return false;
    }

    if (PrayerService.isInMorocco(coordinates) && lastScheduleWasOfficial != true) {
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
    await prefs.setString(
      _lastScheduleAdhanSoundKey,
      (await loadAdhanSettings()).sound.id,
    );
    await prefs.setDouble(
      _lastScheduleAdhanVolumeKey,
      (await loadAdhanSettings()).volume,
    );
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
        final reminderId = _notificationId(date, prayer);
        await _notifications.cancel(id: reminderId);
        await _cancelNativeNotification(reminderId);
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
        await _cancelNativeNotification(adhanId);
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

  static Future<bool> _scheduleNativeAdhan({
    required int id,
    required DateTime time,
    required String prayerName,
    required AdhanSoundOption sound,
    required double volume,
  }) async {
    if (!_isAndroid ||
        (sound.rawResourceName == null && sound.filePath == null)) {
      return false;
    }

    try {
      final scheduled = await _nativeAdhanChannel.invokeMethod<bool>('schedule', {
        'id': id,
        'triggerAtMillis': time.millisecondsSinceEpoch,
        'prayerName': prayerName,
        'rawResourceName': sound.rawResourceName,
        'filePath': sound.filePath,
        'volume': _sanitizeAdhanVolume(volume),
      });
      return scheduled ?? false;
    } catch (_) {
      return false;
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

  static Future<bool> _scheduleNativeNotification({
    required int id,
    required DateTime time,
    required String title,
    required String body,
    required Duration timeoutAfter,
  }) async {
    if (!_isAndroid) {
      return false;
    }

    try {
      final scheduled = await _nativeAdhanChannel.invokeMethod<bool>(
        'scheduleNotification',
        {
          'id': id,
          'triggerAtMillis': time.millisecondsSinceEpoch,
          'title': title,
          'body': body,
          'timeoutAfterMillis': timeoutAfter.inMilliseconds,
        },
      );
      return scheduled ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _cancelNativeNotification(int id) async {
    if (!_isAndroid) {
      return;
    }

    try {
      await _nativeAdhanChannel.invokeMethod<bool>('cancelNotification', {
        'id': id,
      });
    } catch (_) {
      // No-op: cancelling the Flutter notification remains the source of truth.
    }
  }

  static Future<int> _nativePendingScheduledCount() async {
    if (!_isAndroid) {
      return 0;
    }

    try {
      final count = await _nativeAdhanChannel.invokeMethod<int>(
        'pendingScheduledCount',
      );
      return count ?? 0;
    } catch (_) {
      return 0;
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
        timeoutAfter: 5 * 60 * 1000,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
  }

  static NotificationDetails _prayerTimeNotificationDetails(
    DateTime prayerTime,
  ) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        icon: _notificationIconName,
        largeIcon: const DrawableResourceAndroidBitmap(
          _notificationLargeIconName,
        ),
        color: _notificationColor,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        timeoutAfter: _adhanElapsedVisibility.inMilliseconds,
        showWhen: true,
        when: prayerTime.millisecondsSinceEpoch,
      ),
      iOS: const DarwinNotificationDetails(),
      macOS: const DarwinNotificationDetails(),
    );
  }

  static Future<NotificationDetails> _adhanNotificationDetails({
    required DateTime prayerTime,
  }) async {
    final bypassDnd = await _canBypassDnd();
    return NotificationDetails(
      android: _adhanAndroidDetails(
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

  static AndroidNotificationDetails _adhanAndroidDetails({
    required DateTime prayerTime,
    required bool bypassDnd,
  }) {
    final channelId = bypassDnd
        ? '${_nativeAdhanNotificationChannelId}_bypass_silent'
        : _nativeAdhanNotificationChannelId;
    final channelName = bypassDnd
        ? 'تنبيه الأذان - يتجاوز الصامت'
        : 'تنبيه الأذان';

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
      playSound: false,
      sound: null,
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

  static double _sanitizeAdhanVolume(double volume) {
    if (volume.isNaN || volume.isInfinite) {
      return defaultAdhanVolume;
    }
    return volume.clamp(0.1, 1).toDouble();
  }

  // ───────────────────────────────────────────────
  // Public helpers for external custom notifications
  // ───────────────────────────────────────────────

  /// Schedule a repeating custom notification (e.g. Sunnah Reminders).
  static Future<void> scheduleCustom({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
  }) async {
    await _initializeNotifications(requestPermissions: false);
    final mode = await _androidScheduleMode();
    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: mode,
      matchDateTimeComponents: matchDateTimeComponents,
      payload: payload,
    );
  }

  /// Cancel a custom notification by its [id].
  static Future<void> cancelCustom(int id) async {
    await _initializeNotifications(requestPermissions: false);
    await _notifications.cancel(id: id);
  }
}

@pragma('vm:entry-point')
void _notificationTapBackground(NotificationResponse notificationResponse) {
  // Can be used to handle background taps if needed, e.g., tracking analytics.
}
