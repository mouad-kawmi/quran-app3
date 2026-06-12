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

  String getLocalizedTitle(String locale) {
    if (locale == 'ar') return title;
    const en = {
      'kahf_friday': '📖 Surah Al-Kahf',
      'mulk_night': '🌙 Surah Al-Mulk',
      'morning_adhkar': '🌅 Morning Adhkar',
      'evening_adhkar': '🌆 Evening Adhkar',
      'salah_nabi_friday': '💚 Salah upon the Prophet ﷺ',
      'fast_monday': '🤍 Monday Fast',
      'fast_thursday': '🤍 Thursday Fast',
      'sleep_adhkar': '😴 Sleep Adhkar',
      'quran_daily': '📚 Daily Quran Recitation',
    };
    const fr = {
      'kahf_friday': '📖 Sourate Al-Kahf',
      'mulk_night': '🌙 Sourate Al-Mulk',
      'morning_adhkar': '🌅 Adhkar du Matin',
      'evening_adhkar': '🌆 Adhkar du Soir',
      'salah_nabi_friday': '💚 Salat sur le Prophète ﷺ',
      'fast_monday': '🤍 Jeûne du Lundi',
      'fast_thursday': '🤍 Jeûne du Jeudi',
      'sleep_adhkar': '😴 Adhkar du Sommeil',
      'quran_daily': '📚 Récitation Quotidienne',
    };
    return (locale == 'fr' ? fr[id] : en[id]) ?? title;
  }

  String getLocalizedDescription(String locale) {
    if (locale == 'ar') return description;
    const en = {
      'kahf_friday': 'Whoever recites Surah Al-Kahf on Friday, a light will shine for him between the two Fridays.',
      'mulk_night': 'Jabir (RA) narrated: The Prophet ﷺ would not sleep until he had recited {Blessed is He in whose hand is dominion}.',
      'morning_adhkar': 'Morning adhkar are a shield and fortress for the Muslim throughout their day.',
      'evening_adhkar': 'Evening adhkar protect the Muslim through the night and renew their connection with Allah.',
      'salah_nabi_friday': 'The Prophet ﷺ said: Increase your prayers upon me on Friday and Friday night.',
      'fast_monday': 'The Prophet ﷺ said: That is the day I was born and the day revelation came to me, so I love to fast on it.',
      'fast_thursday': 'The Prophet ﷺ said: Deeds are presented on Monday and Thursday, and I love for my deeds to be presented while I am fasting.',
      'sleep_adhkar': 'Sleep adhkar protect the sleeping person and make their sleep an act of worship.',
      'quran_daily': 'The Prophet ﷺ said: Recite the Quran, for it will come on the Day of Resurrection as an intercessor for its companions.',
    };
    const fr = {
      'kahf_friday': 'Quiconque récite la Sourate Al-Kahf le vendredi, une lumière brillera pour lui entre les deux vendredis.',
      'mulk_night': 'Jabir (ra) rapporta : Le Prophète ﷺ ne dormait pas avant d\'avoir récité {Béni soit Celui en la main de qui est la royauté}.',
      'morning_adhkar': 'Les adhkar du matin sont un bouclier et une forteresse pour le musulman tout au long de sa journée.',
      'evening_adhkar': 'Les adhkar du soir protègent le musulman la nuit et renouvellent son lien avec Allah.',
      'salah_nabi_friday': 'Le Prophète ﷺ a dit : Multipliez les prières sur moi le vendredi et la nuit du vendredi.',
      'fast_monday': 'Le Prophète ﷺ a dit : C\'est le jour où je suis né et où la révélation m\'est venue, j\'aime donc y jeûner.',
      'fast_thursday': 'Le Prophète ﷺ a dit : Les actes sont présentés le lundi et le jeudi, et j\'aime que mes actes soient présentés pendant que je jeûne.',
      'sleep_adhkar': 'Les adhkar du sommeil protègent le dormeur et font de son sommeil un acte d\'adoration.',
      'quran_daily': 'Le Prophète ﷺ a dit : Récitez le Coran, il viendra le Jour de la Résurrection comme intercesseur pour ses compagnons.',
    };
    return (locale == 'fr' ? fr[id] : en[id]) ?? description;
  }
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
