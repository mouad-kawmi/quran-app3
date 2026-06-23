import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:adhan/adhan.dart';
import 'package:http/http.dart' as http;
import 'package:quran_app/core/prayer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimesDisplay {
  const PrayerTimesDisplay({
    required this.cityName,
    required this.sourceName,
    required this.date,
    required this.prayers,
    required this.isOfficial,
    required this.notice,
  });

  final String cityName;
  final String sourceName;
  final DateTime date;
  final List<PrayerTimeDisplayItem> prayers;
  final bool isOfficial;
  final String? notice;
}

class PrayerTimeDisplayItem {
  const PrayerTimeDisplayItem({
    required this.prayer,
    required this.name,
    required this.time,
  });

  final Prayer prayer;
  final String name;
  final String time;
}

class HabousPrayerTimesService {
  static const String officialSourceName = 'وزارة الأوقاف والشؤون الإسلامية';
  static const String localSourceName = 'الحساب المحلي';
  static const Duration _requestTimeout = Duration(seconds: 12);
  static const String _cachePrefix = 'habous_prayer_times';
  static const Map<String, String> _requestHeaders = {
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'ar,fr;q=0.9,en;q=0.8',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/125.0 Mobile Safari/537.36',
  };
  static const List<String> _officialHosts = [
    'www.habous.gov.ma',
    'habous.gov.ma',
  ];
  static final Map<int, Future<String>> _officialHtmlRequests = {};
  static final Map<String, Future<String>> _officialDailyRequests = {};
  static Future<Map<String, _HabousCityOption>>? _officialCityOptionsRequest;

  static bool _shouldUseLocalImmediately(PrayerLocation location) {
    return !location.coordinates.latitude.isFinite ||
        !location.coordinates.longitude.isFinite;
  }

  static Future<PrayerTimesDisplay> getTodayPrayerTimes(
    PrayerLocation location, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();

    if (_shouldUseLocalImmediately(location)) {
      return _localTimes(location, targetDate).copyWith(
        notice: location.notice ?? 'المواقيت محسوبة محليا وتعمل دون إنترنت.',
      );
    }

    if (!PrayerService.isInMorocco(location.coordinates)) {
      return _localTimes(location, targetDate).copyWith(
        notice: location.notice,
      );
    }

    final city = await _resolveOfficialCity(location);
    final cachedTimes = await _loadCachedTimes(city, targetDate);
    final shouldRefreshBeforeCache = _isSameDate(targetDate, DateTime.now());
    if (!shouldRefreshBeforeCache && cachedTimes != null) {
      return cachedTimes.copyWith(notice: location.notice);
    }

    try {
      final officialTimes = await _fetchOfficialTimes(city, targetDate);
      await _saveCachedTimes(city, targetDate, officialTimes.prayers);
      return officialTimes.copyWith(notice: _officialNotice(location, city));
    } catch (_) {
      if (cachedTimes != null) {
        return cachedTimes.copyWith(notice: location.notice);
      }
      return _localTimes(location, targetDate).copyWith(
        notice:
            location.notice ??
            'تعذر جلب مواقيت الوزارة الآن، لذلك تم استعمال الحساب المحلي.',
      );
    }
  }

  static Future<List<PrayerMoment>> getPrayerMoments(
    PrayerLocation location,
    DateTime date,
  ) async {
    final display = await getTodayPrayerTimes(location, date: date);
    return momentsFromDisplay(display);
  }

  static Future<void> prefetchOfficialTimes(PrayerLocation location) async {
    if (_shouldUseLocalImmediately(location) ||
        !PrayerService.isInMorocco(location.coordinates)) {
      return;
    }

    final city = await _resolveOfficialCity(location);
    final html = await _fetchOfficialHtml(city);
    await _saveMonthCachedTimes(city, DateTime.now(), html);

    try {
      final todayPrayers = _parseDailyPrayerTimes(
        await _fetchOfficialDailyHtml(city, DateTime.now()),
      );
      if (todayPrayers != null) {
        await _saveCachedTimes(city, DateTime.now(), todayPrayers);
      }
    } catch (_) {
      // The monthly page cache remains enough for offline scheduling.
    }
  }

