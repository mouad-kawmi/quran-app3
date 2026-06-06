import 'package:flutter/material.dart';
import 'package:quran_app/core/sunnah_reminder_service.dart';
import 'package:quran_app/core/theme.dart';

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
      final dow = reminder.weekday;
      final timeStr = _formatTime(reminder.time);
      final when = dow != null
          ? 'كل ${_weekdayName(dow)} الساعة $timeStr'
          : 'يومياً الساعة $timeStr';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ سيتم تذكيرك $when'),
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

  String _scheduleLabel(SunnahReminder r) {
    final t = _formatTime(r.time);
    if (r.weekday != null) return 'كل ${_weekdayName(r.weekday!)} — $t';
    return 'يومياً — $t';
  }

  // Split reminders into categories
  static const _weekly = ['kahf_friday', 'salah_nabi_friday', 'fast_monday', 'fast_thursday'];
  static const _daily = ['morning_adhkar', 'evening_adhkar', 'quran_daily', 'mulk_night', 'sleep_adhkar'];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تنبيهات السنن', style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInfoBanner(),
                  const SizedBox(height: 20),
                  _buildCategoryHeader('📅 أسبوعية', Icons.calendar_today_rounded),
                  const SizedBox(height: 10),
                  ..._buildCards(_weekly),
                  const SizedBox(height: 20),
                  _buildCategoryHeader('🌙 يومية', Icons.repeat_rounded),
                  const SizedBox(height: 10),
                  ..._buildCards(_daily),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoBanner() {
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
              'فعّل التنبيهات التي تريدها وستصلك في الوقت المحدد تلقائياً.',
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

  List<Widget> _buildCards(List<String> ids) {
    return SunnahReminderService.reminders
        .where((r) => ids.contains(r.id))
        .map((r) => _ReminderCard(
              reminder: r,
              enabled: _states[r.id] ?? false,
              scheduleLabel: _scheduleLabel(r),
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
    required this.onToggle,
  });

  final SunnahReminder reminder;
  final bool enabled;
  final String scheduleLabel;
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
          reminder.title,
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
              reminder.description,
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
