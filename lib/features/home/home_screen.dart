import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/habous_prayer_times_service.dart';
import 'package:quran_app/core/khatma_service.dart';
import 'package:quran_app/core/prayer_notification_service.dart';
import 'package:quran_app/core/prayer_service.dart';
import 'package:quran_app/core/prayer_widget_service.dart';
import 'package:quran_app/core/reading_progress_service.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/adhkar/adhkar_screen.dart';
import 'package:quran_app/features/adhan/adhan_settings_screen.dart';
import 'package:quran_app/features/khatma/khatma_screen.dart';
import 'package:quran_app/features/prayer_times/prayer_times_screen.dart';
import 'package:quran_app/features/qibla/qibla_screen.dart';
import 'package:quran_app/features/quran/quran_reader_screen.dart';
import 'package:quran_app/features/quran/surah_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onSelectMainTab});

  final ValueChanged<int>? onSelectMainTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _CountdownSnapshot {
  const _CountdownSnapshot({
    required this.remaining,
    required this.elapsedSinceAdhan,
    required this.progress,
    required this.isLoading,
    required this.isAdhanElapsed,
  });

  static const empty = _CountdownSnapshot(
    remaining: Duration.zero,
    elapsedSinceAdhan: Duration.zero,
    progress: 0,
    isLoading: true,
    isAdhanElapsed: false,
  );

  final Duration remaining;
  final Duration elapsedSinceAdhan;
  final double progress;
  final bool isLoading;
  final bool isAdhanElapsed;

  Duration get displayDuration {
    return isAdhanElapsed ? elapsedSinceAdhan : remaining;
  }

  String get displayLabel {
    return isAdhanElapsed ? 'مضى على الأذان' : 'متبقي';
  }
}

class _DailyAyah {
  const _DailyAyah({
    required this.surah,
    required this.ayah,
    required this.text,
    required this.reference,
  });

  final int surah;
  final int ayah;
  final String text;
  final String reference;
}

class _HomeScreenState extends State<HomeScreen> {
  static const Duration _adhanElapsedDisplayDuration = Duration(minutes: 30);

  Timer? _timer;
  final ValueNotifier<_CountdownSnapshot> _countdown = ValueNotifier(
    _CountdownSnapshot.empty,
  );
  PrayerLocation? _prayerLocation;
  PrayerSchedule? _prayerSchedule;
  List<PrayerMoment> _todayPrayerMoments = const [];
  String _hijriDate = '';
  String _gregorianDate = '';
  DateTime? _dateLabelDay;
  String? _locationError;
  String? _locationNotice;
  bool _isLoadingPrayerTimes = true;
  int _locationRequestSerial = 0;
  KhatmaProgress? _khatmaProgress;
  QuranLastRead? _lastRead;
  NotificationHealthStatus? _notificationHealth;
  bool _showAdhanSetupCard = false;
  bool _adhanSetupSheetVisible = false;

