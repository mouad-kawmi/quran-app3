import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quran_app/core/prayer_service.dart';

class PrayerWidgetService {
  static const MethodChannel _channel = MethodChannel(
    'quran_app/prayer_widget',
  );

  static Future<void> update({
    required PrayerLocation location,
    required PrayerSchedule schedule,
    required List<PrayerMoment> todayMoments,
    required String hijriDate,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      final timelineMoments = _timelineMoments(location, todayMoments);

      await _channel.invokeMethod<void>('update', {
        'cityName': location.name,
        'hijriDate': hijriDate,
        'nextPrayerName': PrayerService.getPrayerName(
          schedule.nextPrayer.prayer,
        ),
        'nextPrayerMillis': schedule.nextPrayer.time.millisecondsSinceEpoch,
        'previousPrayerName': PrayerService.getPrayerName(
          schedule.previousPrayer.prayer,
        ),
        'previousPrayerMillis':
            schedule.previousPrayer.time.millisecondsSinceEpoch,
        'prayers': [
          for (final moment in todayMoments)
            _serializePrayerMoment(moment),
        ],
        'timelinePrayers': [
          for (final moment in timelineMoments) _serializePrayerMoment(moment),
        ],
      });
    } catch (_) {
      // Widgets are an Android convenience; the app should never fail because
      // the launcher refused or delayed a widget update.
    }
  }

  static String _formatTime(DateTime time) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
  }

  static List<PrayerMoment> _timelineMoments(
    PrayerLocation location,
    List<PrayerMoment> todayMoments,
  ) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowMoments = PrayerService.prayerMoments(
      PrayerService.getPrayerTimes(location.coordinates, tomorrow),
    );
    return [...todayMoments, ...tomorrowMoments];
  }

  static Map<String, Object> _serializePrayerMoment(PrayerMoment moment) {
    return {
      'name': PrayerService.getPrayerName(moment.prayer),
      'time': PrayerService.toWesternDigits(_formatTime(moment.time)),
      'millis': moment.time.millisecondsSinceEpoch,
    };
  }
}
