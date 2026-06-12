import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:quran_app/core/habous_prayer_times_service.dart';
import 'package:quran_app/core/prayer_service.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/l10n/app_localizations.dart';

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
      final times = await HabousPrayerTimesService.getTodayPrayerTimes(location);
      if (!mounted) return;
      setState(() {
        _times = times;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = AppLocalizations.of(context)!.prayerTimesError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.prayerTimes,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            onPressed: _isLoading ? null : _loadPrayerTimes,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _times == null) {
      return _buildErrorState(l10n);
    }

    final times = _times!;
    return RefreshIndicator(
      onRefresh: _loadPrayerTimes,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(times, l10n),
          if (times.notice != null) ...[
            const SizedBox(height: 14),
            _buildNotice(times.notice!),
          ],
          const SizedBox(height: 18),
          ...times.prayers.map(_buildPrayerRow),
          const SizedBox(height: 18),
          _buildSourceNote(times, l10n),
        ],
      ),
    );
  }

  Widget _buildHeader(PrayerTimesDisplay times, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).languageCode;
    final dateLocale = locale == 'ar' ? 'ar' : (locale == 'fr' ? 'fr' : 'en');
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
              const Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  PrayerService.getLocalizedCityName(context, times.cityName),
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
            locale == 'ar'
                ? PrayerService.toWesternDigits(
                    DateFormat('EEEE، d MMMM yyyy', 'ar').format(times.date))
                : DateFormat('EEEE, d MMMM yyyy', dateLocale).format(times.date),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              times.isOfficial
                  ? l10n.officialSource(locale == 'en' ? 'Ministry of Awqaf' : (locale == 'fr' ? 'Ministère des Habous' : times.sourceName))
                  : (locale == 'en' ? 'Local Calculation' : (locale == 'fr' ? 'Calcul Local' : times.sourceName)),
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

  String _getLocalizedNotice(BuildContext context, String arabicNotice) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') return arabicNotice;

    String text = arabicNotice;
    if (locale == 'en') {
      text = text.replaceAll('المواقيت محسوبة على آخر موقع محفوظ.', 'Times are calculated for the last saved location.');
      text = text.replaceAll('المواقيت معتمدة على آخر موقع محفوظ لأن خدمة الموقع غير متاحة الآن.', 'Times are based on the last saved location as location service is unavailable now.');
      text = text.replaceAll('يعمل التطبيق دون خدمة الموقع ودون إنترنت.', 'The app works without location service or internet.');
      text = text.replaceAll('يعمل التطبيق دون إنترنت.', 'The app works without internet.');
      text = text.replaceAll('المواقيت محسوبة محليا وتعمل دون إنترنت.', 'Times calculated locally, works offline.');
      text = text.replaceAll('تعذر جلب مواقيت الوزارة الآن، لذلك تم استعمال الحساب المحلي.', 'Could not fetch official times, local calculation used.');
      text = text.replaceAll('استعملنا آخر موقع محفوظ', 'Used last saved location');
      text = text.replaceAll('، والمواقيت الرسمية من أقرب مدينة متاحة في موقع وزارة الأوقاف:', '— official times from the nearest available city:');
      text = text.replaceAll('المواقيت الرسمية من أقرب مدينة متاحة في موقع وزارة الأوقاف:', 'Official times from the nearest available city:');
    } else if (locale == 'fr') {
      text = text.replaceAll('المواقيت محسوبة على آخر موقع محفوظ.', 'Les heures sont calculées pour le dernier emplacement enregistré.');
      text = text.replaceAll('المواقيت معتمدة على آخر موقع محفوظ لأن خدمة الموقع غير متاحة الآن.', 'Les heures sont basées sur le dernier emplacement enregistré car le service de localisation n\'est pas disponible.');
      text = text.replaceAll('يعمل التطبيق دون خدمة الموقع ودون إنترنت.', 'L\'application fonctionne sans service de localisation ou Internet.');
      text = text.replaceAll('يعمل التطبيق دون إنترنت.', 'L\'application fonctionne sans Internet.');
      text = text.replaceAll('المواقيت محسوبة محليا وتعمل دون إنترنت.', 'Temps calculés localement, fonctionne hors ligne.');
      text = text.replaceAll('تعذر جلب مواقيت الوزارة الآن، لذلك تم استعمال الحساب المحلي.', 'Impossible d\'obtenir les temps officiels, calcul local utilisé.');
      text = text.replaceAll('استعملنا آخر موقع محفوظ', 'Dernier emplacement utilisé');
      text = text.replaceAll('، والمواقيت الرسمية من أقرب مدينة متاحة في موقع وزارة الأوقاف:', ' — temps officiels de la ville la plus proche :');
      text = text.replaceAll('المواقيت الرسمية من أقرب مدينة متاحة في موقع وزارة الأوقاف:', 'Temps officiels de la ville la plus proche :');
    }

    for (final word in text.split(' ')) {
      final clean = word.replaceAll(RegExp(r'[()\.:،]'), '');
      if (clean.isEmpty) continue;
      final mapped = PrayerService.getLocalizedCityName(context, clean);
      if (mapped != clean) {
        text = text.replaceAll(clean, mapped);
      }
    }
    
    return text;
  }

  Widget _buildNotice(String notice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.secondaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.secondaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _getLocalizedNotice(context, notice),
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
            color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.14 : 0.03),
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
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(_iconForPrayer(item), color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              PrayerService.getPrayerName(item.prayer, AppLocalizations.of(context)),
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

  Widget _buildSourceNote(PrayerTimesDisplay times, AppLocalizations l10n) {
    return Text(
      times.isOfficial ? l10n.officialSourceNote : l10n.fallbackSourceNote,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppTheme.mutedTextColor(context),
        fontSize: 12,
        height: 1.5,
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
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
              label: Text(l10n.retry),
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
