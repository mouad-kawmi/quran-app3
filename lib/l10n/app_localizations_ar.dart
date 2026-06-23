// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'نور القرآن';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة / Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get themeMode => 'المظهر';

  @override
  String get lightTheme => 'الوضع النهاري';

  @override
  String get darkTheme => 'الوضع الليلي';

  @override
  String get systemTheme => 'حسب الجهاز';

  @override
  String get more => 'المزيد';

  @override
  String get home => 'الرئيسية';

  @override
  String get quran => 'القرآن';

  @override
  String get search => 'البحث';

  @override
  String get adhkar => 'الأذكار';

  @override
  String get adhkarDesc => 'تحصين المسلم';

  @override
  String get quranDesc => 'تلاوة وترجمة';

  @override
  String get detectingLocation => 'تحديد الموقع';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get appSubtitle => 'رفيقك في تدبر الذكر الحكيم';

  @override
  String get currentAdhan => 'الأذان الحالي';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get elapsedSinceAdhan => 'مضى على الأذان';

  @override
  String get remainingForAdhan => 'متبقي';

  @override
  String get locationErrorHint => 'حدث خطأ أثناء قراءة الموقع. حاول مرة أخرى.';

  @override
  String get adhanNeedsSetup => 'الأذان يحتاج إكمال الإعداد';

  @override
  String get adhanNeedsSetupDesc =>
      'فعّل التنبيهات والوقت الدقيق واستثناء البطارية مرة واحدة لتتمتع بتجربة أذان متكاملة و يشتغل التطبيق في الخلفية.';

  @override
  String get notifications => 'التنبيهات';

  @override
  String get exactTime => 'الوقت الدقيق';

  @override
  String get doNotDisturb => 'عدم الإزعاج';

  @override
  String get battery => 'البطارية';

  @override
  String get location => 'الموقع';

  @override
  String get scheduling => 'البرمجة';

  @override
  String get completeSetup => 'إكمال الإعداد';

  @override
  String get mainServices => 'الخدمات الرئيسية';

  @override
  String get continueReading => 'متابعة القراءة';

  @override
  String get fullList => 'القائمة كاملة';

  @override
  String get ayahOfTheDay => 'آية اليوم';

  @override
  String get share => 'شارك';

  @override
  String get khatmaProgress => 'نسبة الإنجاز والورد اليومي';

  @override
  String get surahList => 'الفهرس';

  @override
  String get allSurahs => 'جميع سور القرآن';

  @override
  String get newKhatma => 'ختمة جديدة';

  @override
  String get startOrganizedReading => 'ابدأ قراءة منظمة';

  @override
  String get determineQibla => 'تحديد اتجاه الصلاة';

  @override
  String khatmaState(int percent, int page) {
    return '$percent٪ . الصفحة $page';
  }

  @override
  String get setupAdhanNow => 'إعداد الأذان الآن';

  @override
  String get later => 'لاحقا';

  @override
  String get religiousTools => 'الأدوات الدينية';

  @override
  String get continueKhatma => 'متابعة الختمة';

  @override
  String get startKhatma => 'ابدأ الختمة';

  @override
  String get khatmaCompleted => 'الختمة مكتملة';

  @override
  String khatmaDayAndPage(int day, int page) {
    return 'اليوم $day • الصفحة $page';
  }

  @override
  String get chooseKhatmaPlan => 'اختر خطة الختمة';

  @override
  String khatmaPagesRead(int count) {
    return '$count/604 صفحة مقروءة';
  }

  @override
  String get khatmaDaysOptions => '15 أو 30 أو 60 يوم';

  @override
  String get openPosition => 'فتح الموضع';

  @override
  String get choosePlan => 'اختيار خطة';

  @override
  String get lastRead => 'آخر ما قرأت';

  @override
  String get startReading => 'ابدأ القراءة';

  @override
  String surahName(String name) {
    return 'سورة $name';
  }

  @override
  String get chooseSurahFromList => 'اختر سورة من القائمة';

  @override
  String stoppedAtAyah(int ayah) {
    return 'توقفت عند الآية $ayah';
  }

  @override
  String get prayerTimes => 'مواقيت الصلاة';

  @override
  String get prayerTimesDesc => 'جميع أوقات اليوم من الفجر إلى العشاء';

  @override
  String get qibla => 'القبلة';

  @override
  String get qiblaDesc => 'تحديد اتجاه مكة المكرمة';

  @override
  String get khatma => 'الختمة';

  @override
  String get khatmaDesc => '15 يوم، 30 يوم، أو 60 يوم مع تتبع الصفحات';

  @override
  String get downloadedAudio => 'الصوتيات المحملة';

  @override
  String get downloadedAudioDesc => 'السور المحملة للاستماع دون إنترنت';

  @override
  String get asmaUlHusna => 'أسماء الله الحسنى';

  @override
  String get asmaUlHusnaDesc => 'تصفح الأسماء التسعة والتسعين مع معانيها';

  @override
  String get sunnahReminders => 'تنبيهات السنن';

  @override
  String get sunnahRemindersDesc =>
      'تذكيرات بسورة الكهف والملك والأذكار والصيام';

  @override
  String get sahihBukhari => 'صحيح البخاري';

  @override
  String get sahihBukhariDesc => 'الأحاديث النبوية الشريفة';

  @override
  String get adhan => 'الأذان';

  @override
  String get adhanDesc => 'اختيار الصوت وتحديد الصلوات';

  @override
  String get tajweedRules => 'أحكام التجويد الملونة';

  @override
  String get tajweedRulesDesc => 'تعلم أحكام التجويد وإدارة الألوان';

  @override
  String get fontSize => 'حجم الخط';

  @override
  String currentSize(String size) {
    return 'الحجم الحالي: $size';
  }

  @override
  String get chooseFontSize => 'اختر حجما مناسبا للقرآن والأذكار وباقي النصوص.';

  @override
  String get small => 'صغير';

  @override
  String get large => 'كبير';

  @override
  String get medium => 'متوسط';

  @override
  String get normal => 'عادي';

  @override
  String get resetToNormalSize => 'العودة للحجم العادي';

  @override
  String get aboutApp => 'عن التطبيق';

  @override
  String get contactUs => 'تواصل معنا';

  @override
  String get contactUsDesc => 'أرسل رسالة للإبلاغ عن خطأ أو لاقتراح جديد';

  @override
  String get exactlyAboutApp => 'حول التطبيق';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get shareApp => 'شارك التطبيق';

  @override
  String get shareAppDesc => 'انشر الخير مع أصدقائك';

  @override
  String get shareAppMsg =>
      'جرّب تطبيق نور القرآن للقرآن الكريم، مواقيت الصلاة، الأذكار والقبلة.';

  @override
  String dhikrCount(int count) {
    return '$count ذكراً';
  }

  @override
  String get resetAll => 'إعادة الكل';

  @override
  String get resetItem => 'إعادة من الأول';

  @override
  String get tapToRepeat => 'اضغط للإعادة';

  @override
  String repetitions(int count) {
    return 'التكرار: $count';
  }

  @override
  String get prayerTimesError => 'تعذر جلب مواقيت الصلاة الآن. حاول مرة أخرى.';

  @override
  String officialSource(String name) {
    return 'مصدر رسمي: $name';
  }

  @override
  String get officialSourceNote =>
      'المواقيت مجلوبة من صفحة وزارة الأوقاف عند توفر الاتصال.';

  @override
  String get fallbackSourceNote =>
      'تعذر الاتصال بموقع الوزارة، لذلك استعملنا الحساب المحلي مؤقتاً.';

  @override
  String get refresh => 'تحديث';

  @override
  String get quranSurahs => 'سور القرآن الكريم';

  @override
  String get downloadedAudioTooltip => 'الصوتيات المحملة';

  @override
  String get indexTooltip => 'الفهرس';

  @override
  String get bookmarksTooltip => 'العلامات';

  @override
  String get searchTooltip => 'البحث';

  @override
  String ayahCount(int count) {
    return '$count آية';
  }

  @override
  String get quranIndex => 'فهرس القرآن';

  @override
  String get juzTab => 'الأجزاء';

  @override
  String get hizbTab => 'الأحزاب';

  @override
  String get pagesTab => 'الصفحات';

  @override
  String juzTitle(int n) {
    return 'الجزء $n';
  }

  @override
  String hizbTitle(int n) {
    return 'الحزب $n';
  }

  @override
  String pageTitle(int n) {
    return 'الصفحة $n';
  }

  @override
  String juzStartsAt(String surah, int ayah, int page) {
    return 'يبدأ من سورة $surah • الآية $ayah • الصفحة $page';
  }

  @override
  String hizbFromPage(int page, String surah) {
    return 'من الصفحة $page • سورة $surah';
  }

  @override
  String get searchInQuran => 'البحث في القرآن';

  @override
  String get searchHint => 'اكتب كلمة للبحث...';

  @override
  String get results => 'النتائج';

  @override
  String resultCount(int count) {
    return '$count نتيجة';
  }

  @override
  String get searchEmptyTitle => 'ابحث عن أي كلمة';

  @override
  String get searchEmptySubtitle =>
      'البحث يعمل دون إنترنت ويشمل آيات القرآن كاملة.';

  @override
  String get searchNoResultsTitle => 'عذراً، لم نجد نتائج';

  @override
  String get searchNoResultsSubtitle => 'حاول بكلمة أخرى أو اكتبها دون تشكيل.';

  @override
  String page(int n) {
    return 'ص $n';
  }

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get fallbackCityName => 'الرباط';

  @override
  String get fallbackLocationNotice =>
      'المواقيت محسوبة الآن على الرباط. فعّل خدمة الموقع واضغط على شارة الموقع لتحديد مدينتك.';

  @override
  String get storedLocationNotice =>
      'المواقيت محسوبة على آخر موقع محفوظ. يعمل التطبيق دون خدمة الموقع ودون إنترنت.';

  @override
  String get unavailableLocationNotice =>
      'المواقيت معتمدة على آخر موقع محفوظ لأن خدمة الموقع غير متاحة الآن. يعمل التطبيق دون إنترنت.';

  @override
  String get locationServiceDisabled =>
      'فعّل خدمة الموقع لحساب المواقيت حسب مدينتك.';

  @override
  String get locationPermissionNeeded =>
      'يحتاج التطبيق إلى إذن الموقع لعرض المواقيت الصحيحة.';

  @override
  String get locationPermissionDenied =>
      'إذن الموقع مرفوض بشكل دائم. افتح إعدادات الهاتف وفعّل الإذن للتطبيق.';

  @override
  String get locationTimeoutError =>
      'تعذر الحصول على الموقع الآن. فعّل خدمة الموقع وحاول مرة أخرى.';

  @override
  String get reciterMishari => 'مشاري راشد العفاسي';

  @override
  String get reciterMishariShort => 'العفاسي';

  @override
  String get reciterMinshawi => 'محمد صديق المنشاوي';

  @override
  String get reciterMinshawiShort => 'المنشاوي';

  @override
  String get reciterHusari => 'محمود خليل الحصري';

  @override
  String get reciterHusariShort => 'الحصري';

  @override
  String get reciterAbdulBasit => 'عبد الباسط عبد الصمد';

  @override
  String get reciterAbdulBasitShort => 'عبد الباسط';

  @override
  String get reciterAlHudhayfi => 'علي الحذيفي';

  @override
  String get reciterAlHudhayfiShort => 'الحذيفي';

  @override
  String get reciterMuhammadAyyub => 'محمد أيوب';

  @override
  String get reciterMuhammadAyyubShort => 'محمد أيوب';

  @override
  String get wordTranslation => 'الترجمة (Saheeh International)';

  @override
  String get play => 'تشغيل';

  @override
  String get interpretation => 'التفسير';

  @override
  String get deleteAudioTitle => 'حذف الصوت؟';

  @override
  String deleteAudioContent(String surah, String reciter) {
    return 'سيتم حذف صوت سورة $surah بصوت $reciter من الجهاز.';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get noDownloadedAudioTitle => 'لا توجد صوتيات محملة بعد';

  @override
  String get noDownloadedAudioDesc =>
      'افتح أي سورة واضغط زر التحميل بجانب المشغل، وستظهر هنا للاستماع إليها دون إنترنت.';

  @override
  String get openSurah => 'فتح السورة';

  @override
  String get deleteAudio => 'حذف الصوت';

  @override
  String get asmaUlHusnaAyah =>
      'وَلِلَّهِ الْأَسْمَاءُ الْحُسْنَى فَادْعُوهُ بِهَا';

  @override
  String get asmaUlHusnaAyahRef => '— سورة الأعراف: 180';

  @override
  String get searchNameHint => 'ابحث عن اسم...';

  @override
  String get meaningAndSignificance => 'المعنى والدلالة';

  @override
  String get asmaUlHusnaDhikrTip =>
      'يُستحب الإكثار من ذكر هذا الاسم في الدعاء والتسبيح لما فيه من معاني التقرب إلى الله تعالى.';

  @override
  String get bukhariDeleteTitle => 'حذف صحيح البخاري';

  @override
  String get bukhariDeleteContent =>
      'هل أنت متأكد أنك تريد حذف كتاب صحيح البخاري من جهازك؟ ستحتاج إلى إنترنت لتحميله مرة أخرى.';

  @override
  String get bukhariNoBooksError =>
      'لم يتم العثور على أي كتب في قاعدة البيانات. تأكد من تحميل الملف.';

  @override
  String get bukhariDownloading => 'جاري تحميل صحيح البخاري...';

  @override
  String get bukhariDownloadWait => 'نرجو الانتظار، الحجم التقريبي 9 ميغابايت';

  @override
  String get bukhariDescription =>
      'يحتوي على أكثر من 7000 حديث شريف.\nقم بتحميل الكتاب الآن لتصفح الأحاديث بدون إنترنت في أي وقت.';

  @override
  String get bukhariDownloadBtn => 'تحميل الكتاب (9.4MB)';

  @override
  String bukhariHadiths(int count) {
    return 'الأحاديث: $count';
  }

  @override
  String hadithNumber(int number) {
    return 'حديث رقم $number';
  }

  @override
  String get bukhariSearchHint => 'ابحث برقم الحديث أو الكلمة...';

  @override
  String get bukhariSearchEmptyText =>
      'اكتب رقم الحديث (مثال: 1) \nأو كلمة للبحث عنها';

  @override
  String get bukhariSearchNoResults => 'لم يتم العثور على نتائج تطابق بحثك';

  @override
  String get unknownBook => 'كتاب غير معروف';

  @override
  String get adhanCompleteSetup => 'إكمال تفعيل الأذان';

  @override
  String get adhanCompleteSetupContent =>
      'سيطلب التطبيق تفعيل التنبيهات والوقت الدقيق وتجاوز عدم الإزعاج واستثناء البطارية، ثم يعيد برمجة الأذان حتى يعمل في وقته.';

  @override
  String get adhanStartSetup => 'ابدأ الإعداد';

  @override
  String adhanSoundSet(String sound) {
    return 'تم اعتماد صوت الأذان: $sound';
  }

  @override
  String get adhanSoundPickError => 'تعذر اختيار الملف الصوتي. حاول مرة أخرى.';

  @override
  String get adhanStatusTitle => 'حالة الأذان والتنبيهات';

  @override
  String get refreshStatus => 'تحديث الحالة';

  @override
  String get adhanNotificationsPerm => 'إذن التنبيهات';

  @override
  String get enabled => 'مفعّل';

  @override
  String get adhanNotificationsPermDesc => 'يلزم تفعيله لإظهار تنبيهات الأذان';

  @override
  String get adhanExactTimePerm => 'التنبيه في الوقت الدقيق';

  @override
  String get adhanExactTimeOk => 'مفعّل للوقت الدقيق';

  @override
  String get adhanExactTimePermDesc => 'قد يتأخر الأذان إذا بقي غير مفعّل';

  @override
  String get adhanDndPerm => 'تجاوز عدم الإزعاج';

  @override
  String get allowed => 'مسموح';

  @override
  String get adhanDndPermDesc => 'اختياري عند منع أصوات المنبهات';

  @override
  String get adhanBatteryPerm => 'استثناء البطارية';

  @override
  String get adhanBatteryOk => 'مستثنى من التوفير';

  @override
  String get adhanBatteryPermDesc => 'يساعد على استمرار الأذان في الخلفية';

  @override
  String get adhanLocationPerm => 'الموقع المحفوظ';

  @override
  String get found => 'موجود';

  @override
  String get adhanLocationPermDesc => 'افتح الرئيسية لتحديد المواقيت';

  @override
  String get adhanScheduled => 'التنبيهات المبرمجة';

  @override
  String adhanScheduledCount(int count) {
    return '$count تنبيه';
  }

  @override
  String get adhanScheduledNotYet => 'لم تتم برمجة التنبيهات بعد';

  @override
  String get adhanBgTip =>
      'يعمل الأذان كمنبه في الخلفية. إذا كان وضع عدم الإزعاج يمنع أصوات المنبهات، فعّل إذن تجاوز عدم الإزعاج ثم أعد البرمجة.';

  @override
  String get enableNotifications => 'تفعيل التنبيهات';

  @override
  String get enableExactAlarm => 'تفعيل الوقت الدقيق';

  @override
  String get bypassDnd => 'تجاوز عدم الإزعاج';

  @override
  String get setupBattery => 'إعداد البطارية';

  @override
  String get rescheduleAdhan => 'إعادة البرمجة';

  @override
  String get adhanRescheduleSuccess => 'تم تحديث برمجة الأذان والتنبيهات.';

  @override
  String get adhanRescheduleNoLocation =>
      'لا يوجد موقع محفوظ بعد. افتح الصفحة الرئيسية لتحديد مواقيت الصلاة.';

  @override
  String get adhanPolicySuccess =>
      'بعد منح الإذن، اضغط إعادة البرمجة لتحديث تنبيهات الأذان.';

  @override
  String get adhanUploadSound => 'إضافة أذان من الهاتف';

  @override
  String get adhanUploadSoundDesc => 'اختر ملفا صوتيا ليستعمله التطبيق للأذان';

  @override
  String get adhanVolume => 'حجم صوت الأذان';

  @override
  String get prayersLabel => 'الصلوات';

  @override
  String get adhanPreviewError => 'تعذر تشغيل معاينة الأذان.';

  @override
  String get contactUsTitle => 'تواصل معنا';

  @override
  String get contactUsSubtitle => 'هل لديك اقتراح أو واجهتك مشكلة؟';

  @override
  String get contactUsFeedbackDesc =>
      'نسعد باستقبال ملاحظاتك لتطوير التطبيق وتقديم تجربة أفضل.';

  @override
  String get formspreeError => 'الرجاء إعداد رابط Formspree في الكود أولاً';

  @override
  String get sendSuccess => 'تم الإرسال بنجاح!\nشكراً لك على تواصلك معنا.';

  @override
  String get messageType => 'نوع الرسالة (اقتراح / تبليغ عن خطأ)';

  @override
  String get subjectHint => 'مثال: مشكلة في تلاوة سورة الكهف...';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get messageText => 'نص الرسالة';

  @override
  String get messageHint => 'اكتب تفاصيل الرسالة هنا...';

  @override
  String get sendBtn => 'إرسال الرسالة الآن';

  @override
  String get sendError => 'حدث خطأ أثناء الإرسال، تحقق من اتصالك بالإنترنت.';

  @override
  String get tajweedRulesTitle => 'أحكام التجويد الملونة';

  @override
  String get allCategory => 'الكل';

  @override
  String get enableTajweedMushaf => 'تفعيل مصحف التجويد';

  @override
  String get enableTajweedMushafDesc => 'إظهار الألوان لتسهيل الترتيل.';

  @override
  String get tajweedNoteColor =>
      'ملاحظة: الألوان تظهر في \"الخط العادي\". قم بتعطيل الخط العثماني (QCF) من إعدادات القراءة.';

  @override
  String get searchTajweedHint => 'ابحث عن حكم تجويدي...';

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج';

  @override
  String get adhanEnabled => 'الأذان مفعّل';

  @override
  String get adhanDisabled => 'الأذان غير مفعّل';

  @override
  String get stopPreview => 'إيقاف المعاينة';

  @override
  String get listenAdhan => 'استماع للأذان';

  @override
  String get adhanAttribution =>
      'أصوات الأذان من Wikimedia Commons تحت رخصة CC BY-SA 4.0: Andrewler و Atcovi.';

  @override
  String verseFromSurah(String ayah, String surah) {
    return 'الآية $ayah من سورة $surah';
  }

  @override
  String get playFromHere => 'تشغيل من هذه الآية';

  @override
  String get removeBookmark => 'حذف من العلامات';

  @override
  String get addBookmark => 'حفظ علامة هنا';

  @override
  String get bookmarkAdded => 'تم حفظ العلامة.';

  @override
  String get bookmarkRemoved => 'تم حذف العلامة من هذا الموضع.';

  @override
  String get easyTafsir => 'التفسير الميسر';

  @override
  String get translationEnglish => 'الترجمة (English)';

  @override
  String get shareAyah => 'مشاركة الآية';

  @override
  String tafsirOfAyah(String ayah) {
    return 'تفسير الآية $ayah';
  }

  @override
  String get tafsirNotAvailable => 'التفسير غير متوفر لهذه الآية.';

  @override
  String get close => 'إغلاق';

  @override
  String get readingSettings => 'إعدادات القراءة';

  @override
  String get useQcfFont => 'استخدام خط المصحف العثماني (QCF)';

  @override
  String get qcfFontDesc => 'شكل الصفحات يطابق مصحف المدينة';

  @override
  String normalFontSize(String size) {
    return 'حجم الخط العادي: $size';
  }
}
