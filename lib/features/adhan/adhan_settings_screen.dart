import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/core/permission_explanation_screen.dart';
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
  String? _previewingSoundId;
  String? _previewBusySoundId;

  @override
  void initState() {
    super.initState();
    PrayerNotificationService.setAdhanPreviewCompletedHandler(
      _handleAdhanPreviewCompleted,
    );
    _loadInitialData();
  }

  @override
  void dispose() {
    PrayerNotificationService.setAdhanPreviewCompletedHandler(null);
    unawaited(PrayerNotificationService.stopAdhanPreview());
    super.dispose();
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.adhanCompleteSetup),
          content: Text(l10n.adhanCompleteSetupContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.later),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.adhanStartSetup),
            ),
          ],
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
        volume: current.volume,
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
        SnackBar(content: Text(AppLocalizations.of(context)!.adhanSoundSet(sound.name))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adhanSoundPickError),
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
        volume: current.volume,
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
    if (!await _confirmPermissionRequest(PermissionExplanationType.notifications)) {
      return;
    }

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
    if (!await _confirmPermissionRequest(PermissionExplanationType.exactAlarm)) {
      return;
    }

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
    if (!await _confirmPermissionRequest(PermissionExplanationType.dnd)) {
      return;
    }

    setState(() {
      _isRequestingPolicyAccess = true;
    });

    try {
      await PrayerNotificationService.requestNotificationPolicyAccess();
      await _loadHealth();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.adhanPolicySuccess),
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
    if (!await _confirmPermissionRequest(PermissionExplanationType.battery)) {
      return;
    }

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

  Future<bool> _confirmPermissionRequest(PermissionExplanationType type) async {
    final shouldContinue = await showPermissionExplanationScreen(context, type);
    return mounted && shouldContinue;
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
                ? AppLocalizations.of(context)!.adhanRescheduleSuccess
                : AppLocalizations.of(context)!.adhanRescheduleNoLocation,
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

  void _setAdhanVolume(double volume) {
    final current = _settings;
    if (current == null) {
      return;
    }

    setState(() {
      _settings = AdhanSettings(
        sound: current.sound,
        enabledPrayers: {...current.enabledPrayers},
        volume: _normalizeAdhanVolume(volume),
      );
    });
  }

  void _saveAdhanVolume(double volume) {
    final normalized = _normalizeAdhanVolume(volume);
    _saveInBackground(
      () => PrayerNotificationService.saveAdhanVolume(normalized),
    );

    final previewingSoundId = _previewingSoundId;
    if (previewingSoundId == null) {
      return;
    }

    final previewingSound = _soundOptions.cast<AdhanSoundOption?>().firstWhere(
      (sound) => sound?.id == previewingSoundId,
      orElse: () => null,
    );
    if (previewingSound == null) {
      return;
    }

    unawaited(() async {
      try {
        await PrayerNotificationService.stopAdhanPreview();
        await PrayerNotificationService.previewAdhanSound(
          previewingSound,
          volume: normalized,
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _previewingSoundId = null);
      }
    }());
  }

  Future<void> _toggleSoundPreview(AdhanSoundOption sound) async {
    final settings = _settings;
    if (settings == null || _previewBusySoundId != null) {
      return;
    }

    setState(() => _previewBusySoundId = sound.id);
    try {
      if (_previewingSoundId == sound.id) {
        await PrayerNotificationService.stopAdhanPreview();
        if (!mounted) return;
        setState(() => _previewingSoundId = null);
        return;
      }

      await PrayerNotificationService.stopAdhanPreview();
      await PrayerNotificationService.previewAdhanSound(
        sound,
        volume: settings.volume,
      );
      if (!mounted) return;
      setState(() => _previewingSoundId = sound.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.adhanPreviewError)),
      );
    } finally {
      if (mounted) {
        setState(() => _previewBusySoundId = null);
      }
    }
  }

  void _handleAdhanPreviewCompleted() {
    if (!mounted) {
      return;
    }

    setState(() => _previewingSoundId = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '${l10n.settings} ${l10n.adhan}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final l10n = AppLocalizations.of(context)!;
    final settings = _settings!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHealthCard(),
        const SizedBox(height: 18),
        _buildSectionTitle(l10n.adhanVolume),
        _buildUploadSoundButton(),
        const SizedBox(height: 10),
        _buildVolumeControl(settings.volume),
        const SizedBox(height: 10),
        ..._soundOptions.map(
          (sound) => _buildSoundOption(sound, settings.sound.id),
        ),
        const SizedBox(height: 18),
        _buildSectionTitle(l10n.prayersLabel),
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
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
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
                  AppLocalizations.of(context)!.adhanStatusTitle,
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.refreshStatus,
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
              AppLocalizations.of(context)!.adhanNotificationsPerm,
              health.notificationsEnabled,
              AppLocalizations.of(context)!.enabled,
              AppLocalizations.of(context)!.adhanNotificationsPermDesc,
            ),
            _buildHealthRow(
              Icons.alarm_on_rounded,
              AppLocalizations.of(context)!.adhanExactTimePerm,
              health.exactAlarmsEnabled,
              AppLocalizations.of(context)!.adhanExactTimeOk,
              AppLocalizations.of(context)!.adhanExactTimePermDesc,
            ),
            _buildHealthRow(
              Icons.do_not_disturb_off_rounded,
              AppLocalizations.of(context)!.adhanDndPerm,
              health.notificationPolicyAccessGranted,
              AppLocalizations.of(context)!.allowed,
              AppLocalizations.of(context)!.adhanDndPermDesc,
            ),
            _buildHealthRow(
              Icons.battery_saver_rounded,
              AppLocalizations.of(context)!.adhanBatteryPerm,
              health.batteryOptimizationsIgnored,
              AppLocalizations.of(context)!.adhanBatteryOk,
              AppLocalizations.of(context)!.adhanBatteryPermDesc,
            ),
            _buildHealthRow(
              Icons.my_location_rounded,
              AppLocalizations.of(context)!.adhanLocationPerm,
              health.hasStoredLocation,
              AppLocalizations.of(context)!.found,
              AppLocalizations.of(context)!.adhanLocationPermDesc,
            ),
            _buildHealthRow(
              Icons.event_available_rounded,
              AppLocalizations.of(context)!.adhanScheduled,
              health.pendingNotificationCount > 0,
              AppLocalizations.of(context)!.adhanScheduledCount(health.pendingNotificationCount),
              AppLocalizations.of(context)!.adhanScheduledNotYet,
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context)!.adhanBgTip,
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
                  label: AppLocalizations.of(context)!.enableNotifications,
                  busy: _isRequestingNotifications,
                  onPressed: health.notificationsEnabled
                      ? null
                      : _requestNotifications,
                ),
                _buildActionButton(
                  icon: Icons.alarm_add_rounded,
                  label: AppLocalizations.of(context)!.enableExactAlarm,
                  busy: _isRequestingExactAlarm,
                  onPressed: health.exactAlarmsEnabled
                      ? null
                      : _requestExactAlarm,
                ),
                _buildActionButton(
                  icon: Icons.do_not_disturb_off_rounded,
                  label: AppLocalizations.of(context)!.bypassDnd,
                  busy: _isRequestingPolicyAccess,
                  onPressed: health.notificationPolicyAccessGranted
                      ? null
                      : _requestPolicyAccess,
                ),
                _buildActionButton(
                  icon: Icons.battery_charging_full_rounded,
                  label: AppLocalizations.of(context)!.setupBattery,
                  busy: _isRequestingBattery,
                  onPressed: health.batteryOptimizationsIgnored
                      ? null
                      : _requestBatteryBypass,
                ),
                _buildActionButton(
                  icon: Icons.update_rounded,
                  label: AppLocalizations.of(context)!.rescheduleAdhan,
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
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.14),
        ),
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
        title: Text(
          AppLocalizations.of(context)!.adhanUploadSound,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(AppLocalizations.of(context)!.adhanUploadSoundDesc),
        trailing: Icon(Directionality.of(context) == TextDirection.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded),
        onTap: _isPickingCustomSound ? null : _pickCustomSound,
      ),
    );
  }

  Widget _buildVolumeControl(double volume) {
    final percent = (volume * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volume_up_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.adhanVolume,
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: volume,
            min: 0.1,
            max: 1,
            divisions: 9,
            activeColor: AppTheme.primaryColor,
            onChanged: _setAdhanVolume,
            onChangeEnd: _saveAdhanVolume,
          ),
        ],
      ),
    );
  }

  Widget _buildSoundOption(AdhanSoundOption sound, String selectedSoundId) {
    final isSelected = selectedSoundId == sound.id;
    final isPreviewing = _previewingSoundId == sound.id;
    final isBusy = _previewBusySoundId == sound.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isSelected ? null : () => _setSound(sound.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.mutedTextColor(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      sound.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sound.description,
                      style: TextStyle(color: AppTheme.mutedTextColor(context)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: isPreviewing
                    ? AppLocalizations.of(context)!.stopPreview
                    : AppLocalizations.of(context)!.listenAdhan,
                onPressed: isBusy ? null : () => _toggleSoundPreview(sound),
                icon: isBusy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        isPreviewing
                            ? Icons.pause_rounded
                            : Icons.volume_up_rounded,
                      ),
              ),
            ],
          ),
        ),
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
        activeThumbColor: AppTheme.primaryColor,
        secondary: Icon(
          enabled
              ? Icons.notifications_active_rounded
              : Icons.notifications_off_rounded,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          PrayerService.getPrayerName(prayer, AppLocalizations.of(context)!),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          enabled
              ? AppLocalizations.of(context)!.adhanEnabled
              : AppLocalizations.of(context)!.adhanDisabled,
        ),
      ),
    );
  }

  Widget _buildAttributionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        AppLocalizations.of(context)!.adhanAttribution,
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

  static double _normalizeAdhanVolume(double volume) {
    if (volume.isNaN || volume.isInfinite) {
      return PrayerNotificationService.defaultAdhanVolume;
    }
    return volume.clamp(0.1, 1).toDouble();
  }
}
