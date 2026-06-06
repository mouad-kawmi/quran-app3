import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran_app/core/app_settings.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/adhan/adhan_settings_screen.dart';
import 'package:quran_app/features/more/asma_ul_husna_screen.dart';
import 'package:quran_app/features/more/contact_us_screen.dart';
import 'package:quran_app/features/more/sunnah_reminders_screen.dart';
import 'package:quran_app/features/khatma/khatma_screen.dart';
import 'package:quran_app/features/prayer_times/prayer_times_screen.dart';
import 'package:quran_app/features/qibla/qibla_screen.dart';
import 'package:quran_app/features/quran/downloaded_audio_screen.dart';
import 'package:quran_app/features/quran/tajweed/tajweed_rules_screen.dart';
import 'package:quran_app/features/bukhari/bukhari_books_screen.dart';
import 'package:share_plus/share_plus.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.watch(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'المزيد',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSection('الأدوات الدينية'),
            _buildMoreItem(
              context,
              Icons.schedule_rounded,
              'مواقيت الصلاة',
              'جميع أوقات اليوم من الفجر إلى العشاء',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrayerTimesScreen(),
                ),
              ),
            ),
            _buildMoreItem(
              context,
              Icons.explore_rounded,
              'القبلة',
              'تحديد اتجاه مكة المكرمة',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QiblaScreen()),
              ),
            ),
            _buildMoreItem(
              context,
              Icons.flag_rounded,
              'الختمة',
              '15 يوم، 30 يوم، أو 60 يوم مع تتبع الصفحات',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KhatmaScreen()),
              ),
            ),
            _buildMoreItem(
              context,
              Icons.library_music_rounded,
              'الصوتيات المحملة',
              'السور المحملة للاستماع دون إنترنت',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DownloadedAudioScreen(),
                ),
              ),
            ),
            _buildMoreItem(
              context,
              Icons.auto_awesome_rounded,
              'أسماء الله الحسنى',
              'تصفح الأسماء التسعة والتسعين مع معانيها',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AsmaUlHusnaScreen(),
                ),
              ),
            ),
            _buildMoreItem(
              context,
              Icons.notifications_active_rounded,
              'تنبيهات السنن',
              'تذكيرات بسورة الكهف والملك والأذكار والصيام',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SunnahRemindersScreen(),
                ),
              ),
            ),
            _buildMoreItem(
              context,
              Icons.book_rounded,
              'صحيح البخاري',
              'الأحاديث النبوية الشريفة',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BukhariBooksScreen(),
                ),
              ),
            ),
            const Divider(),
            _buildSection('الإعدادات'),
            _buildMoreItem(
              context,
              Icons.notifications_active_rounded,
              'الأذان',
              'اختيار الصوت وتحديد الصلوات',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdhanSettingsScreen(),
                ),
              ),
            ),
            _buildMoreItem(
              context,
              Icons.auto_stories_rounded,
              'أحكام التجويد الملونة',
              'تعلم أحكام التجويد وإدارة الألوان',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TajweedRulesScreen(),
                ),
              ),
            ),
            _buildMoreItem(
              context,
              Icons.color_lens_rounded,
              'المظهر',
              settings.themeLabel,
              () => _showThemeSheet(context, settings),
            ),
            _buildMoreItem(
              context,
              Icons.font_download_rounded,
              'حجم الخط',
              'الحجم الحالي: ${settings.fontScaleLabel}',
              () => _showFontSizeSheet(context, settings),
            ),
            const Divider(),
            _buildSection('عن التطبيق'),
            _buildMoreItem(
              context,
              Icons.mark_email_unread_rounded,
              'تواصل معنا',
              'أرسل رسالة للإبلاغ عن خطأ أو لاقتراح جديد',
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContactUsScreen(),
                ),
              ),
            ),
            _buildMoreItem(
              context,
              Icons.info_outline_rounded,
              'حول التطبيق',
              'الإصدار 1.0.0',
              () => _showAboutApp(context),
            ),
            _buildMoreItem(
              context,
              Icons.share_rounded,
              'شارك التطبيق',
              'انشر الخير مع أصدقائك',
              _shareApp,
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSheet(
    BuildContext context,
    AppSettingsController settings,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'المظهر',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildThemeOption(
                    sheetContext,
                    settings,
                    ThemeMode.light,
                    'الوضع النهاري',
                    Icons.light_mode_rounded,
                  ),
                  _buildThemeOption(
                    sheetContext,
                    settings,
                    ThemeMode.dark,
                    'الوضع الليلي',
                    Icons.dark_mode_rounded,
                  ),
                  _buildThemeOption(
                    sheetContext,
                    settings,
                    ThemeMode.system,
                    'حسب إعدادات الجهاز',
                    Icons.phone_android_rounded,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext sheetContext,
    AppSettingsController settings,
    ThemeMode mode,
    String title,
    IconData icon,
  ) {
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: settings.themeMode,
      onChanged: (value) {
        if (value == null) return;
        unawaited(settings.setThemeMode(value));
        Navigator.pop(sheetContext);
      },
      activeColor: AppTheme.primaryColor,
      secondary: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _showFontSizeSheet(
    BuildContext context,
    AppSettingsController settings,
  ) {
    var currentScale = settings.fontScale;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'حجم الخط',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اختر حجما مناسبا للقرآن والأذكار وباقي النصوص.',
                        style: TextStyle(color: Colors.grey[600], height: 1.5),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 19 * currentScale,
                            fontWeight: FontWeight.bold,
                            height: 1.7,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Slider(
                        value: currentScale,
                        min: AppSettingsController.minFontScale,
                        max: AppSettingsController.maxFontScale,
                        divisions: 4,
                        label: '${(currentScale * 100).round()}%',
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setSheetState(() => currentScale = value);
                          unawaited(settings.setFontScale(value));
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('صغير', style: TextStyle(color: Colors.grey[600])),
                          Text('كبير', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setSheetState(() => currentScale = 1);
                            unawaited(settings.setFontScale(1));
                          },
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('العودة للحجم العادي'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutApp(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'نور القرآن',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mosque_rounded, color: Colors.white),
      ),
      children: const [
        SizedBox(height: 8),
        Text(
          'تطبيق للقرآن الكريم، مواقيت الصلاة، الأذكار، القبلة، والختمة اليومية.',
        ),
      ],
    );
  }

  void _shareApp() {
    unawaited(
      SharePlus.instance.share(
        ShareParams(
          text:
              'جرّب تطبيق نور القرآن للقرآن الكريم، مواقيت الصلاة، الأذكار والقبلة.\nhttps://play.google.com/store/apps/details?id=com.mouad.quran.quran_app',
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildMoreItem(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
    VoidCallback? onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        sub,
        style: TextStyle(
          color: AppTheme.mutedTextColor(context),
          fontSize: 12,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
    );
  }
}
