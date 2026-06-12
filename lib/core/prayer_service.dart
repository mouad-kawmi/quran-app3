import 'dart:async';
import 'dart:math';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerMoment {
  const PrayerMoment(this.prayer, this.time);

  final Prayer prayer;
  final DateTime time;
}

class PrayerLocation {
  const PrayerLocation({
    required this.coordinates,
    required this.name,
    required this.accuracy,
    this.isFallback = false,
    this.isStored = false,
    this.notice,
    this.noticeKey,
  });

  final Coordinates coordinates;
  final String name;
  final double accuracy;
  final bool isFallback;
  final bool isStored;
  final String? notice;
  final String? noticeKey; // For localization key mapping
}

class PrayerSchedule {
  const PrayerSchedule({
    this.times,
    required this.nextPrayer,
    required this.previousPrayer,
  });

  final PrayerTimes? times;
  final PrayerMoment nextPrayer;
  final PrayerMoment previousPrayer;

  Duration timeUntilNextPrayer(DateTime now) {
    final remaining = nextPrayer.time.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double progress(DateTime now) {
    final total = nextPrayer.time.difference(previousPrayer.time).inSeconds;
    if (total <= 0) {
      return 0;
    }

    final elapsed = now.difference(previousPrayer.time).inSeconds;
    return min(max(elapsed / total, 0), 1);
  }
}

class PrayerLocationException implements Exception {
  const PrayerLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PrayerService {
  // Constants for storage keys
  static const Duration quickLocationTimeout = Duration(seconds: 4);
  static const Duration preciseLocationTimeout = Duration(seconds: 8);
  static const String _storedLatitudeKey = 'last_prayer_location_latitude';
  static const String _storedLongitudeKey = 'last_prayer_location_longitude';
  static const String _storedNameKey = 'last_prayer_location_name';
  static const String _storedAccuracyKey = 'last_prayer_location_accuracy';

  // Note: fallbackCityName will now use localization when accessed from UI
  @Deprecated('Use l10n.fallbackCityName instead')
  static const String fallbackCityName = 'الرباط';

  static Coordinates get fallbackCoordinates => Coordinates(34.0209, -6.8416);

  static PrayerLocation getFallbackLocation({String? cityName}) =>
      PrayerLocation(
        coordinates: fallbackCoordinates,
        name: cityName ?? 'الرباط',
        accuracy: 0,
        isFallback: true,
        noticeKey: 'fallback',
      );

  static PrayerLocation get fallbackLocation => getFallbackLocation();

  static Future<PrayerLocation> getBestAvailableLocation({
    Duration timeout = quickLocationTimeout,
  }) async {
    try {
      final location = await getDeviceLocation(timeout: timeout);
      await saveLocation(location);
      return location;
    } on PrayerLocationException {
      return await _storedLocationOrFallback();
    } catch (_) {
      return await _storedLocationOrFallback();
    }
  }

  static Future<void> saveLocation(PrayerLocation location) async {
    if (location.isFallback) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_storedLatitudeKey, location.coordinates.latitude);
    await prefs.setDouble(_storedLongitudeKey, location.coordinates.longitude);
    await prefs.setString(_storedNameKey, location.name);
    await prefs.setDouble(_storedAccuracyKey, location.accuracy);
  }

  static Future<PrayerLocation?> loadStoredLocation({String? notice}) async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_storedLatitudeKey);
    final longitude = prefs.getDouble(_storedLongitudeKey);
    if (latitude == null || longitude == null) {
      return null;
    }

