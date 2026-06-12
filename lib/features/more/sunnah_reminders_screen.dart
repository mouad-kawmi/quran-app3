import 'package:flutter/material.dart';
import 'package:quran_app/core/sunnah_reminder_service.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class SunnahRemindersScreen extends StatefulWidget {
  const SunnahRemindersScreen({super.key});

  @override
  State<SunnahRemindersScreen> createState() => _SunnahRemindersScreenState();
}

class _SunnahRemindersScreenState extends State<SunnahRemindersScreen> {
  Map<String, bool> _states = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final states = await SunnahReminderService.loadAllStates();
    if (mounted) setState(() { _states = states; _loading = false; });
  }

  Future<void> _toggle(SunnahReminder reminder, bool value) async {
    setState(() => _states[reminder.id] = value);
    await SunnahReminderService.setEnabled(reminder, value);
    if (mounted && value) {
      final l10n = AppLocalizations.of(context)!;
      final locale = Localizations.localeOf(context).languageCode;
      final dow = reminder.weekday;
      final timeStr = _formatTime(reminder.time);
      String when;
      if (locale == 'en') {
        when = dow != null ? 'Every ${_weekdayNameEn(dow)} at $timeStr' : 'Daily at $timeStr';
      } else if (locale == 'fr') {
        when = dow != null ? 'Chaque ${_weekdayNameFr(dow)} à $timeStr' : 'Chaque jour à $timeStr';
      } else {
        when = dow != null ? 'كل ${_weekdayName(dow)} الساعة $timeStr' : 'يومياً الساعة $timeStr';
      }
      final msg = locale == 'en'
          ? '✅ You will be reminded $when'
          : locale == 'fr'
          ? '✅ Vous serez rappelé(e) $when'
          : '✅ سيتم تذكيرك $when';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _weekdayName(int wd) => const {
    1: 'الاثنين', 2: 'الثلاثاء', 3: 'الأربعاء',
    4: 'الخميس', 5: 'الجمعة', 6: 'السبت', 7: 'الأحد',
  }[wd]!;

  String _weekdayNameEn(int wd) => const {
    1: 'Monday', 2: 'Tuesday', 3: 'Wednesday',
    4: 'Thursday', 5: 'Friday', 6: 'Saturday', 7: 'Sunday',
  }[wd]!;

  String _weekdayNameFr(int wd) => const {
    1: 'lundi', 2: 'mardi', 3: 'mercredi',
    4: 'jeudi', 5: 'vendredi', 6: 'samedi', 7: 'dimanche',
  }[wd]!;

  String _scheduleLabel(SunnahReminder r, String locale) {
    final t = _formatTime(r.time);
    if (locale == 'en') {
      return r.weekday != null ? 'Every ${_weekdayNameEn(r.weekday!)} — $t' : 'Daily — $t';
    } else if (locale == 'fr') {
      return r.weekday != null ? 'Chaque ${_weekdayNameFr(r.weekday!)} — $t' : 'Chaque jour — $t';
    }
    return r.weekday != null ? 'كل ${_weekdayName(r.weekday!)} — $t' : 'يومياً — $t';
  }

  // Split reminders into categories
  static const _weekly = ['kahf_friday', 'salah_nabi_friday', 'fast_monday', 'fast_thursday'];
  static const _daily = ['morning_adhkar', 'evening_adhkar', 'quran_daily', 'mulk_night', 'sleep_adhkar'];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final screenTitle = locale == 'en' ? 'Sunnah Reminders' : locale == 'fr' ? 'Rappels Sunnah' : 'تنبيهات السنن';
    final weeklyLabel = locale == 'en' ? '📅 Weekly' : locale == 'fr' ? '📅 Hebdomadaire' : '📅 أسبوعية';
    final dailyLabel = locale == 'en' ? '🌙 Daily' : locale == 'fr' ? '🌙 Quotidien' : '🌙 يومية';
    final bannerMsg = locale == 'en'
        ? 'Enable the reminders you want and they\'ll arrive at the scheduled time automatically.'
        : locale == 'fr'
        ? 'Activez les rappels souhaités, ils arriveront automatiquement à l\'heure prévue.'
        : 'فعّل التنبيهات التي تريدها وستصلك في الوقت المحدد تلقائياً.';
    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoBanner(bannerMsg),
                const SizedBox(height: 20),
                _buildCategoryHeader(weeklyLabel, Icons.calendar_today_rounded),
                const SizedBox(height: 10),
                ..._buildCards(_weekly, locale),
                const SizedBox(height: 20),
                _buildCategoryHeader(dailyLabel, Icons.repeat_rounded),
                const SizedBox(height: 10),
                ..._buildCards(_daily, locale),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildInfoBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppTheme.primaryColor.withOpacity(0.85),
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCards(List<String> ids, String locale) {
    return SunnahReminderService.reminders
        .where((r) => ids.contains(r.id))
        .map((r) => _ReminderCard(
              reminder: r,
              enabled: _states[r.id] ?? false,
              scheduleLabel: _scheduleLabel(r, locale),
              locale: locale,
              onToggle: (v) => _toggle(r, v),
            ))
        .toList();
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.enabled,
    required this.scheduleLabel,
    required this.locale,
    required this.onToggle,
  });

  final SunnahReminder reminder;
  final bool enabled;
  final String scheduleLabel;
  final String locale;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: enabled
            ? reminder.color.withOpacity(dark ? 0.18 : 0.07)
            : AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? reminder.color.withOpacity(0.5)
              : AppTheme.softBorderColor(context),
          width: enabled ? 1.5 : 1,
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: reminder.color.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: reminder.color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: reminder.color.withOpacity(0.3)),
          ),
          child: Icon(reminder.icon, color: reminder.color, size: 22),
        ),
        title: Text(
          reminder.getLocalizedTitle(locale),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: enabled ? reminder.color : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              reminder.getLocalizedDescription(locale),
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppTheme.mutedTextColor(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: reminder.color),
                const SizedBox(width: 4),
                Text(
                  scheduleLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: reminder.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Switch(
          value: enabled,
          activeColor: reminder.color,
          onChanged: onToggle,
        ),
        isThreeLine: true,
      ),
    );
  }
}
