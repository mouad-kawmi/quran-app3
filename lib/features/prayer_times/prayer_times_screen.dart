import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:quran_app/core/habous_prayer_times_service.dart';
import 'package:quran_app/core/prayer_service.dart';
import 'package:quran_app/core/theme.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  PrayerTimesDisplay? _times;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final location = await PrayerService.getBestAvailableLocation();
      final times = await HabousPrayerTimesService.getTodayPrayerTimes(
        location,
      );
      if (!mounted) return;

      setState(() {
        _times = times;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'تعذر جلب مواقيت الصلاة الآن. حاول مرة أخرى.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'مواقيت الصلاة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _isLoading ? null : _loadPrayerTimes,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _times == null) {
      return _buildErrorState();
    }

    final times = _times!;
    return RefreshIndicator(
      onRefresh: _loadPrayerTimes,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(times),
          if (times.notice != null) ...[
            const SizedBox(height: 14),
            _buildNotice(times.notice!),
          ],
          const SizedBox(height: 18),
          ...times.prayers.map(_buildPrayerRow),
          const SizedBox(height: 18),
          _buildSourceNote(times),
        ],
      ),
    );
  }

  Widget _buildHeader(PrayerTimesDisplay times) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_filled_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  times.cityName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            PrayerService.toWesternDigits(
              DateFormat('EEEE، d MMMM yyyy', 'ar').format(times.date),
            ),
            style: TextStyle(color: Colors.white.withOpacity(0.82)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              times.isOfficial
                  ? 'مصدر رسمي: ${times.sourceName}'
                  : times.sourceName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice(String notice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.secondaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              notice,
              style: TextStyle(
                color: AppTheme.mutedTextColor(context),
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerRow(PrayerTimeDisplayItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(AppTheme.isDark(context) ? 0.14 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconForPrayer(item), color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.name,
              style: TextStyle(
                color: AppTheme.primaryTextColor(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            item.time,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: AppTheme.secondaryColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceNote(PrayerTimesDisplay times) {
    return Text(
      times.isOfficial
          ? 'المواقيت مجلوبة من صفحة/جدول وزارة الأوقاف عند توفر الاتصال.'
          : 'تعذر الاتصال بموقع الوزارة، لذلك استعملنا الحساب المحلي مؤقتاً.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppTheme.mutedTextColor(context),
        fontSize: 12,
        height: 1.5,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded, size: 76, color: Colors.grey),
            const SizedBox(height: 18),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadPrayerTimes,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForPrayer(PrayerTimeDisplayItem item) {
    switch (item.prayer) {
      case Prayer.fajr:
        return Icons.nightlight_round;
      case Prayer.sunrise:
        return Icons.wb_twilight_rounded;
      case Prayer.dhuhr:
        return Icons.wb_sunny_rounded;
      case Prayer.asr:
        return Icons.filter_drama_rounded;
      case Prayer.maghrib:
        return Icons.wb_twilight_rounded;
      case Prayer.isha:
        return Icons.dark_mode_rounded;
      case Prayer.none:
        return Icons.access_time_rounded;
    }
  }
}