    final nearestName = _nearestCityName(latitude, longitude);
    final storedName = prefs.getString(_storedNameKey);
    final name = nearestName == _currentLocationName
        ? _arabicCityName(storedName) ?? nearestName
        : nearestName;
    return PrayerLocation(
      coordinates: Coordinates(latitude, longitude),
      name: name,
      accuracy: prefs.getDouble(_storedAccuracyKey) ?? 0,
      isStored: true,
      notice:
          notice ??
          'المواقيت محسوبة على آخر موقع محفوظ. يعمل التطبيق دون خدمة الموقع ودون إنترنت.',
    );
  }

  static Future<PrayerLocation> _storedLocationOrFallback() async {
    final storedLocation = await loadStoredLocation(
      notice:
          'المواقيت معتمدة على آخر موقع محفوظ لأن خدمة الموقع غير متاحة الآن. يعمل التطبيق دون إنترنت.',
    );
    return storedLocation ?? fallbackLocation;
  }

  static Future<PrayerLocation> getDeviceLocation({
    Duration timeout = quickLocationTimeout,
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const PrayerLocationException(
        'فعّل خدمة الموقع لحساب المواقيت حسب مدينتك.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const PrayerLocationException(
        'يحتاج التطبيق إلى إذن الموقع لعرض المواقيت الصحيحة.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PrayerLocationException(
        'إذن الموقع مرفوض بشكل دائم. افتح إعدادات الهاتف وفعّل الإذن للتطبيق.',
      );
    }

    final lastKnown = await Geolocator.getLastKnownPosition();

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: timeout,
      );
      return _locationFromPosition(position);
    } on TimeoutException {
      if (lastKnown != null) {
        return _locationFromPosition(lastKnown);
      }
      throw const PrayerLocationException(
        'تعذر الحصول على الموقع الآن. فعّل خدمة الموقع وحاول مرة أخرى.',
      );
    }
  }

  static PrayerSchedule getSchedule(Coordinates coordinates, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final todayTimes = getPrayerTimes(coordinates, currentTime);
    final tomorrowTimes = getPrayerTimes(
      coordinates,
      currentTime.add(const Duration(days: 1)),
    );
    final yesterdayTimes = getPrayerTimes(
      coordinates,
      currentTime.subtract(const Duration(days: 1)),
    );

    final todayMoments = _prayerMoments(todayTimes);
    final tomorrowFajr = PrayerMoment(Prayer.fajr, tomorrowTimes.fajr);
    final nextPrayer = [...todayMoments, tomorrowFajr].firstWhere(
      (moment) => moment.time.isAfter(currentTime),
      orElse: () => tomorrowFajr,
    );

    final previousCandidates = [
      PrayerMoment(Prayer.isha, yesterdayTimes.isha),
      ...todayMoments,
    ].where((moment) => !moment.time.isAfter(currentTime)).toList();

    return PrayerSchedule(
      times: todayTimes,
      nextPrayer: nextPrayer,
      previousPrayer: previousCandidates.last,
    );
  }

  static PrayerTimes getPrayerTimes(Coordinates coordinates, DateTime date) {
    final params = CalculationParameters(
      fajrAngle: 19,
      ishaAngle: 17,
      method: CalculationMethod.other,
    )..madhab = Madhab.shafi;

    return PrayerTimes(coordinates, DateComponents.from(date), params);
  }

  static String getPrayerName(Prayer prayer, [AppLocalizations? l10n]) {
    if (l10n != null) {
      switch (prayer) {
        case Prayer.fajr:
          return l10n.prayerFajr;
        case Prayer.dhuhr:
          return l10n.prayerDhuhr;
        case Prayer.asr:
          return l10n.prayerAsr;
        case Prayer.maghrib:
          return l10n.prayerMaghrib;
        case Prayer.isha:
          return l10n.prayerIsha;
        case Prayer.sunrise:
          return l10n.prayerSunrise;
        case Prayer.none:
          return '--';
      }
    }
    // Fallback to Arabic names
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.none:
        return '--';
    }
  }

  static String getLocalizedLocationNotice(
    BuildContext context,
    PrayerLocation location,
  ) {
    final l10n = AppLocalizations.of(context)!;

    // Use noticeKey if available
    if (location.noticeKey != null) {
      switch (location.noticeKey) {
        case 'fallback':
          return l10n.fallbackLocationNotice;
        case 'stored':
          return l10n.storedLocationNotice;
        case 'unavailable':
          return l10n.unavailableLocationNotice;
        default:
          break;
      }
    }

    // Fallback to detecting from notice string
    if (location.notice?.contains('المواقيت محسوبة الآن على الرباط') ?? false) {
      return l10n.fallbackLocationNotice;
    } else if (location.notice?.contains(
          'آخر موقع محفوظ. يعمل التطبيق دون خدمة الموقع ودون إنترنت',
        ) ??
        false) {
      return l10n.storedLocationNotice;
    } else if (location.notice?.contains(
          'آخر موقع محفوظ لأن خدمة الموقع غير متاحة',
        ) ??
        false) {
      return l10n.unavailableLocationNotice;
    }

    return location.notice ?? l10n.fallbackLocationNotice;
  }

  static String getLocalizedLocationError(
    BuildContext context,
    String? errorMessage,
  ) {
    final l10n = AppLocalizations.of(context)!;

    if (errorMessage?.contains('فعّل خدمة الموقع') ?? false) {
      return l10n.locationServiceDisabled;
    } else if (errorMessage?.contains('إذن الموقع') ?? false) {
      if (errorMessage?.contains('مرفوض بشكل دائم') ?? false) {
        return l10n.locationPermissionDenied;
      }
      return l10n.locationPermissionNeeded;
    } else if (errorMessage?.contains('تعذر الحصول على الموقع') ?? false) {
      return l10n.locationTimeoutError;
    }

    return errorMessage ?? l10n.prayerTimesError;
  }

  static String getHijriDate([String locale = 'ar']) {
    final hDate = HijriCalendar.now();
    
    if (locale == 'fr') {
      const frMonths = ['Mouharram', 'Safar', 'Rabiʻ I', 'Rabiʻ II', 'Joumada I', 'Joumada II', 'Rajab', 'Chaabane', 'Ramadan', 'Chaouwal', 'Dhou al-Qiʻdah', 'Dhou al-Hijjah'];
      final monthName = hDate.hMonth >= 1 && hDate.hMonth <= 12 ? frMonths[hDate.hMonth - 1] : '';
      return '${hDate.hDay} $monthName ${hDate.hYear}';
    } else if (locale == 'en') {
      const enMonths = ['Muharram', 'Safar', 'Rabiʻ I', 'Rabiʻ II', 'Jumada I', 'Jumada II', 'Rajab', 'Shaʻban', 'Ramadan', 'Shawwal', 'Dhu al-Qiʻdah', 'Dhu al-Hijjah'];
      final monthName = hDate.hMonth >= 1 && hDate.hMonth <= 12 ? enMonths[hDate.hMonth - 1] : '';
      return '${hDate.hDay} $monthName ${hDate.hYear}';
    }

    final monthName = _hijriMonthName(hDate.hMonth);
    return toWesternDigits('${hDate.hDay} $monthName ${hDate.hYear}');
  }

  static String toWesternDigits(String value) {
    const digitMap = {
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
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };

    var normalized = value;
    for (final entry in digitMap.entries) {
      normalized = normalized.replaceAll(entry.key, entry.value);
    }
    return normalized;
  }

  static String formatDuration(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(safeDuration.inHours);
    final minutes = twoDigits(safeDuration.inMinutes.remainder(60));
    final seconds = twoDigits(safeDuration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  static PrayerLocation _locationFromPosition(Position position) {
    final coordinates = Coordinates(position.latitude, position.longitude);
    return PrayerLocation(
      coordinates: coordinates,
      name: _nearestCityName(position.latitude, position.longitude),
      accuracy: position.accuracy,
    );
  }

  static List<PrayerMoment> prayerMoments(PrayerTimes times) {
    return [
      PrayerMoment(Prayer.fajr, times.fajr),
      PrayerMoment(Prayer.dhuhr, times.dhuhr),
      PrayerMoment(Prayer.asr, times.asr),
      PrayerMoment(Prayer.maghrib, times.maghrib),
      PrayerMoment(Prayer.isha, times.isha),
    ];
  }

  static List<PrayerMoment> _prayerMoments(PrayerTimes times) {
    return prayerMoments(times);
  }

  static String _nearestCityName(double latitude, double longitude) {
    _KnownCity? closestCity;
    var closestDistance = double.infinity;

    for (final city in _moroccanCities) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        city.latitude,
        city.longitude,
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        closestCity = city;
      }
    }

    if (closestCity != null && closestDistance <= 45000) {
      return closestCity.name;
    }

    return _currentLocationName;
  }

  static const List<_KnownCity> _moroccanCities = [
    _KnownCity('الدار البيضاء', 33.5731, -7.5898),
    _KnownCity('سيدي رحال', 33.4777, -7.9523),
    _KnownCity('طنجة', 35.7595, -5.8340),
    _KnownCity('الرباط', 34.0209, -6.8416),
    _KnownCity('سلا', 34.0331, -6.7985),
    _KnownCity('فاس', 34.0181, -5.0078),
    _KnownCity('مراكش', 31.6295, -7.9811),
    _KnownCity('أكادير', 30.4278, -9.5981),
    _KnownCity('مكناس', 33.8935, -5.5473),
    _KnownCity('وجدة', 34.6814, -1.9086),
    _KnownCity('القنيطرة', 34.2610, -6.5802),
    _KnownCity('تطوان', 35.5785, -5.3684),
    _KnownCity('المحمدية', 33.6861, -7.3829),
    _KnownCity('الجديدة', 33.2316, -8.5007),
    _KnownCity('الناظور', 35.1681, -2.9335),
    _KnownCity('آسفي', 32.2994, -9.2372),
    _KnownCity('بني ملال', 32.3373, -6.3498),
    _KnownCity('خريبكة', 32.8860, -6.9209),
    _KnownCity('تازة', 34.2133, -4.0100),
    _KnownCity('سطات', 33.0010, -7.6166),
    _KnownCity('برشيد', 33.2655, -7.5875),
    _KnownCity('العرائش', 35.1932, -6.1557),
    _KnownCity('القصر الكبير', 35.0004, -5.9038),
    _KnownCity('الصويرة', 31.5085, -9.7595),
    _KnownCity('ورزازات', 30.9335, -6.9370),
    _KnownCity('الرشيدية', 31.9314, -4.4244),
    _KnownCity('العيون', 27.1536, -13.2033),
    _KnownCity('الداخلة', 23.6848, -15.9580),
    _KnownCity('الحسيمة', 35.2493, -3.9371),
    _KnownCity('شفشاون', 35.1714, -5.2697),
    _KnownCity('إفران', 33.5228, -5.1106),
    _KnownCity('تيزنيت', 29.6974, -9.7316),
    _KnownCity('تارودانت', 30.4703, -8.8770),
    _KnownCity('كلميم', 28.9870, -10.0574),
    _KnownCity('تاوريرت', 34.4073, -2.8973),
  ];

  static const String _currentLocationName = 'موقعي الحالي';

  static String _hijriMonthName(int month) {
    const months = [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ];

    if (month < 1 || month > months.length) {
      return '';
    }
    return months[month - 1];
  }

  static String? _arabicCityName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return null;
    }

    final normalized = name.trim().toLowerCase();
    return _latinCityNames[normalized] ?? name;
  }

  static String getLocalizedCityName(BuildContext context, String arabicName) {
    if (arabicName == _currentLocationName) {
       return AppLocalizations.of(context)!.location;
    }
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ar') return arabicName;
    
    for (final entry in _latinCityNames.entries) {
      if (entry.value == arabicName) {
        return entry.key.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
      }
    }
    return arabicName;
  }

  static const Map<String, String> _latinCityNames = {
    'casablanca': 'الدار البيضاء',
    'sidi rahal': 'سيدي رحال',
    'tanger': 'طنجة',
    'rabat': 'الرباط',
    'salé': 'سلا',
    'sale': 'سلا',
    'fès': 'فاس',
    'fes': 'فاس',
    'marrakech': 'مراكش',
    'agadir': 'أكادير',
    'meknès': 'مكناس',
    'meknes': 'مكناس',
    'oujda': 'وجدة',
    'kénitra': 'القنيطرة',
    'kenitra': 'القنيطرة',
    'tétouan': 'تطوان',
    'tetouan': 'تطوان',
    'mohammedia': 'المحمدية',
    'el jadida': 'الجديدة',
    'nador': 'الناظور',
    'safi': 'آسفي',
    'béni mellal': 'بني ملال',
    'beni mellal': 'بني ملال',
    'khouribga': 'خريبكة',
    'taza': 'تازة',
    'settat': 'سطات',
    'berrechid': 'برشيد',
    'larache': 'العرائش',
    'ksar el kebir': 'القصر الكبير',
    'essaouira': 'الصويرة',
    'ouarzazate': 'ورزازات',
    'errachidia': 'الرشيدية',
    'laâyoune': 'العيون',
    'laayoune': 'العيون',
    'dakhla': 'الداخلة',
    'al hoceima': 'الحسيمة',
    'chefchaouen': 'شفشاون',
    'ifrane': 'إفران',
    'tiznit': 'تيزنيت',
    'taroudant': 'تارودانت',
    'guelmim': 'كلميم',
    'taourirt': 'تاوريرت',
  };
}

class _KnownCity {
  const _KnownCity(this.name, this.latitude, this.longitude);

  final String name;
  final double latitude;
  final double longitude;
}
