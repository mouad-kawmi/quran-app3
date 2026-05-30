import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:quran_app/core/prayer_notification_service.dart';
import 'package:quran_app/core/prayer_service.dart';
import 'package:quran_app/core/theme.dart';

class AdhanSettingsScreen extends StatefulWidget {
  const AdhanSettingsScreen({super.key, this.startSetupGuide = false});

  final bool startSetupGuide;

  @override
  State<AdhanSettingsScreen> createState() => _AdhanSettingsScreenState();
}

class _AdhanSettingsScreenState extends State<AdhanSettingsScreen> {
  AdhanSettings? _settings;
  List<AdhanSoundOption> _soundOptions = const [];
  NotificationHealthStatus? _health;
  bool _isLoading = true;
  bool _isRefreshingHealth = false;
  bool _isRequestingNotifications = false;
  bool _isRequestingExactAlarm = false;
  bool _isRequestingPolicyAccess = false;
  bool _isRequestingBattery = false;
  bool _isRescheduling = false;
  bool _isPickingCustomSound = false;
  bool _setupGuideStarted = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final settings = await PrayerNotificationService.loadAdhanSettings();
    final soundOptions =
        await PrayerNotificationService.loadAvailableAdhanSounds();
    final health = await PrayerNotificationService.loadNotificationHealth();
    if (!mounted) return;

    setState(() {
      _settings = settings;
      _soundOptions = soundOptions;
      _health = health;
      _isLoading = false;
    });

