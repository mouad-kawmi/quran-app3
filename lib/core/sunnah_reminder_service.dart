import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:quran_app/core/prayer_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

class SunnahReminder {
  final String id;
  final String title;
  final String body;
  final String description;
  final IconData icon;
  final String iconName;
  final Color color;
  /// null = daily, 1=Monday...7=Sunday (DateTime.weekday)
  final int? weekday;
  final TimeOfDay time;
  final int notifId;

  const SunnahReminder({
    required this.id,
    required this.title,
    required this.body,
    required this.description,
    required this.icon,
    required this.color,
    required this.time,
    required this.notifId,
    required this.iconName,
    this.weekday,
  });
}

class SunnahReminderService {
  static const _prefix = 'sunnah_reminder_';

  static const List<SunnahReminder> reminders = [
    SunnahReminder(
      id: 'kahf_friday',
      title: '📖 سورة الكهف',
      body: 'اقرأ سورة الكهف اليوم — نور من الجمعة إلى الجمعة',
      description: 'من قرأ سورة الكهف يوم الجمعة أضاء له النور ما بين الجمعتين.',
      icon: Icons.menu_book_rounded,
      color: Color(0xFF004D40),
      iconName: 'ic_notif_book',
      weekday: DateTime.friday,
      time: TimeOfDay(hour: 8, minute: 0),
      notifId: 9001,
    ),
    SunnahReminder(
      id: 'mulk_night',
      title: '🌙 سورة الملك',
      body: 'اقرأ سورة الملك قبل النوم — شفيعة يوم القيامة',
      description: 'عن جابر رضي الله عنه: كان النبي ﷺ لا ينام حتى يقرأ {تبارك الذي بيده الملك}.',
      icon: Icons.nights_stay_rounded,
      color: Color(0xFF1A237E),
      iconName: 'ic_notif_moon',
      time: TimeOfDay(hour: 22, minute: 0),
      notifId: 9002,
    ),
    SunnahReminder(
      id: 'morning_adhkar',
      title: '🌅 أذكار الصباح',
      body: 'لا تنس أذكار الصباح — حصنك ليومك كله',
      description: 'أذكار الصباح درع وحصن للمسلم طوال يومه من الشياطين والبلاء.',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFF57F17),
      iconName: 'ic_notif_sun',
      time: TimeOfDay(hour: 6, minute: 30),
      notifId: 9003,
    ),
    SunnahReminder(
      id: 'evening_adhkar',
      title: '🌆 أذكار المساء',
      body: 'حان وقت أذكار المساء — أمسِ بذكر الله',
      description: 'أذكار المساء تحمي المسلم في ليله وتجدد صلته بربه.',
      icon: Icons.wb_twilight_rounded,
      color: Color(0xFFE65100),
      iconName: 'ic_notif_twilight',
      time: TimeOfDay(hour: 18, minute: 0),
      notifId: 9004,
    ),
    SunnahReminder(
      id: 'salah_nabi_friday',
      title: '💚 الصلاة على النبي ﷺ',
      body: 'أكثر من الصلاة على النبي ﷺ يوم الجمعة',
      description: 'قال ﷺ: أكثروا الصلاة عليّ يوم الجمعة وليلة الجمعة.',
      icon: Icons.favorite_rounded,
      color: Color(0xFF2E7D32),
      iconName: 'ic_notif_heart',
      weekday: DateTime.friday,
      time: TimeOfDay(hour: 12, minute: 0),
      notifId: 9005,
    ),
    SunnahReminder(
      id: 'fast_monday',
      title: '🤍 صيام الاثنين',
      body: 'اليوم يوم الاثنين — يوم صيام النبي ﷺ',
      description: 'قال ﷺ: ذاك يوم ولدتُ فيه وأُنزل عليّ فيه، فأحب أن أصوم فيه.',
      icon: Icons.no_food_rounded,
      color: Color(0xFF6A1B9A),
      iconName: 'ic_notif_calendar',
      weekday: DateTime.monday,
      time: TimeOfDay(hour: 5, minute: 30),
      notifId: 9006,
    ),
    SunnahReminder(
      id: 'fast_thursday',
      title: '🤍 صيام الخميس',
      body: 'اليوم يوم الخميس — يُعرض فيه العمل على الله',
      description: 'قال ﷺ: تُعرض الأعمال يوم الاثنين والخميس فأحب أن يُعرض عملي وأنا صائم.',
      icon: Icons.no_food_rounded,
      color: Color(0xFF6A1B9A),
      iconName: 'ic_notif_calendar',
      weekday: DateTime.thursday,
      time: TimeOfDay(hour: 5, minute: 30),
      notifId: 9007,
    ),
    SunnahReminder(
      id: 'sleep_adhkar',
      title: '😴 أذكار النوم',
      body: 'آوِ إلى فراشك بذكر الله — أنم مستريحاً',
      description: 'أذكار النوم تحمي النائم وتجعل نومه عبادة.',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF37474F),
      iconName: 'ic_notif_bed',
      time: TimeOfDay(hour: 22, minute: 30),
      notifId: 9008,
    ),
    SunnahReminder(
      id: 'quran_daily',
      title: '📚 ورد القرآن اليومي',
      body: 'خصص وقتاً لتلاوة القرآن — لا تجعل يومًا بلا قرآن',
      description: 'قال ﷺ: اقرؤوا القرآن فإنه يأتي يوم القيامة شفيعاً لأصحابه.',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF00695C),
      iconName: 'ic_notif_book',
      time: TimeOfDay(hour: 9, minute: 0),
      notifId: 9009,
    ),
  ];

  static Future<bool> isEnabled(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$id') ?? false;
  }

  static Future<void> setEnabled(SunnahReminder reminder, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix${reminder.id}', enabled);
    if (enabled) {
      await _schedule(reminder);
    } else {
      await PrayerNotificationService.cancelCustom(reminder.notifId);
    }
  }

  static Future<Map<String, bool>> loadAllStates() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final r in reminders)
        r.id: prefs.getBool('$_prefix${r.id}') ?? false,
    };
  }

  static Future<void> _schedule(SunnahReminder reminder) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = _nextOccurrence(reminder, now);

    final androidDetails = AndroidNotificationDetails(
      'sunnah_reminders',
      'تنبيهات السنن',
      channelDescription: 'تذكير يومي وأسبوعي بالسنن النبوية',
      importance: Importance.high,
      priority: Priority.high,
      color: reminder.color,
      icon: reminder.iconName,
      largeIcon: const DrawableResourceAndroidBitmap('nor_quran_2'),
    );

    await PrayerNotificationService.scheduleCustom(
      id: reminder.notifId,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(android: androidDetails),
      matchDateTimeComponents: reminder.weekday != null
          ? DateTimeComponents.dayOfWeekAndTime
          : DateTimeComponents.time,
      payload: 'sunnah:${reminder.id}',
    );
  }

  static tz.TZDateTime _nextOccurrence(
      SunnahReminder reminder, tz.TZDateTime now) {
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.time.hour,
      reminder.time.minute,
    );

    if (reminder.weekday != null) {
      while (
          candidate.weekday != reminder.weekday || candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
    } else {
      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
    }

    return candidate;
  }
}