  @override
  void initState() {
    super.initState();
    _primeFallbackPrayerTimes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_primeStoredPrayerTimes());
      unawaited(
        _loadPrayerTimes(showLoading: false).whenComplete(() {
          if (!mounted) return;
          unawaited(_refreshAdhanSetupStatus(showInitialPrompt: true));
        }),
      );
      unawaited(_loadReadingProgress());
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickPrayerCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdown.dispose();
    super.dispose();
  }

  void _primeFallbackPrayerTimes() {
    final now = DateTime.now();
    final location = PrayerService.fallbackLocation;
    final schedule = PrayerService.getSchedule(location.coordinates, now: now);

    _updateDateLabels(now);
    _prayerLocation = location;
    _prayerSchedule = schedule;
    _todayPrayerMoments = schedule.times == null
        ? const []
        : PrayerService.prayerMoments(schedule.times!);
    _locationNotice = location.notice;
    _locationError = null;
    _isLoadingPrayerTimes = false;
    _updateCountdownSnapshot(now, schedule);
    _syncPrayerWidget();
  }

  Future<void> _primeStoredPrayerTimes() async {
    final location = await PrayerService.loadStoredLocation();
    if (!mounted || location == null) return;
    _applyPrayerLocation(location);
  }

  Future<void> _loadPrayerTimes({bool showLoading = true}) async {
    final requestSerial = ++_locationRequestSerial;
    if (showLoading) {
      setState(() {
        _isLoadingPrayerTimes = true;
        _locationError = null;
      });
      final schedule = _prayerSchedule;
      if (schedule != null) {
        _updateCountdownSnapshot(DateTime.now(), schedule, isLoading: true);
      }
    }

    try {
      final location = await PrayerService.getBestAvailableLocation(
        timeout: showLoading
            ? PrayerService.preciseLocationTimeout
            : PrayerService.quickLocationTimeout,
      );
      if (!mounted || requestSerial != _locationRequestSerial) return;

      _applyPrayerLocation(location);
      unawaited(
        PrayerNotificationService.schedulePrayerReminders(location.coordinates)
            .whenComplete(() {
          if (!mounted) return;
          unawaited(_refreshAdhanSetupStatus(showInitialPrompt: true));
        }),
      );
    } on PrayerLocationException catch (error) {
      if (!mounted || requestSerial != _locationRequestSerial) return;
      setState(() {
        _isLoadingPrayerTimes = false;
        _locationError = error.message;
        _locationNotice = null;
      });
      _setCountdownLoading(false);
    } catch (_) {
      if (!mounted || requestSerial != _locationRequestSerial) return;
      setState(() {
        _isLoadingPrayerTimes = false;
        _locationError = 'حدث خطأ أثناء قراءة الموقع. حاول مرة أخرى.';
        _locationNotice = null;
      });
      _setCountdownLoading(false);
    }
  }

  void _applyPrayerLocation(PrayerLocation location) {
    final now = DateTime.now();
    final schedule = PrayerService.getSchedule(location.coordinates, now: now);

    setState(() {
      _prayerLocation = location;
      _prayerSchedule = schedule;
      _todayPrayerMoments = schedule.times == null
          ? const []
          : PrayerService.prayerMoments(schedule.times!);
      _locationNotice = location.notice;
      _locationError = null;
      _isLoadingPrayerTimes = false;
      _updateDateLabels(now);
    });
    _updateCountdownSnapshot(now, schedule);
    _syncPrayerWidget();
    unawaited(_applyOfficialPrayerSchedule(location));
  }

  Future<void> _applyOfficialPrayerSchedule(PrayerLocation location) async {
    try {
      final todayDisplay = await HabousPrayerTimesService.getTodayPrayerTimes(
        location,
      );
      final todayMoments = HabousPrayerTimesService.momentsFromDisplay(
        todayDisplay,
      );
      final schedule = await HabousPrayerTimesService.getPrayerSchedule(
        location,
      );
      if (!mounted || !_isSamePrayerLocation(location, _prayerLocation)) {
        return;
      }

      setState(() {
        _prayerSchedule = schedule;
        _todayPrayerMoments = todayMoments;
      });
      _updateCountdownSnapshot(DateTime.now(), schedule);
      _syncPrayerWidget();
    } catch (_) {
      // Keep the already visible local schedule if the official source fails.
    }
  }

  Future<void> _loadReadingProgress() async {
    final khatmaProgress = await KhatmaService.loadProgress();
    final lastRead = await ReadingProgressService.loadLastRead();
    if (!mounted) return;

    setState(() {
      _khatmaProgress = khatmaProgress;
      _lastRead = lastRead;
    });
  }

  Future<void> _pushAndRefreshReading(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    if (!mounted) return;
    await _loadReadingProgress();
  }

  void _openSurahList() {
    final onSelectMainTab = widget.onSelectMainTab;
    if (onSelectMainTab != null) {
      onSelectMainTab(1);
      return;
    }

    unawaited(_pushAndRefreshReading(const SurahListScreen()));
  }

  void _openKhatma() {
    unawaited(_pushAndRefreshReading(const KhatmaScreen()));
  }

  void _openKhatmaProgress() {
    final khatma = _khatmaProgress;
    final nextPage = khatma?.nextPage;
    if (khatma?.hasPlan == true && nextPage != null) {
      unawaited(
        _pushAndRefreshReading(
          KhatmaPageScreen(
            page: nextPage,
            returnToKhatmaHomeOnBack: true,
          ),
        ),
      );
      return;
    }

    _openKhatma();
  }

  void _openLastRead() {
    final lastRead = _lastRead;
    if (lastRead == null) {
      _openSurahList();
      return;
    }

    unawaited(
      _pushAndRefreshReading(
        QuranReaderScreen(
          surahNumber: lastRead.surah,
          initialAyah: lastRead.ayah,
        ),
      ),
    );
  }

  void _tickPrayerCountdown() {
    final location = _prayerLocation;
    final now = DateTime.now();

    _refreshDateLabelsIfNeeded(now);

    if (location == null) return;

    var schedule = _prayerSchedule;
    if (schedule == null || !schedule.nextPrayer.time.isAfter(now)) {
      schedule = PrayerService.getSchedule(location.coordinates, now: now);
      if (mounted) {
        setState(() {
          _prayerSchedule = schedule;
          _todayPrayerMoments = schedule?.times == null
              ? const []
              : PrayerService.prayerMoments(schedule!.times!);
        });
      }
      _syncPrayerWidget();
      unawaited(_applyOfficialPrayerSchedule(location));
    }

    _updateCountdownSnapshot(now, schedule);
  }

  bool _isSamePrayerLocation(PrayerLocation expected, PrayerLocation? current) {
    if (current == null) {
      return false;
    }

    const tolerance = 0.000001;
    return (expected.coordinates.latitude - current.coordinates.latitude)
                .abs() <
            tolerance &&
        (expected.coordinates.longitude - current.coordinates.longitude).abs() <
            tolerance;
  }

  void _refreshDateLabelsIfNeeded(DateTime now) {
    final currentDay = DateTime(now.year, now.month, now.day);
    if (_dateLabelDay == currentDay || !mounted) return;
    setState(() {
      _updateDateLabels(now);
    });
    _syncPrayerWidget();
  }

  void _updateDateLabels(DateTime now) {
    _dateLabelDay = DateTime(now.year, now.month, now.day);
    _hijriDate = PrayerService.getHijriDate();
    _gregorianDate = PrayerService.toWesternDigits(
      DateFormat('EEEE، d MMMM yyyy', 'ar').format(now),
    );
  }

  void _updateCountdownSnapshot(
    DateTime now,
    PrayerSchedule schedule, {
    bool? isLoading,
  }) {
    final elapsedSinceAdhan = now.difference(schedule.previousPrayer.time);
    final isAdhanElapsed = !elapsedSinceAdhan.isNegative &&
        elapsedSinceAdhan <= _adhanElapsedDisplayDuration;
    final elapsedProgress = elapsedSinceAdhan.inSeconds /
        _adhanElapsedDisplayDuration.inSeconds;

    _countdown.value = _CountdownSnapshot(
      remaining: schedule.timeUntilNextPrayer(now),
      elapsedSinceAdhan: elapsedSinceAdhan.isNegative
          ? Duration.zero
          : elapsedSinceAdhan,
      progress: isAdhanElapsed
          ? elapsedProgress.clamp(0, 1).toDouble()
          : schedule.progress(now),
      isLoading: isLoading ?? _isLoadingPrayerTimes,
      isAdhanElapsed: isAdhanElapsed,
    );
  }

  void _setCountdownLoading(bool isLoading) {
    final schedule = _prayerSchedule;
    if (schedule == null) return;
    _updateCountdownSnapshot(DateTime.now(), schedule, isLoading: isLoading);
  }

  void _syncPrayerWidget() {
    final location = _prayerLocation;
    final schedule = _prayerSchedule;
    if (location == null || schedule == null || _todayPrayerMoments.isEmpty) {
      return;
    }

    unawaited(
      PrayerWidgetService.update(
        location: location,
        schedule: schedule,
        todayMoments: _todayPrayerMoments,
        hijriDate: _hijriDate,
      ),
    );
  }

  Future<void> _refreshAdhanSetupStatus({
    bool showInitialPrompt = false,
  }) async {
    final health = await PrayerNotificationService.loadNotificationHealth();
    if (!mounted) return;

    final needsSetup = PrayerNotificationService.needsAdhanSetup(health);
    setState(() {
      _notificationHealth = health;
      _showAdhanSetupCard = needsSetup;
    });

    if (!showInitialPrompt || !needsSetup || _adhanSetupSheetVisible) {
      return;
    }

    final shouldShow =
        await PrayerNotificationService.shouldShowInitialAdhanSetupPrompt(
      health,
    );
    if (!mounted || !shouldShow || _adhanSetupSheetVisible) {
      return;
    }

    await PrayerNotificationService.markInitialAdhanSetupPromptShown();
    if (!mounted) return;
    _showInitialAdhanSetupSheet();
  }

  Future<void> _openAdhanSettings({bool startSetupGuide = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdhanSettingsScreen(
          startSetupGuide: startSetupGuide,
        ),
      ),
    );
    if (!mounted) return;
    await _refreshAdhanSetupStatus();
  }

  void _showInitialAdhanSetupSheet() {
    _adhanSetupSheetVisible = true;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useSafeArea: true,
        backgroundColor: AppTheme.elevatedSurfaceColor(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'إكمال تفعيل الأذان',
                        style: TextStyle(
                          color: AppTheme.primaryTextColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'يحتاج الأذان تفعيل التنبيهات والوقت الدقيق واستثناء البطارية مرة واحدة حتى يعمل في وقته، ثم يعيد التطبيق برمجة الأذان تلقائيا.',
                  style: TextStyle(
                    color: AppTheme.mutedTextColor(context),
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(_openAdhanSettings(startSetupGuide: true));
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('إعداد الأذان الآن'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('لاحقا'),
                ),
              ],
            ),
          ),
        ),
      ).whenComplete(() {
        _adhanSetupSheetVisible = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildPrayerTimeCard(),
                    if (_showAdhanSetupCard) ...[
                      const SizedBox(height: 12),
                      _buildAdhanSetupCard(),
                    ],
                    const SizedBox(height: 24),
                    _buildAyahOfTheDay(),
                    const SizedBox(height: 32),
                    _buildSectionHeader('الخدمات الرئيسية'),
                    const SizedBox(height: 16),
                    _buildServicesGrid(context),
                    const SizedBox(height: 32),
                    _buildSectionHeader(
                      'متابعة القراءة',
                      action: 'القائمة كاملة',
                      onActionTap: _openSurahList,
                    ),
                    const SizedBox(height: 16),
                    _buildReadingProgressCards(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.book_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'نور القرآن',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'رفيقك في تدبر الذكر الحكيم',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeCard() {
    final schedule = _prayerSchedule;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              AppTheme.isDark(context) ? 0.18 : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hijriDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _gregorianDate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.mutedTextColor(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildLocationBadge(),
            ],
          ),
          if (_locationNotice != null && _locationError == null) ...[
            const SizedBox(height: 16),
            _buildLocationNotice(),
          ],
          const SizedBox(height: 30),
          if (_locationError != null)
            _buildLocationError()
          else
            ValueListenableBuilder<_CountdownSnapshot>(
              valueListenable: _countdown,
              builder: (context, countdown, _) {
                final displayPrayer = countdown.isAdhanElapsed
                    ? schedule?.previousPrayer
                    : schedule?.nextPrayer;
                final prayerTitle = countdown.isAdhanElapsed
                    ? 'الأذان الحالي'
                    : 'الصلاة القادمة';
                final prayerName = displayPrayer == null
                    ? '--'
                    : PrayerService.getPrayerName(displayPrayer.prayer);
                final prayerTime = displayPrayer == null
                    ? '--:--'
                    : DateFormat('HH:mm').format(displayPrayer.time);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildProgressCircle(
                      countdown.isLoading
                          ? '--:--:--'
                          : PrayerService.formatDuration(
                              countdown.displayDuration,
                            ),
                      countdown.displayLabel,
                      isLoading: countdown.isLoading,
                      progress: countdown.progress,
                    ),
                    Column(
                      children: [
                        Text(
                          prayerTitle,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          prayerName,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          prayerTime,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAdhanSetupCard() {
    final health = _notificationHealth;
    final notificationsOk = health?.notificationsEnabled ?? false;
    final exactOk = health?.exactAlarmsEnabled ?? false;
    final dndOk = health?.notificationPolicyAccessGranted ?? false;
    final batteryOk = health?.batteryOptimizationsIgnored ?? false;
    final locationOk = health?.hasStoredLocation ?? false;
    final scheduleOk = (health?.pendingNotificationCount ?? 0) > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.secondaryColor.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.alarm_add_rounded,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'الأذان يحتاج إكمال الإعداد',
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'فعّل التنبيهات والوقت الدقيق واستثناء البطارية مرة واحدة حتى لا ينتظر المستخدم الأذان وهو غير جاهز.',
            style: TextStyle(
              color: AppTheme.mutedTextColor(context),
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAdhanSetupPill('التنبيهات', notificationsOk),
              _buildAdhanSetupPill('الوقت الدقيق', exactOk),
              _buildAdhanSetupPill('عدم الإزعاج', dndOk),
              _buildAdhanSetupPill('البطارية', batteryOk),
              _buildAdhanSetupPill('الموقع', locationOk),
              _buildAdhanSetupPill('البرمجة', scheduleOk),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => unawaited(
                _openAdhanSettings(startSetupGuide: true),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('إكمال الإعداد'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdhanSetupPill(String label, bool isOk) {
    final color = isOk ? AppTheme.primaryColor : Colors.orange[800]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.error_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBadge() {
    final location = _prayerLocation;
    return InkWell(
      onTap: _isLoadingPrayerTimes ? null : _loadPrayerTimes,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.subtleSurfaceColor(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              location?.isFallback == true || _locationError != null
                  ? Icons.location_off_rounded
                  : Icons.location_on_rounded,
              color: AppTheme.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _isLoadingPrayerTimes
                    ? 'تحديد الموقع'
                    : location?.name ?? 'الموقع',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.primaryTextColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationNotice() {
    return InkWell(
      onTap: _isLoadingPrayerTimes ? null : _loadPrayerTimes,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.gps_off_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _locationNotice!,
                style: TextStyle(
                  color: AppTheme.mutedTextColor(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.refresh_rounded,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationError() {
    return Column(
      children: [
        Icon(Icons.my_location_rounded, color: Colors.grey[400], size: 42),
        const SizedBox(height: 12),
        Text(
          _locationError!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _loadPrayerTimes,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
        ),
      ],
    );
  }

  Widget _buildProgressCircle(
    String time,
    String label, {
    required bool isLoading,
    required double progress,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 108,
          height: 108,
          child: CircularProgressIndicator(
            value: isLoading ? null : progress,
            strokeWidth: 8,
            backgroundColor: AppTheme.subtleSurfaceColor(context),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.accentColor,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                color: AppTheme.primaryTextColor(context),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.mutedTextColor(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAyahOfTheDay() {
    final dailyAyah = _dailyAyah();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(25),
        border: Border(
          right: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.5),
            width: 5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'آية اليوم',
              style: TextStyle(
                color: AppTheme.secondaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '"${dailyAyah.text}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: AppTheme.primaryTextColor(context),
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                height: 1.7,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              dailyAyah.reference,
              style: TextStyle(
                color: AppTheme.mutedTextColor(context),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _DailyAyah _dailyAyah() {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final seedDay = DateTime(2024, 1, 1);
    final daysSinceSeed = day.difference(seedDay).inDays;
    final totalVerses = [
      for (var surah = 1; surah <= 114; surah++) quran.getVerseCount(surah),
    ].fold<int>(0, (sum, count) => sum + count);

    var verseOffset = daysSinceSeed.remainder(totalVerses);
    for (var surah = 1; surah <= 114; surah++) {
      final verseCount = quran.getVerseCount(surah);
      if (verseOffset < verseCount) {
        final ayah = verseOffset + 1;
        return _DailyAyah(
          surah: surah,
          ayah: ayah,
          text: quran.getVerse(surah, ayah),
          reference: 'سورة ${quran.getSurahNameArabic(surah)} • آية $ayah',
        );
      }
      verseOffset -= verseCount;
    }

    return _DailyAyah(
      surah: 65,
      ayah: 3,
      text: quran.getVerse(65, 3),
      reference: 'سورة ${quran.getSurahNameArabic(65)} • آية 3',
    );
  }

  Widget _buildSectionHeader(
    String title, {
    String? action,
    VoidCallback? onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (action != null)
          InkWell(
            onTap: onActionTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                action,
          style: const TextStyle(
            color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.9,
      children: [
        _buildServiceItem(
          Icons.schedule_rounded,
          'مواقيت الصلاة',
          'الفجر إلى العشاء',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrayerTimesScreen()),
          ),
        ),
        _buildServiceItem(
          Icons.menu_book_rounded,
          'القرآن الكريم',
          'تلاوة وترجمة',
          onTap: _openSurahList,
        ),
        _buildServiceItem(
          Icons.access_time_filled_rounded,
          'الأذكار',
          'تحصين المسلم',
          onTap: () {
            final onSelectMainTab = widget.onSelectMainTab;
            if (onSelectMainTab != null) {
              onSelectMainTab(3);
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdhkarScreen()),
            );
          },
        ),
        _buildServiceItem(
          Icons.explore_rounded,
          'القبلة',
          'اتجاه مكة',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QiblaScreen()),
          ),
        ),
        _buildServiceItem(
          Icons.ads_click_rounded,
          'الختمة',
          'ختم القرآن',
          onTap: _openKhatmaProgress,
        ),
      ],
    );
  }

  Widget _buildServiceItem(
    IconData icon,
    String title,
    String sub, {
    bool isLock = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isLock ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.elevatedSurfaceColor(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(AppTheme.isDark(context) ? 0.14 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppTheme.primaryColor, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    sub,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.mutedTextColor(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isLock)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurfaceColor(context).withOpacity(0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(Icons.lock_outline, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingProgressCards() {
    final khatma = _khatmaProgress;
    final hasKhatmaPlan = khatma?.hasPlan == true;
    final nextPage = khatma?.nextPage;
    final lastRead = _lastRead;

    return Column(
      children: [
        _buildProgressCard(
          hasKhatmaPlan ? 'متابعة الختمة' : 'ابدأ الختمة',
          hasKhatmaPlan
              ? nextPage == null
                    ? 'الختمة مكتملة'
                    : 'اليوم ${khatma!.currentDay} • الصفحة $nextPage'
              : 'اختر خطة الختمة',
          Icons.layers_rounded,
          const Color(0xFF1B3D2F),
          subtitle: hasKhatmaPlan
              ? '${khatma!.completedCount}/604 صفحة مقروءة'
              : '15 أو 30 أو 60 يوم',
          type: 'khatmah',
          onTap: _openKhatma,
          actionLabel: hasKhatmaPlan ? 'فتح الموضع' : 'اختيار خطة',
          actionIcon: hasKhatmaPlan
              ? Icons.open_in_new_rounded
              : Icons.flag_rounded,
        ),
        const SizedBox(height: 16),
        _buildProgressCard(
          'آخر ما قرأت',
          lastRead == null
              ? 'ابدأ القراءة'
              : 'سورة ${quran.getSurahNameArabic(lastRead.surah)}',
          Icons.book_rounded,
          const Color(0xFF1B3D2F),
          subtitle: lastRead == null
              ? 'اختر سورة من القائمة'
              : 'توقفت عند الآية ${lastRead.ayah}',
          type: 'last_read',
          onTap: _openLastRead,
        ),
      ],
    );
  }

  Widget _buildProgressCard(
    String title,
    String main,
    IconData icon,
    Color bg, {
    String? subtitle,
    required String type,
    VoidCallback? onTap,
    String? actionLabel,
    IconData? actionIcon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: [bg, bg.withOpacity(0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          main,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.secondaryColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (actionLabel != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            actionIcon ?? Icons.open_in_new_rounded,
                            color: Colors.purpleAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            actionLabel,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Icon(
                icon,
                color: type == 'last_read'
                    ? AppTheme.secondaryColor
                    : Colors.purpleAccent,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
