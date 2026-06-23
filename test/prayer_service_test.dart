import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/habous_prayer_times_service.dart';
import 'package:quran_app/core/prayer_service.dart';

void main() {
  group('Prayer location routing', () {
    test('detects Moroccan and non-Moroccan coordinates', () {
      expect(
        PrayerService.isInMorocco(Coordinates(33.5731, -7.5898)),
        isTrue,
      );
      expect(
        PrayerService.isInMorocco(Coordinates(23.6848, -15.9580)),
        isTrue,
      );
      expect(
        PrayerService.isInMorocco(Coordinates(48.8566, 2.3522)),
        isFalse,
      );
      expect(
        PrayerService.isInMorocco(Coordinates(40.7128, -74.0060)),
        isFalse,
      );
    });

    test('uses local GPS calculation outside Morocco instead of Habous', () async {
      final date = DateTime(2026, 6, 18);
      final location = PrayerLocation(
        coordinates: Coordinates(48.8566, 2.3522),
        name: 'Paris',
        accuracy: 10,
      );

      final display = await HabousPrayerTimesService.getTodayPrayerTimes(
        location,
        date: date,
      ).timeout(const Duration(seconds: 3));

      final expectedTimes = PrayerService.getPrayerTimes(
        location.coordinates,
        date,
      );
      final displayTimes = {
        for (final item in display.prayers) item.prayer: item.time,
      };

      expect(display.isOfficial, isFalse);
      expect(display.cityName, 'Paris');
      expect(displayTimes[Prayer.fajr], _formatTime(expectedTimes.fajr));
      expect(displayTimes[Prayer.sunrise], _formatTime(expectedTimes.sunrise));
      expect(displayTimes[Prayer.dhuhr], _formatTime(expectedTimes.dhuhr));
      expect(displayTimes[Prayer.asr], _formatTime(expectedTimes.asr));
      expect(displayTimes[Prayer.maghrib], _formatTime(expectedTimes.maghrib));
      expect(displayTimes[Prayer.isha], _formatTime(expectedTimes.isha));
    });
  });
}

String _formatTime(DateTime dateTime) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}';
}