  static Future<PrayerSchedule> getPrayerSchedule(
    PrayerLocation location, {
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final todayMoments = await getPrayerMoments(location, currentTime);
    final tomorrowMoments = await getPrayerMoments(
      location,
      currentTime.add(const Duration(days: 1)),
    );
    final yesterdayMoments = await getPrayerMoments(
      location,
      currentTime.subtract(const Duration(days: 1)),
    );

    final tomorrowFajr = tomorrowMoments.firstWhere(
      (moment) => moment.prayer == Prayer.fajr,
      orElse: () {
        final localTimes = PrayerService.getPrayerTimes(
          location.coordinates,
          currentTime.add(const Duration(days: 1)),
        );
        return PrayerMoment(Prayer.fajr, localTimes.fajr);
      },
    );
    final nextPrayer = [...todayMoments, tomorrowFajr].firstWhere(
      (moment) => moment.time.isAfter(currentTime),
      orElse: () => tomorrowFajr,
    );

    final previousCandidates = [
      ...yesterdayMoments.where((moment) => moment.prayer == Prayer.isha),
      ...todayMoments,
    ].where((moment) => !moment.time.isAfter(currentTime)).toList();
    final previousPrayer = previousCandidates.isEmpty
        ? todayMoments.first
        : previousCandidates.last;

    return PrayerSchedule(
      nextPrayer: nextPrayer,
      previousPrayer: previousPrayer,
    );
  }

  static Future<PrayerTimesDisplay> _fetchOfficialTimes(
    _HabousCity city,
    DateTime date,
  ) async {
    List<PrayerTimeDisplayItem>? prayers;

    if (_isSameDate(date, DateTime.now())) {
      try {
        prayers = _parseDailyPrayerTimes(
          await _fetchOfficialDailyHtml(city, date),
        );
      } catch (_) {
        prayers = null;
      }
    }

    if (prayers == null) {
      final html = await _fetchOfficialHtml(city);
      await _saveMonthCachedTimes(city, date, html);
      prayers = _parsePrayerRow(html, date);
    }
    if (prayers == null) {
      throw const FormatException('No prayer row found in Habous response');
    }

    return PrayerTimesDisplay(
      cityName: city.name,
      sourceName: officialSourceName,
      date: date,
      prayers: prayers,
      isOfficial: true,
      notice: null,
    );
  }

  static Future<String> _fetchOfficialDailyHtml(
    _HabousCity city,
    DateTime date,
  ) async {
    final requestKey = '${city.id}_${_dateKey(date)}';
    final cachedRequest = _officialDailyRequests[requestKey];
    if (cachedRequest != null) {
      return cachedRequest;
    }

    final request = _fetchHabousHtml(
      '/prieres/horaire-api.php',
      {'ville': city.id.toString()},
      'Habous daily request failed',
    );
    _officialDailyRequests[requestKey] = request;

    try {
      return await request;
    } catch (_) {
      _officialDailyRequests.remove(requestKey);
      rethrow;
    }
  }

  static Future<Map<String, _HabousCityOption>> _fetchOfficialCityOptions(
    _HabousCity seedCity,
  ) async {
    final cachedRequest = _officialCityOptionsRequest;
    if (cachedRequest != null) {
      return cachedRequest;
    }

    final request = _fetchOfficialDailyHtml(seedCity, DateTime.now()).then(
      _parseOfficialCityOptions,
    );
    _officialCityOptionsRequest = request;

    try {
      return await request;
    } catch (_) {
      _officialCityOptionsRequest = null;
      rethrow;
    }
  }

  static Future<String> _fetchOfficialHtml(_HabousCity city) async {
    final cachedRequest = _officialHtmlRequests[city.id];
    if (cachedRequest != null) {
      return cachedRequest;
    }

    final request = _fetchHabousHtml(
      '/prieres/horaire_hijri_2.php',
      {'ville': city.id.toString()},
      'Habous monthly request failed',
    );
    _officialHtmlRequests[city.id] = request;

    try {
      return await request;
    } catch (_) {
      _officialHtmlRequests.remove(city.id);
      rethrow;
    }
  }

  static Future<String> _fetchHabousHtml(
    String path,
    Map<String, String> queryParameters,
    String errorContext,
  ) async {
    Object? lastError;
    for (final host in _officialHosts) {
      final uri = Uri.https(host, path, queryParameters);
      try {
        final response = await http
            .get(uri, headers: _requestHeaders)
            .timeout(_requestTimeout);
        if (response.statusCode == 200) {
          return utf8.decode(response.bodyBytes);
        }
        lastError = StateError('$errorContext: ${response.statusCode}');
      } catch (error) {
        lastError = error;
      }
    }

    for (final host in _officialHosts) {
      final uri = Uri.https(host, path, queryParameters);
      try {
        return await _fetchHabousHtmlWithRelaxedCertificate(uri);
      } catch (error) {
        lastError = error;
      }
    }

    throw StateError('$errorContext: $lastError');
  }

  static Future<String> _fetchHabousHtmlWithRelaxedCertificate(Uri uri) async {
    final client = HttpClient()
      ..connectionTimeout = _requestTimeout
      ..badCertificateCallback = (certificate, host, port) {
        return _officialHosts.contains(host);
      };

    try {
      final request = await client.getUrl(uri).timeout(_requestTimeout);
      for (final entry in _requestHeaders.entries) {
        request.headers.set(entry.key, entry.value);
      }

      final response = await request.close().timeout(_requestTimeout);
      if (response.statusCode != HttpStatus.ok) {
        throw StateError(
          'Habous relaxed request failed: ${response.statusCode}',
        );
      }

      return await utf8.decoder.bind(response).join().timeout(_requestTimeout);
    } finally {
      client.close(force: true);
    }
  }

  static String? _officialNotice(PrayerLocation location, _HabousCity city) {
    if (location.isStored && location.name != city.name) {
      return 'استعملنا آخر موقع محفوظ (${location.name})، والمواقيت الرسمية من أقرب مدينة متاحة في موقع وزارة الأوقاف: ${city.name}.';
    }

    if (location.name != city.name) {
      return 'المواقيت الرسمية من أقرب مدينة متاحة في موقع وزارة الأوقاف: ${city.name}.';
    }

    return null;
  }

  static PrayerTimesDisplay _localTimes(
    PrayerLocation location,
    DateTime date,
  ) {
    final times = PrayerService.getPrayerTimes(location.coordinates, date);
    final applyMoroccoOffset = PrayerService.isInMorocco(location.coordinates);
    return PrayerTimesDisplay(
      cityName: location.name,
      sourceName: localSourceName,
      date: date,
      isOfficial: false,
      notice: null,
      prayers: [
        PrayerTimeDisplayItem(
          prayer: Prayer.fajr,
          name: PrayerService.getPrayerName(Prayer.fajr),
          time: _formatLocalTime(times.fajr, Prayer.fajr, applyMoroccoOffset),
        ),
        PrayerTimeDisplayItem(
          prayer: Prayer.sunrise,
          name: PrayerService.getPrayerName(Prayer.sunrise),
          time: _formatLocalTime(
            times.sunrise,
            Prayer.sunrise,
            applyMoroccoOffset,
          ),
        ),
        PrayerTimeDisplayItem(
          prayer: Prayer.dhuhr,
          name: PrayerService.getPrayerName(Prayer.dhuhr),
          time: _formatLocalTime(times.dhuhr, Prayer.dhuhr, applyMoroccoOffset),
        ),
        PrayerTimeDisplayItem(
          prayer: Prayer.asr,
          name: PrayerService.getPrayerName(Prayer.asr),
          time: _formatLocalTime(times.asr, Prayer.asr, applyMoroccoOffset),
        ),
        PrayerTimeDisplayItem(
          prayer: Prayer.maghrib,
          name: PrayerService.getPrayerName(Prayer.maghrib),
          time: _formatLocalTime(
            times.maghrib,
            Prayer.maghrib,
            applyMoroccoOffset,
          ),
        ),
        PrayerTimeDisplayItem(
          prayer: Prayer.isha,
          name: PrayerService.getPrayerName(Prayer.isha),
          time: _formatLocalTime(times.isha, Prayer.isha, applyMoroccoOffset),
        ),
      ],
    );
  }

  static List<PrayerMoment> momentsFromDisplay(PrayerTimesDisplay display) {
    return display.prayers
        .where((item) => item.prayer != Prayer.sunrise)
        .map(
          (item) => PrayerMoment(
            item.prayer,
            _dateTimeForDisplayTime(display.date, item.time),
          ),
        )
        .toList();
  }

  static DateTime _dateTimeForDisplayTime(DateTime date, String time) {
    final parts = time.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid prayer time: $time');
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  static Future<PrayerTimesDisplay?> _loadCachedTimes(
    _HabousCity city,
    DateTime date,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedValue = prefs.getString(_cacheKey(city, date));
    if (cachedValue == null) {
      return null;
    }

    try {
      final data = jsonDecode(cachedValue) as Map<String, dynamic>;
      final prayerData = data['prayers'] as List<dynamic>;
      final prayers = prayerData
          .map((item) => item as Map<String, dynamic>)
          .map(
            (item) => PrayerTimeDisplayItem(
              prayer: Prayer.values[item['prayerIndex'] as int],
              name: item['name'] as String,
              time: item['time'] as String,
            ),
          )
          .toList();

      return PrayerTimesDisplay(
        cityName: city.name,
        sourceName: officialSourceName,
        date: date,
        prayers: prayers,
        isOfficial: true,
        notice: null,
      );
    } catch (_) {
      await prefs.remove(_cacheKey(city, date));
      return null;
    }
  }

  static Future<void> _saveCachedTimes(
    _HabousCity city,
    DateTime date,
    List<PrayerTimeDisplayItem> prayers,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode({
      'cityId': city.id,
      'date': _dateKey(date),
      'prayers': prayers
          .map(
            (item) => {
              'prayerIndex': item.prayer.index,
              'name': item.name,
              'time': item.time,
            },
          )
          .toList(),
    });
    await prefs.setString(_cacheKey(city, date), encoded);
  }

  static Future<void> _saveMonthCachedTimes(
    _HabousCity city,
    DateTime monthDate,
    String html,
  ) async {
    final monthTimes = _parsePrayerMonth(html, monthDate);
    if (monthTimes.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    for (final entry in monthTimes.entries) {
      final encoded = jsonEncode({
        'cityId': city.id,
        'date': _dateKey(entry.key),
        'prayers': entry.value
            .map(
              (item) => {
                'prayerIndex': item.prayer.index,
                'name': item.name,
                'time': item.time,
              },
            )
            .toList(),
      });
      await prefs.setString(_cacheKey(city, entry.key), encoded);
    }
  }

  static String _cacheKey(_HabousCity city, DateTime date) {
    return '${_cachePrefix}_${city.id}_${_dateKey(date)}';
  }

  static String _dateKey(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${date.year}${twoDigits(date.month)}${twoDigits(date.day)}';
  }

  static bool _isSameDate(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  static List<PrayerTimeDisplayItem>? _parseDailyPrayerTimes(String html) {
    final tableTimes = _parseDailyPrayerTable(html);
    if (tableTimes != null) {
      return tableTimes;
    }

    final text = _cleanCell(html);
    final fajr = _extractLabeledTime(text, const ['الفجر', 'الصبح']);
    final sunrise = _extractLabeledTime(text, const ['الشروق']);
    final dhuhr = _extractLabeledTime(text, const ['الظهر']);
    final asr = _extractLabeledTime(text, const ['العصر']);
    final maghrib = _extractLabeledTime(text, const ['المغرب']);
    final isha = _extractLabeledTime(text, const ['العشاء']);

    return _buildPrayerItems(
      fajr: fajr,
      sunrise: sunrise,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
    );
  }

  static List<PrayerTimeDisplayItem>? _parseDailyPrayerTable(String html) {
    final tableMatch = RegExp(
      r'''<table[^>]*class=["'][^"']*\bhoraire\b[^"']*["'][^>]*>(.*?)</table>''',
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(html);
    final tableHtml = tableMatch?.group(1) ?? html;
    final cells =
        RegExp(
              r'<t[dh][^>]*>(.*?)</t[dh]>',
              caseSensitive: false,
              dotAll: true,
            )
            .allMatches(tableHtml)
            .map((match) => _cleanCell(match.group(1) ?? ''))
            .where((cell) => cell.isNotEmpty)
            .toList();

    final timesByPrayer = <Prayer, String>{};
    for (var index = 0; index < cells.length - 1; index++) {
      final prayer = _prayerForLabel(cells[index]);
      final time = _cleanTime(cells[index + 1]);
      if (prayer != null && time != null) {
        timesByPrayer[prayer] = time;
        index++;
      }
    }

    return _buildPrayerItems(
      fajr: timesByPrayer[Prayer.fajr],
      sunrise: timesByPrayer[Prayer.sunrise],
      dhuhr: timesByPrayer[Prayer.dhuhr],
      asr: timesByPrayer[Prayer.asr],
      maghrib: timesByPrayer[Prayer.maghrib],
      isha: timesByPrayer[Prayer.isha],
    );
  }

  static Prayer? _prayerForLabel(String value) {
    final label = _cleanCell(value).replaceAll(RegExp(r'[\s:：]+'), '');
    if (label.contains('الفجر') || label.contains('الصبح')) {
      return Prayer.fajr;
    }
    if (label.contains('الشروق')) {
      return Prayer.sunrise;
    }
    if (label.contains('الظهر')) {
      return Prayer.dhuhr;
    }
    if (label.contains('العصر')) {
      return Prayer.asr;
    }
    if (label.contains('المغرب')) {
      return Prayer.maghrib;
    }
    if (label.contains('العشاء')) {
      return Prayer.isha;
    }
    return null;
  }

  static String? _extractLabeledTime(String text, List<String> labels) {
    for (final label in labels) {
      final escapedLabel = RegExp.escape(label);
      final directMatch = RegExp(
        '$escapedLabel\\s*[:：]?\\s*(?:\\|\\s*)*(\\d{1,2}:\\d{2})',
      ).firstMatch(text);
      if (directMatch != null) {
        return _cleanTime(directMatch.group(1)!);
      }

      final looseMatch = RegExp(
        '$escapedLabel[^0-9]{0,40}(\\d{1,2}:\\d{2})',
      ).firstMatch(text);
      if (looseMatch != null) {
        return _cleanTime(looseMatch.group(1)!);
      }
    }

    return null;
  }

  static List<PrayerTimeDisplayItem>? _parsePrayerRow(
    String html,
    DateTime date,
  ) {
    return _parsePrayerMonth(html, date)[
        DateTime(date.year, date.month, date.day)];
  }

  static Map<DateTime, List<PrayerTimeDisplayItem>> _parsePrayerMonth(
    String html,
    DateTime monthDate,
  ) {
    final parsedRows = <_ParsedPrayerRow>[];
    final parsed = <DateTime, List<PrayerTimeDisplayItem>>{};
    final rows = RegExp(
      r'<tr[^>]*>(.*?)</tr>',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);

    for (final row in rows) {
      final cells =
          RegExp(
                r'<t[dh][^>]*>(.*?)</t[dh]>',
                caseSensitive: false,
                dotAll: true,
              )
              .allMatches(row.group(1) ?? '')
              .map((match) => _cleanCell(match.group(1) ?? ''))
              .where((cell) => cell.isNotEmpty)
              .toList();

      if (cells.length < 9) {
        continue;
      }

      final gregorianDay = int.tryParse(_numbersOnly(cells[2]));
      if (gregorianDay == null ||
          gregorianDay < 1 ||
          gregorianDay >
              DateTime(monthDate.year, monthDate.month + 1, 0).day) {
        continue;
      }

      final fajr = _cleanTime(cells[3]);
      final sunrise = _cleanTime(cells[4]);
      final dhuhr = _cleanTime(cells[5]);
      final asr = _cleanTime(cells[6]);
      final maghrib = _cleanTime(cells[7]);
      final isha = _cleanTime(cells[8]);
      final prayerItems = _buildPrayerItems(
        fajr: fajr,
        sunrise: sunrise,
        dhuhr: dhuhr,
        asr: asr,
        maghrib: maghrib,
        isha: isha,
      );

      if (prayerItems == null) {
        continue;
      }

      parsedRows.add(_ParsedPrayerRow(gregorianDay, prayerItems));
    }

    if (parsedRows.isEmpty) {
      return parsed;
    }

    var monthCursor = DateTime(monthDate.year, monthDate.month);
    final firstDay = parsedRows.first.gregorianDay;
    var hasMonthRollover = false;
    for (var index = 1; index < parsedRows.length; index++) {
      if (parsedRows[index].gregorianDay <
          parsedRows[index - 1].gregorianDay) {
        hasMonthRollover = true;
        break;
      }
    }
    if (hasMonthRollover && firstDay > monthDate.day) {
      monthCursor = DateTime(monthDate.year, monthDate.month - 1);
    }

    int? previousDay;
    for (final row in parsedRows) {
      if (previousDay != null && row.gregorianDay < previousDay) {
        monthCursor = DateTime(monthCursor.year, monthCursor.month + 1);
      }
      parsed[DateTime(monthCursor.year, monthCursor.month, row.gregorianDay)] =
          row.prayers;
      previousDay = row.gregorianDay;
    }

    return parsed;
  }

  static List<PrayerTimeDisplayItem>? _buildPrayerItems({
    required String? fajr,
    required String? sunrise,
    required String? dhuhr,
    required String? asr,
    required String? maghrib,
    required String? isha,
  }) {
    if ([fajr, sunrise, dhuhr, asr, maghrib, isha].any((time) => time == null)) {
      return null;
    }

    return [
      PrayerTimeDisplayItem(
        prayer: Prayer.fajr,
        name: PrayerService.getPrayerName(Prayer.fajr),
        time: fajr!,
      ),
      PrayerTimeDisplayItem(
        prayer: Prayer.sunrise,
        name: PrayerService.getPrayerName(Prayer.sunrise),
        time: sunrise!,
      ),
      PrayerTimeDisplayItem(
        prayer: Prayer.dhuhr,
        name: PrayerService.getPrayerName(Prayer.dhuhr),
        time: dhuhr!,
      ),
      PrayerTimeDisplayItem(
        prayer: Prayer.asr,
        name: PrayerService.getPrayerName(Prayer.asr),
        time: asr!,
      ),
      PrayerTimeDisplayItem(
        prayer: Prayer.maghrib,
        name: PrayerService.getPrayerName(Prayer.maghrib),
        time: maghrib!,
      ),
      PrayerTimeDisplayItem(
        prayer: Prayer.isha,
        name: PrayerService.getPrayerName(Prayer.isha),
        time: isha!,
      ),
    ];
  }

  static String _cleanCell(String value) {
    return _normalizeDigits(value)
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#160;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? _cleanTime(String value) {
    final compact = _normalizeDigits(value).replaceAll(RegExp(r'\s+'), '');
    final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(compact);
    if (match == null) {
      return null;
    }

    final hour = match.group(1)!.padLeft(2, '0');
    final minute = match.group(2)!;
    return '$hour:$minute';
  }

  static String _numbersOnly(String value) {
    return _normalizeDigits(value).replaceAll(RegExp(r'[^0-9]'), '');
  }

  static String _normalizeDigits(String value) {
    const easternArabicDigits = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };

    var normalized = value;
    for (final entry in easternArabicDigits.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized;
  }

  static String _formatTime(DateTime dateTime) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
  }

  static String _formatLocalTime(
    DateTime dateTime,
    Prayer prayer,
    bool applyMoroccoOffset,
  ) {
    if (!applyMoroccoOffset) {
      return _formatTime(dateTime);
    }
    return _formatTime(dateTime.add(_moroccoFallbackOffset(prayer)));
  }

  static Duration _moroccoFallbackOffset(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return const Duration(minutes: 2);
      case Prayer.dhuhr:
        return const Duration(minutes: 4);
      case Prayer.asr:
        return const Duration(minutes: 1);
      case Prayer.maghrib:
        return const Duration(minutes: 4);
      case Prayer.isha:
        return const Duration(minutes: 1);
      case Prayer.sunrise:
      case Prayer.none:
        return Duration.zero;
    }
  }

  static Future<_HabousCity> _resolveOfficialCity(
    PrayerLocation location,
  ) async {
    final nearestCity = _nearestSupportedCity(location.coordinates);
    final normalizedLocationName = _normalizeCityName(location.name);
    if (normalizedLocationName.isEmpty) {
      return nearestCity;
    }

    final bundledCity = _findBundledCityByName(normalizedLocationName);
    if (bundledCity != null) {
      return bundledCity;
    }

    try {
      final officialOptions = await _fetchOfficialCityOptions(nearestCity);
      final option = officialOptions[normalizedLocationName];
      if (option != null) {
        return option.toCity(location.coordinates);
      }
    } catch (_) {
      // Keep the offline-friendly nearest-city behavior when Habous is unreachable.
    }

    return nearestCity;
  }

  static _HabousCity? _findBundledCityByName(String normalizedName) {
    for (final city in _habousCities) {
      if (_normalizeCityName(city.name) == normalizedName) {
        return city;
      }
    }
    return null;
  }

  static Map<String, _HabousCityOption> _parseOfficialCityOptions(
    String html,
  ) {
    final options = <String, _HabousCityOption>{};
    final matches = RegExp(
      r'''<option\b[^>]*\bvalue\s*=\s*["']?[^"'>]*[?&]ville=(\d+)[^>]*>(.*?)</option>''',
      caseSensitive: false,
      dotAll: true,
    ).allMatches(html);

    for (final match in matches) {
      final id = int.tryParse(match.group(1) ?? '');
      final name = _cleanCell(match.group(2) ?? '');
      final normalizedName = _normalizeCityName(name);
      if (id != null && normalizedName.isNotEmpty) {
        options[normalizedName] = _HabousCityOption(id, name);
      }
    }

    return options;
  }

  static String _normalizeCityName(String value) {
    return _cleanCell(value)
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ـ', '')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF]+'), ' ')
        .trim();
  }

  static _HabousCity _nearestSupportedCity(Coordinates coordinates) {
    _HabousCity closestCity = _habousCities.first;
    var closestDistance = double.infinity;

    for (final city in _habousCities) {
      final distance = _distanceInKm(
        coordinates.latitude,
        coordinates.longitude,
        city.latitude,
        city.longitude,
      );
      if (distance < closestDistance) {
        closestDistance = distance;
        closestCity = city;
      }
    }

    return closestCity;
  }

  static double _distanceInKm(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(latitude2 - latitude1);
    final dLon = _toRadians(longitude2 - longitude1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude1)) *
            cos(_toRadians(latitude2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  static const List<_HabousCity> _habousCities = [
    _HabousCity(1, 'الرباط', 34.0209, -6.8416),
    _HabousCity(7, 'القنيطرة', 34.2610, -6.5802),
    _HabousCity(14, 'طنجة', 35.7595, -5.8340),
    _HabousCity(15, 'تطوان', 35.5785, -5.3684),
    _HabousCity(16, 'العرائش', 35.1932, -6.1557),
    _HabousCity(18, 'شفشاون', 35.1714, -5.2697),
    _HabousCity(21, 'القصر الكبير', 35.0004, -5.9038),
    _HabousCity(23, 'الحسيمة', 35.2493, -3.9371),
    _HabousCity(31, 'وجدة', 34.6814, -1.9086),
    _HabousCity(38, 'تاوريرت', 34.4073, -2.8973),
    _HabousCity(39, 'الناظور', 35.1681, -2.9335),
    _HabousCity(58, 'الدار البيضاء', 33.5731, -7.5898),
    _HabousCity(59, 'المحمدية', 33.6861, -7.3829),
    _HabousCity(61, 'سطات', 33.0010, -7.6166),
    _HabousCity(65, 'برشيد', 33.2655, -7.5875),
    _HabousCity(66, 'الجديدة', 33.2316, -8.5007),
    _HabousCity(73, 'بني ملال', 32.3373, -6.3498),
    _HabousCity(79, 'خريبكة', 32.8860, -6.9209),
    _HabousCity(81, 'فاس', 34.0181, -5.0078),
    _HabousCity(89, 'تازة', 34.2133, -4.0100),
    _HabousCity(99, 'مكناس', 33.8935, -5.5473),
    _HabousCity(100, 'إفران', 33.5228, -5.1106),
    _HabousCity(104, 'مراكش', 31.6295, -7.9811),
    _HabousCity(106, 'الصويرة', 31.5085, -9.7595),
    _HabousCity(111, 'آسفي', 32.2994, -9.2372),
    _HabousCity(117, 'أكادير', 30.4278, -9.5981),
    _HabousCity(118, 'تارودانت', 30.4703, -8.8770),
    _HabousCity(119, 'تيزنيت', 29.6974, -9.7316),
    _HabousCity(128, 'الرشيدية', 31.9314, -4.4244),
    _HabousCity(138, 'ورزازات', 30.9335, -6.9370),
    _HabousCity(149, 'كلميم', 28.9870, -10.0574),
    _HabousCity(152, 'طانطان', 28.4380, -11.1032),
    _HabousCity(156, 'العيون', 27.1536, -13.2033),
    _HabousCity(165, 'الداخلة', 23.6848, -15.9580),
  ];
}

extension on PrayerTimesDisplay {
  PrayerTimesDisplay copyWith({String? notice}) {
    return PrayerTimesDisplay(
      cityName: cityName,
      sourceName: sourceName,
      date: date,
      prayers: prayers,
      isOfficial: isOfficial,
      notice: notice,
    );
  }
}

class _HabousCity {
  const _HabousCity(this.id, this.name, this.latitude, this.longitude);

  final int id;
  final String name;
  final double latitude;
  final double longitude;
}

class _HabousCityOption {
  const _HabousCityOption(this.id, this.name);

  final int id;
  final String name;

  _HabousCity toCity(Coordinates coordinates) {
    return _HabousCity(
      id,
      name,
      coordinates.latitude,
      coordinates.longitude,
    );
  }
}

class _ParsedPrayerRow {
  const _ParsedPrayerRow(this.gregorianDay, this.prayers);

  final int gregorianDay;
  final List<PrayerTimeDisplayItem> prayers;
}