    _startSetupGuideIfNeeded();
  }

  void _startSetupGuideIfNeeded() {
    if (!widget.startSetupGuide || _setupGuideStarted) {
      return;
    }

    final health = _health;
    if (health == null || !PrayerNotificationService.needsAdhanSetup(health)) {
      return;
    }

    _setupGuideStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_startSetupGuide());
    });
  }

  Future<void> _startSetupGuide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إكمال تفعيل الأذان'),
            content: const Text(
              'سيطلب التطبيق تفعيل التنبيهات والوقت الدقيق وتجاوز عدم الإزعاج واستثناء البطارية، ثم يعيد برمجة الأذان حتى يعمل في وقته.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('لاحقا'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('ابدأ الإعداد'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    var health =
        _health ?? await PrayerNotificationService.loadNotificationHealth();
    if (!health.notificationsEnabled) {
      await _requestNotifications();
      health =
          _health ?? await PrayerNotificationService.loadNotificationHealth();
    }

    if (!health.exactAlarmsEnabled) {
      await _requestExactAlarm();
      health =
          _health ?? await PrayerNotificationService.loadNotificationHealth();
    }

    if (!health.notificationPolicyAccessGranted) {
      await _requestPolicyAccess();
      health =
          _health ?? await PrayerNotificationService.loadNotificationHealth();
    }

    if (!health.batteryOptimizationsIgnored) {
      await _requestBatteryBypass();
    }

    if (!mounted) return;
    await _rescheduleNotifications();
  }

  Future<void> _loadSettings() async {
    final settings = await PrayerNotificationService.loadAdhanSettings();
    final soundOptions =
        await PrayerNotificationService.loadAvailableAdhanSounds();
    if (!mounted) return;

    setState(() {
      _settings = settings;
      _soundOptions = soundOptions;
      _isLoading = false;
    });
  }

  Future<void> _loadHealth() async {
    final health = await PrayerNotificationService.loadNotificationHealth();
    if (!mounted) return;

    setState(() {
      _health = health;
    });
  }

  Future<void> _setSound(String soundId) async {
    final current = _settings;
    if (current == null || current.sound.id == soundId) {
      return;
    }

    final sound = _soundOptions.firstWhere(
      (sound) => sound.id == soundId,
      orElse: () => PrayerNotificationService.adhanSoundById(soundId),
    );
    setState(() {
      _settings = AdhanSettings(
        sound: sound,
        enabledPrayers: {...current.enabledPrayers},
      );
    });

    _saveInBackground(() => PrayerNotificationService.saveAdhanSound(soundId));
  }

  Future<void> _pickCustomSound() async {
    setState(() {
      _isPickingCustomSound = true;
    });

    try {
      final sound = await PrayerNotificationService.pickCustomAdhanSound();
      if (sound == null) {
        return;
      }

      final settings = await PrayerNotificationService.loadAdhanSettings();
      final soundOptions =
          await PrayerNotificationService.loadAvailableAdhanSounds();
      if (!mounted) return;

      setState(() {
        _settings = settings;
        _soundOptions = soundOptions;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم اعتماد صوت الأذان: ${sound.name}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر اختيار الملف الصوتي. حاول مرة أخرى.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingCustomSound = false;
        });
      }
    }
  }

  void _togglePrayer(Prayer prayer, bool enabled) {
    final current = _settings;
    if (current == null) {
      return;
    }

    final enabledPrayers = {...current.enabledPrayers};
    if (enabled) {
      enabledPrayers.add(prayer);
    } else {
      enabledPrayers.remove(prayer);
    }

    setState(() {
      _settings = AdhanSettings(
        sound: current.sound,
        enabledPrayers: enabledPrayers,
      );
    });

    _saveInBackground(
      () => PrayerNotificationService.setPrayerAdhanEnabled(prayer, enabled),
    );
  }

  Future<void> _refreshHealth() async {
    setState(() {
      _isRefreshingHealth = true;
    });

    try {
      await _loadHealth();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingHealth = false;
        });
      }
    }
  }

  Future<void> _requestNotifications() async {
    setState(() {
      _isRequestingNotifications = true;
    });

    try {
      await PrayerNotificationService.requestNotificationsPermission();
      await _loadHealth();
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingNotifications = false;
        });
      }
    }
  }

  Future<void> _requestExactAlarm() async {
    setState(() {
      _isRequestingExactAlarm = true;
    });

    try {
      await PrayerNotificationService.requestExactAlarmPermission();
      await _loadHealth();
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingExactAlarm = false;
        });
      }
    }
  }

  Future<void> _requestPolicyAccess() async {
    setState(() {
      _isRequestingPolicyAccess = true;
    });

    try {
      await PrayerNotificationService.requestNotificationPolicyAccess();
      await _loadHealth();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'بعد منح الإذن، اضغط إعادة البرمجة لتحديث تنبيهات الأذان.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingPolicyAccess = false;
        });
      }
    }
  }

  Future<void> _requestBatteryBypass() async {
    setState(() {
      _isRequestingBattery = true;
    });

    try {
      await PrayerNotificationService.requestBatteryOptimizationBypass();
      await _loadHealth();
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingBattery = false;
        });
      }
    }
  }

  Future<void> _rescheduleNotifications() async {
    setState(() {
      _isRescheduling = true;
    });

    try {
      await PrayerNotificationService.refreshStoredPrayerReminders(force: true);
      await _loadHealth();
      if (!mounted) return;

      final hasLocation = _health?.hasStoredLocation ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasLocation
                ? 'تم تحديث برمجة الأذان والتنبيهات.'
                : 'لا يوجد موقع محفوظ بعد. افتح الصفحة الرئيسية لتحديد مواقيت الصلاة.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRescheduling = false;
        });
      }
    }
  }

  void _saveInBackground(Future<void> Function() save) {
    unawaited(() async {
      try {
        await save();
      } catch (_) {
        if (mounted) {
          await _loadSettings();
        }
      }
    }());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'إعدادات الأذان',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final settings = _settings!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHealthCard(),
        const SizedBox(height: 18),
        _buildSectionTitle('صوت الأذان'),
        _buildUploadSoundButton(),
        const SizedBox(height: 10),
        ..._soundOptions.map(
          (sound) => _buildSoundOption(sound, settings.sound.id),
        ),
        const SizedBox(height: 18),
        _buildSectionTitle('الصلوات'),
        ..._prayers.map(
          (prayer) => _buildPrayerSwitch(prayer, settings.isEnabledFor(prayer)),
        ),
        const SizedBox(height: 18),
        _buildAttributionCard(),
      ],
    );
  }

  Widget _buildHealthCard() {
    final health = _health;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'حالة الأذان والتنبيهات',
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'تحديث الحالة',
                onPressed: _isRefreshingHealth ? null : _refreshHealth,
                icon: _isRefreshingHealth
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (health == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildHealthRow(
              Icons.notifications_active_rounded,
              'إذن التنبيهات',
              health.notificationsEnabled,
              'مفعّل',
              'يلزم تفعيله لإظهار تنبيهات الأذان',
            ),
            _buildHealthRow(
              Icons.alarm_on_rounded,
              'التنبيه في الوقت الدقيق',
              health.exactAlarmsEnabled,
              'مفعّل للوقت الدقيق',
              'قد يتأخر الأذان إذا بقي غير مفعّل',
            ),
            _buildHealthRow(
              Icons.do_not_disturb_off_rounded,
              'تجاوز عدم الإزعاج',
              health.notificationPolicyAccessGranted,
              'مسموح',
              'اختياري عند منع أصوات المنبهات',
            ),
            _buildHealthRow(
              Icons.battery_saver_rounded,
              'استثناء البطارية',
              health.batteryOptimizationsIgnored,
              'مستثنى من التوفير',
              'يساعد على استمرار الأذان في الخلفية',
            ),
            _buildHealthRow(
              Icons.my_location_rounded,
              'الموقع المحفوظ',
              health.hasStoredLocation,
              'موجود',
              'افتح الرئيسية لتحديد المواقيت',
            ),
            _buildHealthRow(
              Icons.event_available_rounded,
              'التنبيهات المبرمجة',
              health.pendingNotificationCount > 0,
              '${health.pendingNotificationCount} تنبيه',
              'لم تتم برمجة التنبيهات بعد',
            ),
            const SizedBox(height: 6),
            Text(
              'يعمل الأذان كمنبه في الخلفية. إذا كان وضع عدم الإزعاج يمنع أصوات المنبهات، فعّل إذن تجاوز عدم الإزعاج ثم أعد البرمجة.',
              style: TextStyle(
                color: AppTheme.mutedTextColor(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  icon: Icons.notifications_rounded,
                  label: 'تفعيل التنبيهات',
                  busy: _isRequestingNotifications,
                  onPressed: health.notificationsEnabled
                      ? null
                      : _requestNotifications,
                ),
                _buildActionButton(
                  icon: Icons.alarm_add_rounded,
                  label: 'تفعيل الوقت الدقيق',
                  busy: _isRequestingExactAlarm,
                  onPressed: health.exactAlarmsEnabled
                      ? null
                      : _requestExactAlarm,
                ),
                _buildActionButton(
                  icon: Icons.do_not_disturb_off_rounded,
                  label: 'تجاوز عدم الإزعاج',
                  busy: _isRequestingPolicyAccess,
                  onPressed: health.notificationPolicyAccessGranted
                      ? null
                      : _requestPolicyAccess,
                ),
                _buildActionButton(
                  icon: Icons.battery_charging_full_rounded,
                  label: 'إعداد البطارية',
                  busy: _isRequestingBattery,
                  onPressed: health.batteryOptimizationsIgnored
                      ? null
                      : _requestBatteryBypass,
                ),
                _buildActionButton(
                  icon: Icons.update_rounded,
                  label: 'إعادة البرمجة',
                  busy: _isRescheduling,
                  onPressed: _rescheduleNotifications,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHealthRow(
    IconData icon,
    String title,
    bool isOk,
    String okText,
    String warningText,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isOk ? AppTheme.primaryColor : AppTheme.secondaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.primaryTextColor(context),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              isOk ? okText : warningText,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isOk ? AppTheme.primaryColor : Colors.orange[800],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool busy,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(label),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildUploadSoundButton() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.14)),
      ),
      child: ListTile(
        leading: _isPickingCustomSound
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.upload_file_rounded,
                color: AppTheme.primaryColor,
              ),
        title: const Text(
          'إضافة أذان من الهاتف',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('اختر ملفا صوتيا ليستعمله التطبيق للأذان'),
        trailing: const Icon(Icons.chevron_left_rounded),
        onTap: _isPickingCustomSound ? null : _pickCustomSound,
      ),
    );
  }

  Widget _buildSoundOption(AdhanSoundOption sound, String selectedSoundId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: RadioListTile<String>(
        value: sound.id,
        groupValue: selectedSoundId,
        onChanged: selectedSoundId == sound.id
            ? null
            : (value) => _setSound(value!),
        activeColor: AppTheme.primaryColor,
        title: Text(
          sound.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(sound.description),
      ),
    );
  }

  Widget _buildPrayerSwitch(Prayer prayer, bool enabled) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        value: enabled,
        onChanged: (value) => _togglePrayer(prayer, value),
        activeColor: AppTheme.primaryColor,
        secondary: Icon(
          enabled
              ? Icons.notifications_active_rounded
              : Icons.notifications_off_rounded,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          PrayerService.getPrayerName(prayer),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(enabled ? 'الأذان مفعّل' : 'الأذان غير مفعّل'),
      ),
    );
  }

  Widget _buildAttributionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'أصوات الأذان من Wikimedia Commons تحت رخصة CC BY-SA 4.0: Andrewler و Atcovi.',
        style: TextStyle(
          color: AppTheme.mutedTextColor(context),
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }

  static const List<Prayer> _prayers = [
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];
}
