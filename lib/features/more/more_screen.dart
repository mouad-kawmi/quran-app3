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
import 'package:quran_app/l10n/app_localizations.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.watch(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.more,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSection(l10n.religiousTools),
            _buildMoreItem(
              context,
              Icons.schedule_rounded,
              l10n.prayerTimes,
              l10n.prayerTimesDesc,
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
              l10n.qibla,
              l10n.qiblaDesc,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const QiblaScreen()),
              ),
            ),
            _buildMoreItem(
              context,
              Icons.flag_rounded,
              l10n.khatma,
              l10n.khatmaDesc,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const KhatmaScreen()),
              ),
            ),
            _buildMoreItem(
              context,
              Icons.library_music_rounded,
              l10n.downloadedAudio,
              l10n.downloadedAudioDesc,
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
              l10n.asmaUlHusna,
              l10n.asmaUlHusnaDesc,
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
              l10n.sunnahReminders,
              l10n.sunnahRemindersDesc,
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
              l10n.sahihBukhari,
              l10n.sahihBukhariDesc,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BukhariBooksScreen(),
                ),
              ),
            ),
            const Divider(),
            _buildSection(l10n.settings),
            _buildMoreItem(
              context,
              Icons.notifications_active_rounded,
              l10n.adhan,
              l10n.adhanDesc,
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
              l10n.tajweedRules,
              l10n.tajweedRulesDesc,
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
              l10n.themeMode,
              _getThemeLabel(context, settings.themeMode, l10n),
              () => _showThemeSheet(context, settings),
            ),
            _buildMoreItem(
              context,
              Icons.language_rounded,
              l10n.language,
              settings.locale.languageCode == 'ar' ? l10n.arabic : settings.locale.languageCode == 'fr' ? l10n.french : l10n.english,
              () => _showLanguageSheet(context, settings),
            ),
            _buildMoreItem(
              context,
              Icons.font_download_rounded,
              l10n.fontSize,
              l10n.currentSize(_getFontScaleLabel(settings.fontScale, l10n)),
              () => _showFontSizeSheet(context, settings, l10n),
            ),
            const Divider(),
            _buildSection(l10n.aboutApp),
            _buildMoreItem(
              context,
              Icons.mark_email_unread_rounded,
              l10n.contactUs,
              l10n.contactUsDesc,
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
              l10n.exactlyAboutApp,
              l10n.version('1.0.0'),
              () => _showAboutApp(context, l10n),
            ),
            _buildMoreItem(
              context,
              Icons.share_rounded,
              l10n.shareApp,
              l10n.shareAppDesc,
              () => _shareApp(l10n),
            ),
          ],
        ),
    );
  }

  String _getThemeLabel(BuildContext context, ThemeMode mode, AppLocalizations l10n) {
    return switch (mode) {
      ThemeMode.dark => l10n.darkTheme,
      ThemeMode.system => l10n.systemTheme,
      ThemeMode.light => l10n.lightTheme,
    };
  }

  String _getFontScaleLabel(double fontScale, AppLocalizations l10n) {
    if (fontScale < 0.98) return l10n.small;
    if (fontScale > 1.14) return l10n.large;
    if (fontScale > 1.04) return l10n.medium;
    return l10n.normal;
  }

  void _showThemeSheet(
    BuildContext context,
    AppSettingsController settings,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.themeMode,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildThemeOption(
                  sheetContext,
                  settings,
                  ThemeMode.light,
                  l10n.lightTheme,
                  Icons.light_mode_rounded,
                ),
                _buildThemeOption(
                  sheetContext,
                  settings,
                  ThemeMode.dark,
                  l10n.darkTheme,
                  Icons.dark_mode_rounded,
                ),
                _buildThemeOption(
                  sheetContext,
                  settings,
                  ThemeMode.system,
                  l10n.systemTheme,
                  Icons.phone_android_rounded,
                ),
              ],
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

  void _showLanguageSheet(
    BuildContext context,
    AppSettingsController settings,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildLanguageOption(
                  sheetContext,
                  settings,
                  const Locale('ar'),
                  l10n.arabic,
                ),
                _buildLanguageOption(
                  sheetContext,
                  settings,
                  const Locale('en'),
                  l10n.english,
                ),
                _buildLanguageOption(
                  sheetContext,
                  settings,
                  const Locale('fr'),
                  l10n.french,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext sheetContext,
    AppSettingsController settings,
    Locale locale,
    String title,
  ) {
    return RadioListTile<String>(
      value: locale.languageCode,
      groupValue: settings.locale.languageCode,
      onChanged: (value) {
        if (value == null) return;
        unawaited(settings.setLocale(Locale(value)));
        Navigator.pop(sheetContext);
      },
      activeColor: AppTheme.primaryColor,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  void _showFontSizeSheet(
    BuildContext context,
    AppSettingsController settings,
    AppLocalizations l10n,
  ) {
    var currentScale = settings.fontScale;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.fontSize,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.chooseFontSize,
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
                          fontFamily: 'QCF_BSML', // explicitly adding an arabic font for demo could be done but not needed
                        ),
                        textDirection: TextDirection.rtl, // ensure Arabic demo is always RTL
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
                        Text(l10n.small, style: TextStyle(color: Colors.grey[600])),
                        Text(l10n.large, style: TextStyle(color: Colors.grey[600])),
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
                        label: Text(l10n.resetToNormalSize),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAboutApp(BuildContext context, AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: l10n.appTitle,
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
      children: [
        const SizedBox(height: 8),
        Text(l10n.shareAppMsg),
      ],
    );
  }

  void _shareApp(AppLocalizations l10n) {
    unawaited(
      SharePlus.instance.share(
        ShareParams(
          text: '${l10n.shareAppMsg}\nhttps://play.google.com/store/apps/details?id=com.mouad.quran.quran_app',
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
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
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
