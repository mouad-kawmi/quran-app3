import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'نور القرآن'**
  String get appTitle;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة / Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @french.
  ///
  /// In ar, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @themeMode.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get themeMode;

  /// No description provided for @lightTheme.
  ///
  /// In ar, this message translates to:
  /// **'الوضع النهاري'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الليلي'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In ar, this message translates to:
  /// **'حسب الجهاز'**
  String get systemTheme;

  /// No description provided for @more.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get more;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @quran.
  ///
  /// In ar, this message translates to:
  /// **'القرآن'**
  String get quran;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get search;

  /// No description provided for @adhkar.
  ///
  /// In ar, this message translates to:
  /// **'الأذكار'**
  String get adhkar;

  /// No description provided for @adhkarDesc.
  ///
  /// In ar, this message translates to:
  /// **'تحصين المسلم'**
  String get adhkarDesc;

  /// No description provided for @quranDesc.
  ///
  /// In ar, this message translates to:
  /// **'تلاوة وترجمة'**
  String get quranDesc;

  /// No description provided for @detectingLocation.
  ///
  /// In ar, this message translates to:
  /// **'تحديد الموقع'**
  String get detectingLocation;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @appSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'رفيقك في تدبر الذكر الحكيم'**
  String get appSubtitle;

  /// No description provided for @currentAdhan.
  ///
  /// In ar, this message translates to:
  /// **'الأذان الحالي'**
  String get currentAdhan;

  /// No description provided for @nextPrayer.
  ///
  /// In ar, this message translates to:
  /// **'الصلاة القادمة'**
  String get nextPrayer;

  /// No description provided for @elapsedSinceAdhan.
  ///
  /// In ar, this message translates to:
  /// **'مضى على الأذان'**
  String get elapsedSinceAdhan;

  /// No description provided for @remainingForAdhan.
  ///
  /// In ar, this message translates to:
  /// **'متبقي'**
  String get remainingForAdhan;

  /// No description provided for @locationErrorHint.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء قراءة الموقع. حاول مرة أخرى.'**
  String get locationErrorHint;

  /// No description provided for @adhanNeedsSetup.
  ///
  /// In ar, this message translates to:
  /// **'الأذان يحتاج إكمال الإعداد'**
  String get adhanNeedsSetup;

  /// No description provided for @adhanNeedsSetupDesc.
  ///
  /// In ar, this message translates to:
  /// **'فعّل التنبيهات والوقت الدقيق واستثناء البطارية مرة واحدة لتتمتع بتجربة أذان متكاملة و يشتغل التطبيق في الخلفية.'**
  String get adhanNeedsSetupDesc;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات'**
  String get notifications;

  /// No description provided for @exactTime.
  ///
  /// In ar, this message translates to:
  /// **'الوقت الدقيق'**
  String get exactTime;

  /// No description provided for @doNotDisturb.
  ///
  /// In ar, this message translates to:
  /// **'عدم الإزعاج'**
  String get doNotDisturb;

  /// No description provided for @battery.
  ///
  /// In ar, this message translates to:
  /// **'البطارية'**
  String get battery;

  /// No description provided for @location.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get location;

  /// No description provided for @scheduling.
  ///
  /// In ar, this message translates to:
  /// **'البرمجة'**
  String get scheduling;

  /// No description provided for @completeSetup.
  ///
  /// In ar, this message translates to:
  /// **'إكمال الإعداد'**
  String get completeSetup;

  /// No description provided for @mainServices.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات الرئيسية'**
  String get mainServices;

  /// No description provided for @continueReading.
  ///
  /// In ar, this message translates to:
  /// **'متابعة القراءة'**
  String get continueReading;

  /// No description provided for @fullList.
  ///
  /// In ar, this message translates to:
  /// **'القائمة كاملة'**
  String get fullList;

  /// No description provided for @ayahOfTheDay.
  ///
  /// In ar, this message translates to:
  /// **'آية اليوم'**
  String get ayahOfTheDay;

  /// No description provided for @share.
  ///
  /// In ar, this message translates to:
  /// **'شارك'**
  String get share;

  /// No description provided for @khatmaProgress.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الإنجاز والورد اليومي'**
  String get khatmaProgress;

  /// No description provided for @surahList.
  ///
  /// In ar, this message translates to:
  /// **'الفهرس'**
  String get surahList;

  /// No description provided for @allSurahs.
  ///
  /// In ar, this message translates to:
  /// **'جميع سور القرآن'**
  String get allSurahs;

  /// No description provided for @newKhatma.
  ///
  /// In ar, this message translates to:
  /// **'ختمة جديدة'**
  String get newKhatma;

  /// No description provided for @startOrganizedReading.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ قراءة منظمة'**
  String get startOrganizedReading;

  /// No description provided for @determineQibla.
  ///
  /// In ar, this message translates to:
  /// **'تحديد اتجاه الصلاة'**
  String get determineQibla;

  /// No description provided for @khatmaState.
  ///
  /// In ar, this message translates to:
  /// **'{percent}٪ . الصفحة {page}'**
  String khatmaState(int percent, int page);

  /// No description provided for @setupAdhanNow.
  ///
  /// In ar, this message translates to:
  /// **'إعداد الأذان الآن'**
  String get setupAdhanNow;

  /// No description provided for @later.
  ///
  /// In ar, this message translates to:
  /// **'لاحقا'**
  String get later;

  /// No description provided for @religiousTools.
  ///
  /// In ar, this message translates to:
  /// **'الأدوات الدينية'**
  String get religiousTools;

  /// No description provided for @continueKhatma.
  ///
  /// In ar, this message translates to:
  /// **'متابعة الختمة'**
  String get continueKhatma;

  /// No description provided for @startKhatma.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الختمة'**
  String get startKhatma;

  /// No description provided for @khatmaCompleted.
  ///
  /// In ar, this message translates to:
  /// **'الختمة مكتملة'**
  String get khatmaCompleted;

  /// No description provided for @khatmaDayAndPage.
  ///
  /// In ar, this message translates to:
  /// **'اليوم {day} • الصفحة {page}'**
  String khatmaDayAndPage(int day, int page);

  /// No description provided for @chooseKhatmaPlan.
  ///
  /// In ar, this message translates to:
  /// **'اختر خطة الختمة'**
  String get chooseKhatmaPlan;

  /// No description provided for @khatmaPagesRead.
  ///
  /// In ar, this message translates to:
  /// **'{count}/604 صفحة مقروءة'**
  String khatmaPagesRead(int count);

  /// No description provided for @khatmaDaysOptions.
  ///
  /// In ar, this message translates to:
  /// **'15 أو 30 أو 60 يوم'**
  String get khatmaDaysOptions;

  /// No description provided for @openPosition.
  ///
  /// In ar, this message translates to:
  /// **'فتح الموضع'**
  String get openPosition;

  /// No description provided for @choosePlan.
  ///
  /// In ar, this message translates to:
  /// **'اختيار خطة'**
  String get choosePlan;

  /// No description provided for @lastRead.
  ///
  /// In ar, this message translates to:
  /// **'آخر ما قرأت'**
  String get lastRead;

  /// No description provided for @startReading.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ القراءة'**
  String get startReading;

  /// No description provided for @surahName.
  ///
  /// In ar, this message translates to:
  /// **'سورة {name}'**
  String surahName(String name);

  /// No description provided for @chooseSurahFromList.
  ///
  /// In ar, this message translates to:
  /// **'اختر سورة من القائمة'**
  String get chooseSurahFromList;

  /// No description provided for @stoppedAtAyah.
  ///
  /// In ar, this message translates to:
  /// **'توقفت عند الآية {ayah}'**
  String stoppedAtAyah(int ayah);

  /// No description provided for @prayerTimes.
  ///
  /// In ar, this message translates to:
  /// **'مواقيت الصلاة'**
  String get prayerTimes;

  /// No description provided for @prayerTimesDesc.
  ///
  /// In ar, this message translates to:
  /// **'جميع أوقات اليوم من الفجر إلى العشاء'**
  String get prayerTimesDesc;

  /// No description provided for @qibla.
  ///
  /// In ar, this message translates to:
  /// **'القبلة'**
  String get qibla;

  /// No description provided for @qiblaDesc.
  ///
  /// In ar, this message translates to:
  /// **'تحديد اتجاه مكة المكرمة'**
  String get qiblaDesc;

  /// No description provided for @khatma.
  ///
  /// In ar, this message translates to:
  /// **'الختمة'**
  String get khatma;

  /// No description provided for @khatmaDesc.
  ///
  /// In ar, this message translates to:
  /// **'15 يوم، 30 يوم، أو 60 يوم مع تتبع الصفحات'**
  String get khatmaDesc;

  /// No description provided for @downloadedAudio.
  ///
  /// In ar, this message translates to:
  /// **'الصوتيات المحملة'**
  String get downloadedAudio;

  /// No description provided for @downloadedAudioDesc.
  ///
  /// In ar, this message translates to:
  /// **'السور المحملة للاستماع دون إنترنت'**
  String get downloadedAudioDesc;

  /// No description provided for @asmaUlHusna.
  ///
  /// In ar, this message translates to:
  /// **'أسماء الله الحسنى'**
  String get asmaUlHusna;

  /// No description provided for @asmaUlHusnaDesc.
  ///
  /// In ar, this message translates to:
  /// **'تصفح الأسماء التسعة والتسعين مع معانيها'**
  String get asmaUlHusnaDesc;

  /// No description provided for @sunnahReminders.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات السنن'**
  String get sunnahReminders;

  /// No description provided for @sunnahRemindersDesc.
  ///
  /// In ar, this message translates to:
  /// **'تذكيرات بسورة الكهف والملك والأذكار والصيام'**
  String get sunnahRemindersDesc;

  /// No description provided for @sahihBukhari.
  ///
  /// In ar, this message translates to:
  /// **'صحيح البخاري'**
  String get sahihBukhari;

  /// No description provided for @sahihBukhariDesc.
  ///
  /// In ar, this message translates to:
  /// **'الأحاديث النبوية الشريفة'**
  String get sahihBukhariDesc;

  /// No description provided for @adhan.
  ///
  /// In ar, this message translates to:
  /// **'الأذان'**
  String get adhan;

  /// No description provided for @adhanDesc.
  ///
  /// In ar, this message translates to:
  /// **'اختيار الصوت وتحديد الصلوات'**
  String get adhanDesc;

  /// No description provided for @tajweedRules.
  ///
  /// In ar, this message translates to:
  /// **'أحكام التجويد الملونة'**
  String get tajweedRules;

  /// No description provided for @tajweedRulesDesc.
  ///
  /// In ar, this message translates to:
  /// **'تعلم أحكام التجويد وإدارة الألوان'**
  String get tajweedRulesDesc;

  /// No description provided for @fontSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط'**
  String get fontSize;

  /// No description provided for @currentSize.
  ///
  /// In ar, this message translates to:
  /// **'الحجم الحالي: {size}'**
  String currentSize(String size);

  /// No description provided for @chooseFontSize.
  ///
  /// In ar, this message translates to:
  /// **'اختر حجما مناسبا للقرآن والأذكار وباقي النصوص.'**
  String get chooseFontSize;

  /// No description provided for @small.
  ///
  /// In ar, this message translates to:
  /// **'صغير'**
  String get small;

  /// No description provided for @large.
  ///
  /// In ar, this message translates to:
  /// **'كبير'**
  String get large;

  /// No description provided for @medium.
  ///
  /// In ar, this message translates to:
  /// **'متوسط'**
  String get medium;

  /// No description provided for @normal.
  ///
  /// In ar, this message translates to:
  /// **'عادي'**
  String get normal;

  /// No description provided for @resetToNormalSize.
  ///
  /// In ar, this message translates to:
  /// **'العودة للحجم العادي'**
  String get resetToNormalSize;

  /// No description provided for @aboutApp.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get aboutApp;

  /// No description provided for @contactUs.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا'**
  String get contactUs;

  /// No description provided for @contactUsDesc.
  ///
  /// In ar, this message translates to:
  /// **'أرسل رسالة للإبلاغ عن خطأ أو لاقتراح جديد'**
  String get contactUsDesc;

  /// No description provided for @exactlyAboutApp.
  ///
  /// In ar, this message translates to:
  /// **'حول التطبيق'**
  String get exactlyAboutApp;

  /// No description provided for @version.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار {version}'**
  String version(String version);

  /// No description provided for @shareApp.
  ///
  /// In ar, this message translates to:
  /// **'شارك التطبيق'**
  String get shareApp;

  /// No description provided for @shareAppDesc.
  ///
  /// In ar, this message translates to:
  /// **'انشر الخير مع أصدقائك'**
  String get shareAppDesc;

  /// No description provided for @shareAppMsg.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تطبيق نور القرآن للقرآن الكريم، مواقيت الصلاة، الأذكار والقبلة.'**
  String get shareAppMsg;

  /// No description provided for @dhikrCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} ذكراً'**
  String dhikrCount(int count);

  /// No description provided for @resetAll.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الكل'**
  String get resetAll;

  /// No description provided for @resetItem.
  ///
  /// In ar, this message translates to:
  /// **'إعادة من الأول'**
  String get resetItem;

  /// No description provided for @tapToRepeat.
  ///
  /// In ar, this message translates to:
  /// **'اضغط للإعادة'**
  String get tapToRepeat;

  /// No description provided for @repetitions.
  ///
  /// In ar, this message translates to:
  /// **'التكرار: {count}'**
  String repetitions(int count);

  /// No description provided for @prayerTimesError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر جلب مواقيت الصلاة الآن. حاول مرة أخرى.'**
  String get prayerTimesError;

  /// No description provided for @officialSource.
  ///
  /// In ar, this message translates to:
  /// **'مصدر رسمي: {name}'**
  String officialSource(String name);

  /// No description provided for @officialSourceNote.
  ///
  /// In ar, this message translates to:
  /// **'المواقيت مجلوبة من صفحة وزارة الأوقاف عند توفر الاتصال.'**
  String get officialSourceNote;

  /// No description provided for @fallbackSourceNote.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الاتصال بموقع الوزارة، لذلك استعملنا الحساب المحلي مؤقتاً.'**
  String get fallbackSourceNote;

  /// No description provided for @refresh.
  ///
  /// In ar, this message translates to:
  /// **'تحديث'**
  String get refresh;

  /// No description provided for @quranSurahs.
  ///
  /// In ar, this message translates to:
  /// **'سور القرآن الكريم'**
  String get quranSurahs;

  /// No description provided for @downloadedAudioTooltip.
  ///
  /// In ar, this message translates to:
  /// **'الصوتيات المحملة'**
  String get downloadedAudioTooltip;

  /// No description provided for @indexTooltip.
  ///
  /// In ar, this message translates to:
  /// **'الفهرس'**
  String get indexTooltip;

  /// No description provided for @bookmarksTooltip.
  ///
  /// In ar, this message translates to:
  /// **'العلامات'**
  String get bookmarksTooltip;

  /// No description provided for @searchTooltip.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get searchTooltip;

  /// No description provided for @ayahCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} آية'**
  String ayahCount(int count);

  /// No description provided for @quranIndex.
  ///
  /// In ar, this message translates to:
  /// **'فهرس القرآن'**
  String get quranIndex;

  /// No description provided for @juzTab.
  ///
  /// In ar, this message translates to:
  /// **'الأجزاء'**
  String get juzTab;

  /// No description provided for @hizbTab.
  ///
  /// In ar, this message translates to:
  /// **'الأحزاب'**
  String get hizbTab;

  /// No description provided for @pagesTab.
  ///
  /// In ar, this message translates to:
  /// **'الصفحات'**
  String get pagesTab;

  /// No description provided for @juzTitle.
  ///
  /// In ar, this message translates to:
  /// **'الجزء {n}'**
  String juzTitle(int n);

  /// No description provided for @hizbTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحزب {n}'**
  String hizbTitle(int n);

  /// No description provided for @pageTitle.
  ///
  /// In ar, this message translates to:
  /// **'الصفحة {n}'**
  String pageTitle(int n);

  /// No description provided for @juzStartsAt.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ من سورة {surah} • الآية {ayah} • الصفحة {page}'**
  String juzStartsAt(String surah, int ayah, int page);

  /// No description provided for @hizbFromPage.
  ///
  /// In ar, this message translates to:
  /// **'من الصفحة {page} • سورة {surah}'**
  String hizbFromPage(int page, String surah);

  /// No description provided for @searchInQuran.
  ///
  /// In ar, this message translates to:
  /// **'البحث في القرآن'**
  String get searchInQuran;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كلمة للبحث...'**
  String get searchHint;

  /// No description provided for @results.
  ///
  /// In ar, this message translates to:
  /// **'النتائج'**
  String get results;

  /// No description provided for @resultCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} نتيجة'**
  String resultCount(int count);

  /// No description provided for @searchEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن أي كلمة'**
  String get searchEmptyTitle;

  /// No description provided for @searchEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'البحث يعمل دون إنترنت ويشمل آيات القرآن كاملة.'**
  String get searchEmptySubtitle;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In ar, this message translates to:
  /// **'عذراً، لم نجد نتائج'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حاول بكلمة أخرى أو اكتبها دون تشكيل.'**
  String get searchNoResultsSubtitle;

  /// No description provided for @page.
  ///
  /// In ar, this message translates to:
  /// **'ص {n}'**
  String page(int n);

  /// No description provided for @prayerFajr.
  ///
  /// In ar, this message translates to:
  /// **'الفجر'**
  String get prayerFajr;

  /// No description provided for @prayerDhuhr.
  ///
  /// In ar, this message translates to:
  /// **'الظهر'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In ar, this message translates to:
  /// **'العصر'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In ar, this message translates to:
  /// **'المغرب'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In ar, this message translates to:
  /// **'العشاء'**
  String get prayerIsha;

  /// No description provided for @prayerSunrise.
  ///
  /// In ar, this message translates to:
  /// **'الشروق'**
  String get prayerSunrise;

  /// No description provided for @fallbackCityName.
  ///
  /// In ar, this message translates to:
  /// **'الرباط'**
  String get fallbackCityName;

  /// No description provided for @fallbackLocationNotice.
  ///
  /// In ar, this message translates to:
  /// **'المواقيت محسوبة الآن على الرباط. فعّل خدمة الموقع واضغط على شارة الموقع لتحديد مدينتك.'**
  String get fallbackLocationNotice;

  /// No description provided for @storedLocationNotice.
  ///
  /// In ar, this message translates to:
  /// **'المواقيت محسوبة على آخر موقع محفوظ. يعمل التطبيق دون خدمة الموقع ودون إنترنت.'**
  String get storedLocationNotice;

  /// No description provided for @unavailableLocationNotice.
  ///
  /// In ar, this message translates to:
  /// **'المواقيت معتمدة على آخر موقع محفوظ لأن خدمة الموقع غير متاحة الآن. يعمل التطبيق دون إنترنت.'**
  String get unavailableLocationNotice;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In ar, this message translates to:
  /// **'فعّل خدمة الموقع لحساب المواقيت حسب مدينتك.'**
  String get locationServiceDisabled;

  /// No description provided for @locationPermissionNeeded.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج التطبيق إلى إذن الموقع لعرض المواقيت الصحيحة.'**
  String get locationPermissionNeeded;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In ar, this message translates to:
  /// **'إذن الموقع مرفوض بشكل دائم. افتح إعدادات الهاتف وفعّل الإذن للتطبيق.'**
  String get locationPermissionDenied;

  /// No description provided for @locationTimeoutError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الحصول على الموقع الآن. فعّل خدمة الموقع وحاول مرة أخرى.'**
  String get locationTimeoutError;

  /// No description provided for @reciterMishari.
  ///
  /// In ar, this message translates to:
  /// **'مشاري راشد العفاسي'**
  String get reciterMishari;

  /// No description provided for @reciterMishariShort.
  ///
  /// In ar, this message translates to:
  /// **'العفاسي'**
  String get reciterMishariShort;

  /// No description provided for @reciterMinshawi.
  ///
  /// In ar, this message translates to:
  /// **'محمد صديق المنشاوي'**
  String get reciterMinshawi;

  /// No description provided for @reciterMinshawiShort.
  ///
  /// In ar, this message translates to:
  /// **'المنشاوي'**
  String get reciterMinshawiShort;

  /// No description provided for @reciterHusari.
  ///
  /// In ar, this message translates to:
  /// **'محمود خليل الحصري'**
  String get reciterHusari;

  /// No description provided for @reciterHusariShort.
  ///
  /// In ar, this message translates to:
  /// **'الحصري'**
  String get reciterHusariShort;

  /// No description provided for @reciterAbdulBasit.
  ///
  /// In ar, this message translates to:
  /// **'عبد الباسط عبد الصمد'**
  String get reciterAbdulBasit;

  /// No description provided for @reciterAbdulBasitShort.
  ///
  /// In ar, this message translates to:
  /// **'عبد الباسط'**
  String get reciterAbdulBasitShort;

  /// No description provided for @reciterAlHudhayfi.
  ///
  /// In ar, this message translates to:
  /// **'علي الحذيفي'**
  String get reciterAlHudhayfi;

  /// No description provided for @reciterAlHudhayfiShort.
  ///
  /// In ar, this message translates to:
  /// **'الحذيفي'**
  String get reciterAlHudhayfiShort;

  /// No description provided for @reciterMuhammadAyyub.
  ///
  /// In ar, this message translates to:
  /// **'محمد أيوب'**
  String get reciterMuhammadAyyub;

  /// No description provided for @reciterMuhammadAyyubShort.
  ///
  /// In ar, this message translates to:
  /// **'محمد أيوب'**
  String get reciterMuhammadAyyubShort;

  /// No description provided for @wordTranslation.
  ///
  /// In ar, this message translates to:
  /// **'الترجمة (Saheeh International)'**
  String get wordTranslation;

  /// No description provided for @play.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل'**
  String get play;

  /// No description provided for @interpretation.
  ///
  /// In ar, this message translates to:
  /// **'التفسير'**
  String get interpretation;

  /// No description provided for @deleteAudioTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف الصوت؟'**
  String get deleteAudioTitle;

  /// No description provided for @deleteAudioContent.
  ///
  /// In ar, this message translates to:
  /// **'سيتم حذف صوت سورة {surah} بصوت {reciter} من الجهاز.'**
  String deleteAudioContent(String surah, String reciter);

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @noDownloadedAudioTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد صوتيات محملة بعد'**
  String get noDownloadedAudioTitle;

  /// No description provided for @noDownloadedAudioDesc.
  ///
  /// In ar, this message translates to:
  /// **'افتح أي سورة واضغط زر التحميل بجانب المشغل، وستظهر هنا للاستماع إليها دون إنترنت.'**
  String get noDownloadedAudioDesc;

  /// No description provided for @openSurah.
  ///
  /// In ar, this message translates to:
  /// **'فتح السورة'**
  String get openSurah;

  /// No description provided for @deleteAudio.
  ///
  /// In ar, this message translates to:
  /// **'حذف الصوت'**
  String get deleteAudio;

  /// No description provided for @asmaUlHusnaAyah.
  ///
  /// In ar, this message translates to:
  /// **'وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَى فَادْعُوهُ بِهَا'**
  String get asmaUlHusnaAyah;

  /// No description provided for @asmaUlHusnaAyahRef.
  ///
  /// In ar, this message translates to:
  /// **'— سورة الأعراف: 180'**
  String get asmaUlHusnaAyahRef;

  /// No description provided for @searchNameHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن اسم...'**
  String get searchNameHint;

  /// No description provided for @meaningAndSignificance.
  ///
  /// In ar, this message translates to:
  /// **'المعنى والدلالة'**
  String get meaningAndSignificance;

  /// No description provided for @asmaUlHusnaDhikrTip.
  ///
  /// In ar, this message translates to:
  /// **'يُستحب الإكثار من ذكر هذا الاسم في الدعاء والتسبيح لما فيه من معاني التقرب إلى الله تعالى.'**
  String get asmaUlHusnaDhikrTip;

  /// No description provided for @bukhariDeleteTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف صحيح البخاري'**
  String get bukhariDeleteTitle;

  /// No description provided for @bukhariDeleteContent.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد أنك تريد حذف كتاب صحيح البخاري من جهازك؟ ستحتاج إلى إنترنت لتحميله مرة أخرى.'**
  String get bukhariDeleteContent;

  /// No description provided for @bukhariNoBooksError.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على أي كتب في قاعدة البيانات. تأكد من تحميل الملف.'**
  String get bukhariNoBooksError;

  /// No description provided for @bukhariDownloading.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحميل صحيح البخاري...'**
  String get bukhariDownloading;

  /// No description provided for @bukhariDownloadWait.
  ///
  /// In ar, this message translates to:
  /// **'نرجو الانتظار، الحجم التقريبي 9 ميغابايت'**
  String get bukhariDownloadWait;

  /// No description provided for @bukhariDescription.
  ///
  /// In ar, this message translates to:
  /// **'يحتوي على أكثر من 7000 حديث شريف.\nقم بتحميل الكتاب الآن لتصفح الأحاديث بدون إنترنت في أي وقت.'**
  String get bukhariDescription;

  /// No description provided for @bukhariDownloadBtn.
  ///
  /// In ar, this message translates to:
  /// **'تحميل الكتاب (9.4MB)'**
  String get bukhariDownloadBtn;

  /// No description provided for @bukhariHadiths.
  ///
  /// In ar, this message translates to:
  /// **'الأحاديث: {count}'**
  String bukhariHadiths(int count);

  /// No description provided for @hadithNumber.
  ///
  /// In ar, this message translates to:
  /// **'حديث رقم {number}'**
  String hadithNumber(int number);

  /// No description provided for @bukhariSearchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث برقم الحديث أو الكلمة...'**
  String get bukhariSearchHint;

  /// No description provided for @bukhariSearchEmptyText.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقم الحديث (مثال: 1) \nأو كلمة للبحث عنها'**
  String get bukhariSearchEmptyText;

  /// No description provided for @bukhariSearchNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على نتائج تطابق بحثك'**
  String get bukhariSearchNoResults;

  /// No description provided for @unknownBook.
  ///
  /// In ar, this message translates to:
  /// **'كتاب غير معروف'**
  String get unknownBook;

  /// No description provided for @adhanCompleteSetup.
  ///
  /// In ar, this message translates to:
  /// **'إكمال تفعيل الأذان'**
  String get adhanCompleteSetup;

  /// No description provided for @adhanCompleteSetupContent.
  ///
  /// In ar, this message translates to:
  /// **'سيطلب التطبيق تفعيل التنبيهات والوقت الدقيق وتجاوز عدم الإزعاج واستثناء البطارية، ثم يعيد برمجة الأذان حتى يعمل في وقته.'**
  String get adhanCompleteSetupContent;

  /// No description provided for @adhanStartSetup.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الإعداد'**
  String get adhanStartSetup;

  /// No description provided for @adhanSoundSet.
  ///
  /// In ar, this message translates to:
  /// **'تم اعتماد صوت الأذان: {sound}'**
  String adhanSoundSet(String sound);

  /// No description provided for @adhanSoundPickError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر اختيار الملف الصوتي. حاول مرة أخرى.'**
  String get adhanSoundPickError;

  /// No description provided for @adhanStatusTitle.
  ///
  /// In ar, this message translates to:
  /// **'حالة الأذان والتنبيهات'**
  String get adhanStatusTitle;

  /// No description provided for @refreshStatus.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الحالة'**
  String get refreshStatus;

  /// No description provided for @adhanNotificationsPerm.
  ///
  /// In ar, this message translates to:
  /// **'إذن التنبيهات'**
  String get adhanNotificationsPerm;

  /// No description provided for @enabled.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get enabled;

  /// No description provided for @adhanNotificationsPermDesc.
  ///
  /// In ar, this message translates to:
  /// **'يلزم تفعيله لإظهار تنبيهات الأذان'**
  String get adhanNotificationsPermDesc;

  /// No description provided for @adhanExactTimePerm.
  ///
  /// In ar, this message translates to:
  /// **'التنبيه في الوقت الدقيق'**
  String get adhanExactTimePerm;

  /// No description provided for @adhanExactTimeOk.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل للوقت الدقيق'**
  String get adhanExactTimeOk;

  /// No description provided for @adhanExactTimePermDesc.
  ///
  /// In ar, this message translates to:
  /// **'قد يتأخر الأذان إذا بقي غير مفعّل'**
  String get adhanExactTimePermDesc;

  /// No description provided for @adhanDndPerm.
  ///
  /// In ar, this message translates to:
  /// **'تجاوز عدم الإزعاج'**
  String get adhanDndPerm;

  /// No description provided for @allowed.
  ///
  /// In ar, this message translates to:
  /// **'مسموح'**
  String get allowed;

  /// No description provided for @adhanDndPermDesc.
  ///
  /// In ar, this message translates to:
  /// **'اختياري عند منع أصوات المنبهات'**
  String get adhanDndPermDesc;

  /// No description provided for @adhanBatteryPerm.
  ///
  /// In ar, this message translates to:
  /// **'استثناء البطارية'**
  String get adhanBatteryPerm;

  /// No description provided for @adhanBatteryOk.
  ///
  /// In ar, this message translates to:
  /// **'مستثنى من التوفير'**
  String get adhanBatteryOk;

  /// No description provided for @adhanBatteryPermDesc.
  ///
  /// In ar, this message translates to:
  /// **'يساعد على استمرار الأذان في الخلفية'**
  String get adhanBatteryPermDesc;

  /// No description provided for @adhanLocationPerm.
  ///
  /// In ar, this message translates to:
  /// **'الموقع المحفوظ'**
  String get adhanLocationPerm;

  /// No description provided for @found.
  ///
  /// In ar, this message translates to:
  /// **'موجود'**
  String get found;

  /// No description provided for @adhanLocationPermDesc.
  ///
  /// In ar, this message translates to:
  /// **'افتح الرئيسية لتحديد المواقيت'**
  String get adhanLocationPermDesc;

  /// No description provided for @adhanScheduled.
  ///
  /// In ar, this message translates to:
  /// **'التنبيهات المبرمجة'**
  String get adhanScheduled;

  /// No description provided for @adhanScheduledCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} تنبيه'**
  String adhanScheduledCount(int count);

  /// No description provided for @adhanScheduledNotYet.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم برمجة التنبيهات بعد'**
  String get adhanScheduledNotYet;

  /// No description provided for @adhanBgTip.
  ///
  /// In ar, this message translates to:
  /// **'يعمل الأذان كمنبه في الخلفية. إذا كان وضع عدم الإزعاج يمنع أصوات المنبهات، فعّل إذن تجاوز عدم الإزعاج ثم أعد البرمجة.'**
  String get adhanBgTip;

  /// No description provided for @enableNotifications.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل التنبيهات'**
  String get enableNotifications;

  /// No description provided for @enableExactAlarm.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل الوقت الدقيق'**
  String get enableExactAlarm;

  /// No description provided for @bypassDnd.
  ///
  /// In ar, this message translates to:
  /// **'تجاوز عدم الإزعاج'**
  String get bypassDnd;

  /// No description provided for @setupBattery.
  ///
  /// In ar, this message translates to:
  /// **'إعداد البطارية'**
  String get setupBattery;

  /// No description provided for @rescheduleAdhan.
  ///
  /// In ar, this message translates to:
  /// **'إعادة البرمجة'**
  String get rescheduleAdhan;

  /// No description provided for @adhanRescheduleSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث برمجة الأذان والتنبيهات.'**
  String get adhanRescheduleSuccess;

  /// No description provided for @adhanRescheduleNoLocation.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد موقع محفوظ بعد. افتح الصفحة الرئيسية لتحديد مواقيت الصلاة.'**
  String get adhanRescheduleNoLocation;

  /// No description provided for @adhanPolicySuccess.
  ///
  /// In ar, this message translates to:
  /// **'بعد منح الإذن، اضغط إعادة البرمجة لتحديث تنبيهات الأذان.'**
  String get adhanPolicySuccess;

  /// No description provided for @adhanUploadSound.
  ///
  /// In ar, this message translates to:
  /// **'إضافة أذان من الهاتف'**
  String get adhanUploadSound;

  /// No description provided for @adhanUploadSoundDesc.
  ///
  /// In ar, this message translates to:
  /// **'اختر ملفا صوتيا ليستعمله التطبيق للأذان'**
  String get adhanUploadSoundDesc;

  /// No description provided for @adhanVolume.
  ///
  /// In ar, this message translates to:
  /// **'حجم صوت الأذان'**
  String get adhanVolume;

  /// No description provided for @prayersLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصلوات'**
  String get prayersLabel;

  /// No description provided for @adhanPreviewError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر تشغيل معاينة الأذان.'**
  String get adhanPreviewError;

  /// No description provided for @contactUsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تواصل معنا'**
  String get contactUsTitle;

  /// No description provided for @contactUsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'هل لديك اقتراح أو واجهتك مشكلة؟'**
  String get contactUsSubtitle;

  /// No description provided for @contactUsFeedbackDesc.
  ///
  /// In ar, this message translates to:
  /// **'نسعد باستقبال ملاحظاتك لتطوير التطبيق وتقديم تجربة أفضل.'**
  String get contactUsFeedbackDesc;

  /// No description provided for @formspreeError.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إعداد رابط Formspree في الكود أولاً'**
  String get formspreeError;

  /// No description provided for @sendSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم الإرسال بنجاح!\nشكراً لك على تواصلك معنا.'**
  String get sendSuccess;

  /// No description provided for @messageType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الرسالة (اقتراح / تبليغ عن خطأ)'**
  String get messageType;

  /// No description provided for @subjectHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: مشكلة في تلاوة سورة الكهف...'**
  String get subjectHint;

  /// No description provided for @requiredField.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get requiredField;

  /// No description provided for @messageText.
  ///
  /// In ar, this message translates to:
  /// **'نص الرسالة'**
  String get messageText;

  /// No description provided for @messageHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب تفاصيل الرسالة هنا...'**
  String get messageHint;

  /// No description provided for @sendBtn.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرسالة الآن'**
  String get sendBtn;

  /// No description provided for @sendError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الإرسال، تحقق من اتصالك بالإنترنت.'**
  String get sendError;

  /// No description provided for @tajweedRulesTitle.
  ///
  /// In ar, this message translates to:
  /// **'أحكام التجويد الملونة'**
  String get tajweedRulesTitle;

  /// No description provided for @allCategory.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allCategory;

  /// No description provided for @enableTajweedMushaf.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل مصحف التجويد'**
  String get enableTajweedMushaf;

  /// No description provided for @enableTajweedMushafDesc.
  ///
  /// In ar, this message translates to:
  /// **'إظهار الألوان لتسهيل الترتيل.'**
  String get enableTajweedMushafDesc;

  /// No description provided for @tajweedNoteColor.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة: الألوان تظهر في \"الخط العادي\". قم بتعطيل الخط العثماني (QCF) من إعدادات القراءة.'**
  String get tajweedNoteColor;

  /// No description provided for @searchTajweedHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن حكم تجويدي...'**
  String get searchTajweedHint;

  /// No description provided for @noResultsFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على نتائج'**
  String get noResultsFound;

  /// No description provided for @adhanEnabled.
  ///
  /// In ar, this message translates to:
  /// **'الأذان مفعّل'**
  String get adhanEnabled;

  /// No description provided for @adhanDisabled.
  ///
  /// In ar, this message translates to:
  /// **'الأذان غير مفعّل'**
  String get adhanDisabled;

  /// No description provided for @stopPreview.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف المعاينة'**
  String get stopPreview;

  /// No description provided for @listenAdhan.
  ///
  /// In ar, this message translates to:
  /// **'استماع للأذان'**
  String get listenAdhan;

  /// No description provided for @adhanAttribution.
  ///
  /// In ar, this message translates to:
  /// **'أصوات الأذان من Wikimedia Commons تحت رخصة CC BY-SA 4.0: Andrewler و Atcovi.'**
  String get adhanAttribution;

  /// No description provided for @verseFromSurah.
  ///
  /// In ar, this message translates to:
  /// **'الآية {ayah} من سورة {surah}'**
  String verseFromSurah(String ayah, String surah);

  /// No description provided for @playFromHere.
  ///
  /// In ar, this message translates to:
  /// **'تشغيل من هذه الآية'**
  String get playFromHere;

  /// No description provided for @removeBookmark.
  ///
  /// In ar, this message translates to:
  /// **'حذف من العلامات'**
  String get removeBookmark;

  /// No description provided for @addBookmark.
  ///
  /// In ar, this message translates to:
  /// **'حفظ علامة هنا'**
  String get addBookmark;

  /// No description provided for @bookmarkAdded.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ العلامة.'**
  String get bookmarkAdded;

  /// No description provided for @bookmarkRemoved.
  ///
  /// In ar, this message translates to:
  /// **'تم حذف العلامة من هذا الموضع.'**
  String get bookmarkRemoved;

  /// No description provided for @easyTafsir.
  ///
  /// In ar, this message translates to:
  /// **'التفسير الميسر'**
  String get easyTafsir;

  /// No description provided for @translationEnglish.
  ///
  /// In ar, this message translates to:
  /// **'الترجمة (English)'**
  String get translationEnglish;

  /// No description provided for @shareAyah.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الآية'**
  String get shareAyah;

  /// No description provided for @tafsirOfAyah.
  ///
  /// In ar, this message translates to:
  /// **'تفسير الآية {ayah}'**
  String tafsirOfAyah(String ayah);

  /// No description provided for @tafsirNotAvailable.
  ///
  /// In ar, this message translates to:
  /// **'التفسير غير متوفر لهذه الآية.'**
  String get tafsirNotAvailable;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @readingSettings.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات القراءة'**
  String get readingSettings;

  /// No description provided for @useQcfFont.
  ///
  /// In ar, this message translates to:
  /// **'استخدام خط المصحف العثماني (QCF)'**
  String get useQcfFont;

  /// No description provided for @qcfFontDesc.
  ///
  /// In ar, this message translates to:
  /// **'شكل الصفحات يطابق مصحف المدينة'**
  String get qcfFontDesc;

  /// No description provided for @normalFontSize.
  ///
  /// In ar, this message translates to:
  /// **'حجم الخط العادي: {size}'**
  String normalFontSize(String size);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
