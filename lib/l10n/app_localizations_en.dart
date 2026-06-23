// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Noor Al-Quran';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get themeMode => 'Theme';

  @override
  String get lightTheme => 'Light Mode';

  @override
  String get darkTheme => 'Dark Mode';

  @override
  String get systemTheme => 'System Default';

  @override
  String get more => 'More';

  @override
  String get home => 'Home';

  @override
  String get quran => 'Quran';

  @override
  String get search => 'Search';

  @override
  String get adhkar => 'Adhkar';

  @override
  String get adhkarDesc => 'Muslim fortress';

  @override
  String get quranDesc => 'Recitation & Translation';

  @override
  String get detectingLocation => 'Detecting Location';

  @override
  String get retry => 'Retry';

  @override
  String get appSubtitle => 'Your companion in pondering the Holy Quran';

  @override
  String get currentAdhan => 'Current Adhan';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get elapsedSinceAdhan => 'Elapsed';

  @override
  String get remainingForAdhan => 'Remaining';

  @override
  String get locationErrorHint =>
      'An error occurred while getting location. Try again.';

  @override
  String get adhanNeedsSetup => 'Adhan Needs Setup';

  @override
  String get adhanNeedsSetupDesc =>
      'Enable notifications, exact time, and ignore battery optimization once to have a complete and background Adhan experience.';

  @override
  String get notifications => 'Notifications';

  @override
  String get exactTime => 'Exact Time';

  @override
  String get doNotDisturb => 'Do Not Disturb';

  @override
  String get battery => 'Battery';

  @override
  String get location => 'Location';

  @override
  String get scheduling => 'Scheduling';

  @override
  String get completeSetup => 'Complete Setup';

  @override
  String get mainServices => 'Main Services';

  @override
  String get continueReading => 'Continue Reading';

  @override
  String get fullList => 'Full List';

  @override
  String get ayahOfTheDay => 'Ayah of the Day';

  @override
  String get share => 'Share';

  @override
  String get khatmaProgress => 'Progress & Daily Plan';

  @override
  String get surahList => 'Index';

  @override
  String get allSurahs => 'All Quran Surahs';

  @override
  String get newKhatma => 'New Khatma';

  @override
  String get startOrganizedReading => 'Start organized reading';

  @override
  String get determineQibla => 'Determine prayer direction';

  @override
  String khatmaState(int percent, int page) {
    return '$percent% . Page $page';
  }

  @override
  String get setupAdhanNow => 'Setup Adhan Now';

  @override
  String get later => 'Later';

  @override
  String get religiousTools => 'Religious Tools';

  @override
  String get continueKhatma => 'Continue Khatma';

  @override
  String get startKhatma => 'Start Khatma';

  @override
  String get khatmaCompleted => 'Khatma Completed';

  @override
  String khatmaDayAndPage(int day, int page) {
    return 'Day $day • Page $page';
  }

  @override
  String get chooseKhatmaPlan => 'Choose Khatma Plan';

  @override
  String khatmaPagesRead(int count) {
    return '$count/604 pages read';
  }

  @override
  String get khatmaDaysOptions => '15, 30 or 60 days';

  @override
  String get openPosition => 'Open Position';

  @override
  String get choosePlan => 'Choose Plan';

  @override
  String get lastRead => 'Last Read';

  @override
  String get startReading => 'Start Reading';

  @override
  String surahName(String name) {
    return 'Surah $name';
  }

  @override
  String get chooseSurahFromList => 'Choose Surah from list';

  @override
  String stoppedAtAyah(int ayah) {
    return 'Stopped at Ayah $ayah';
  }

  @override
  String get prayerTimes => 'Prayer Times';

  @override
  String get prayerTimesDesc => 'All daily times from Fajr to Isha';

  @override
  String get qibla => 'Qibla';

  @override
  String get qiblaDesc => 'Determine the direction of Mecca';

  @override
  String get khatma => 'Khatma';

  @override
  String get khatmaDesc => '15, 30, or 60 days with page tracking';

  @override
  String get downloadedAudio => 'Downloaded Audio';

  @override
  String get downloadedAudioDesc => 'Downloaded Surahs for offline listening';

  @override
  String get asmaUlHusna => 'Asma Ul Husna';

  @override
  String get asmaUlHusnaDesc =>
      'Browse the 99 Names of Allah and their meanings';

  @override
  String get sunnahReminders => 'Sunnah Reminders';

  @override
  String get sunnahRemindersDesc =>
      'Reminders for Kahf, Mulk, Adhkar and Fasting';

  @override
  String get sahihBukhari => 'Sahih Al-Bukhari';

  @override
  String get sahihBukhariDesc => 'Prophetic Hadiths';

  @override
  String get adhan => 'Adhan';

  @override
  String get adhanDesc => 'Choose sound and select prayers';

  @override
  String get tajweedRules => 'Colored Tajweed Rules';

  @override
  String get tajweedRulesDesc => 'Learn Tajweed rules and manage colors';

  @override
  String get fontSize => 'Font Size';

  @override
  String currentSize(String size) {
    return 'Current size: $size';
  }

  @override
  String get chooseFontSize =>
      'Choose a suitable size for Quran, Adhkar and texts.';

  @override
  String get small => 'Small';

  @override
  String get large => 'Large';

  @override
  String get medium => 'Medium';

  @override
  String get normal => 'Normal';

  @override
  String get resetToNormalSize => 'Reset to normal size';

  @override
  String get aboutApp => 'About the App';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get contactUsDesc =>
      'Send a message to report a bug or suggest a feature';

  @override
  String get exactlyAboutApp => 'About App';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get shareApp => 'Share App';

  @override
  String get shareAppDesc => 'Spread goodness with your friends';

  @override
  String get shareAppMsg =>
      'Try the Noor Al-Quran app for the Holy Quran, prayer times, adhkar, and the qibla.';

  @override
  String dhikrCount(int count) {
    return '$count dhikr';
  }

  @override
  String get resetAll => 'Reset All';

  @override
  String get resetItem => 'Reset';

  @override
  String get tapToRepeat => 'Tap to repeat';

  @override
  String repetitions(int count) {
    return 'Repetitions: $count';
  }

  @override
  String get prayerTimesError => 'Could not fetch prayer times. Try again.';

  @override
  String officialSource(String name) {
    return 'Official source: $name';
  }

  @override
  String get officialSourceNote =>
      'Times are retrieved from the Ministry of Awqaf when connected.';

  @override
  String get fallbackSourceNote =>
      'Could not connect to the ministry website, using local calculation temporarily.';

  @override
  String get refresh => 'Refresh';

  @override
  String get quranSurahs => 'Quran Surahs';

  @override
  String get downloadedAudioTooltip => 'Downloaded Audio';

  @override
  String get indexTooltip => 'Index';

  @override
  String get bookmarksTooltip => 'Bookmarks';

  @override
  String get searchTooltip => 'Search';

  @override
  String ayahCount(int count) {
    return '$count ayahs';
  }

  @override
  String get quranIndex => 'Quran Index';

  @override
  String get juzTab => 'Juz';

  @override
  String get hizbTab => 'Hizb';

  @override
  String get pagesTab => 'Pages';

  @override
  String juzTitle(int n) {
    return 'Juz $n';
  }

  @override
  String hizbTitle(int n) {
    return 'Hizb $n';
  }

  @override
  String pageTitle(int n) {
    return 'Page $n';
  }

  @override
  String juzStartsAt(String surah, int ayah, int page) {
    return 'Starts at Surah $surah • Ayah $ayah • Page $page';
  }

  @override
  String hizbFromPage(int page, String surah) {
    return 'From page $page • Surah $surah';
  }

  @override
  String get searchInQuran => 'Search in Quran';

  @override
  String get searchHint => 'Type a word to search...';

  @override
  String get results => 'Results';

  @override
  String resultCount(int count) {
    return '$count result(s)';
  }

  @override
  String get searchEmptyTitle => 'Search any word';

  @override
  String get searchEmptySubtitle =>
      'Search works offline and covers all Quran verses.';

  @override
  String get searchNoResultsTitle => 'No results found';

  @override
  String get searchNoResultsSubtitle =>
      'Try another word or remove diacritics.';

  @override
  String page(int n) {
    return 'p.$n';
  }

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get fallbackCityName => 'Rabat';

  @override
  String get fallbackLocationNotice =>
      'Prayer times are calculated for Rabat. Enable location service and tap the location icon to set your city.';

  @override
  String get storedLocationNotice =>
      'Prayer times are calculated for the last saved location. The app works without location service or internet.';

  @override
  String get unavailableLocationNotice =>
      'Prayer times are based on the last saved location as location service is unavailable now. The app works without internet.';

  @override
  String get locationServiceDisabled =>
      'Enable location service to calculate prayer times for your city.';

  @override
  String get locationPermissionNeeded =>
      'The app needs location permission to display correct prayer times.';

  @override
  String get locationPermissionDenied =>
      'Location permission is permanently denied. Open phone settings and enable permission for this app.';

  @override
  String get locationTimeoutError =>
      'Unable to get location now. Enable location service and try again.';

  @override
  String get reciterMishari => 'Mishary Rashid Al-Afasy';

  @override
  String get reciterMishariShort => 'Al-Afasy';

  @override
  String get reciterMinshawi => 'Muhammad Siddiq Al-Minshawi';

  @override
  String get reciterMinshawiShort => 'Al-Minshawi';

  @override
  String get reciterHusari => 'Mahmoud Khalil Al-Hussary';

  @override
  String get reciterHusariShort => 'Al-Hussary';

  @override
  String get reciterAbdulBasit => 'Abdul Basit Abdul Samad';

  @override
  String get reciterAbdulBasitShort => 'Abdul Basit';

  @override
  String get reciterAlHudhayfi => 'Ali Al-Hudhayfi';

  @override
  String get reciterAlHudhayfiShort => 'Al-Hudhayfi';

  @override
  String get reciterMuhammadAyyub => 'Muhammad Ayyub';

  @override
  String get reciterMuhammadAyyubShort => 'Muhammad Ayyub';

  @override
  String get wordTranslation => 'Translation (Saheeh International)';

  @override
  String get play => 'Play';

  @override
  String get interpretation => 'Interpretation';

  @override
  String get deleteAudioTitle => 'Delete Audio?';

  @override
  String deleteAudioContent(String surah, String reciter) {
    return 'Audio for Surah $surah by $reciter will be deleted from the device.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get noDownloadedAudioTitle => 'No downloaded audios yet';

  @override
  String get noDownloadedAudioDesc =>
      'Open any Surah and press the download button next to the player, and it will appear here for offline listening.';

  @override
  String get openSurah => 'Open Surah';

  @override
  String get deleteAudio => 'Delete Audio';

  @override
  String get asmaUlHusnaAyah =>
      'And to Allah belong the best names, so invoke Him by them.';

  @override
  String get asmaUlHusnaAyahRef => '— Surah Al-A\'raf: 180';

  @override
  String get searchNameHint => 'Search for a name...';

  @override
  String get meaningAndSignificance => 'Meaning and Significance';

  @override
  String get asmaUlHusnaDhikrTip =>
      'It is recommended to mention this name frequently in supplication and glorification as it draws one closer to Allah.';

  @override
  String get bukhariDeleteTitle => 'Delete Sahih Al-Bukhari';

  @override
  String get bukhariDeleteContent =>
      'Are you sure you want to delete Sahih Al-Bukhari from your device? You will need internet to download it again.';

  @override
  String get bukhariNoBooksError =>
      'No books found in the database. Please ensure the file is downloaded.';

  @override
  String get bukhariDownloading => 'Downloading Sahih Al-Bukhari...';

  @override
  String get bukhariDownloadWait => 'Please wait, approximate size is 9MB';

  @override
  String get bukhariDescription =>
      'Contains over 7000 hadiths.\nDownload the book now to browse hadiths offline at any time.';

  @override
  String get bukhariDownloadBtn => 'Download Book (9.4MB)';

  @override
  String bukhariHadiths(int count) {
    return 'Hadiths: $count';
  }

  @override
  String hadithNumber(int number) {
    return 'Hadith No. $number';
  }

  @override
  String get bukhariSearchHint => 'Search by hadith number or word...';

  @override
  String get bukhariSearchEmptyText =>
      'Type a hadith number (e.g. 1) \nor a word to search for';

  @override
  String get bukhariSearchNoResults => 'No results found matching your search';

  @override
  String get unknownBook => 'Unknown Book';

  @override
  String get adhanCompleteSetup => 'Complete Adhan Setup';

  @override
  String get adhanCompleteSetupContent =>
      'The app will request notifications, exact time, do not disturb limits, and battery exclusions, then reschedule the Adhan.';

  @override
  String get adhanStartSetup => 'Start Setup';

  @override
  String adhanSoundSet(String sound) {
    return 'Adhan sound set: $sound';
  }

  @override
  String get adhanSoundPickError => 'Failed to pick audio file. Try again.';

  @override
  String get adhanStatusTitle => 'Adhan and Notification Status';

  @override
  String get refreshStatus => 'Refresh Status';

  @override
  String get adhanNotificationsPerm => 'Notifications Permission';

  @override
  String get enabled => 'Enabled';

  @override
  String get adhanNotificationsPermDesc => 'Required to show Adhan alerts';

  @override
  String get adhanExactTimePerm => 'Exact Time Alarms';

  @override
  String get adhanExactTimeOk => 'Enabled for exact time';

  @override
  String get adhanExactTimePermDesc => 'Adhan may be delayed if not enabled';

  @override
  String get adhanDndPerm => 'Bypass Do Not Disturb';

  @override
  String get allowed => 'Allowed';

  @override
  String get adhanDndPermDesc => 'Optional when alarms are muted';

  @override
  String get adhanBatteryPerm => 'Battery Optimization';

  @override
  String get adhanBatteryOk => 'Excluded from saving';

  @override
  String get adhanBatteryPermDesc => 'Helps Adhan run in the background';

  @override
  String get adhanLocationPerm => 'Saved Location';

  @override
  String get found => 'Found';

  @override
  String get adhanLocationPermDesc => 'Open Home to set Prayer times';

  @override
  String get adhanScheduled => 'Scheduled Alerts';

  @override
  String adhanScheduledCount(int count) {
    return '$count alerts';
  }

  @override
  String get adhanScheduledNotYet => 'Alerts not scheduled yet';

  @override
  String get adhanBgTip =>
      'Adhan works like a background alarm. If Do Not Disturb blocks alarms, enable the bypass permission and reschedule.';

  @override
  String get enableNotifications => 'Enable Notifications';

  @override
  String get enableExactAlarm => 'Enable Exact Time';

  @override
  String get bypassDnd => 'Bypass DND';

  @override
  String get setupBattery => 'Setup Battery';

  @override
  String get rescheduleAdhan => 'Reschedule';

  @override
  String get adhanRescheduleSuccess => 'Adhan schedule updated.';

  @override
  String get adhanRescheduleNoLocation =>
      'No location saved. Open the main page to set prayer times.';

  @override
  String get adhanPolicySuccess =>
      'Permission granted, click Reschedule to update Adhan alerts.';

  @override
  String get adhanUploadSound => 'Add Adhan from Phone';

  @override
  String get adhanUploadSoundDesc => 'Choose an audio file to use for Adhan';

  @override
  String get adhanVolume => 'Adhan Volume';

  @override
  String get prayersLabel => 'Prayers';

  @override
  String get adhanPreviewError => 'Failed to play Adhan preview.';

  @override
  String get contactUsTitle => 'Contact Us';

  @override
  String get contactUsSubtitle => 'Have a suggestion or facing an issue?';

  @override
  String get contactUsFeedbackDesc =>
      'We are happy to receive your feedback to improve the app.';

  @override
  String get formspreeError => 'Please configure Formspree URL in code first';

  @override
  String get sendSuccess => 'Sent successfully!\nThank you for contacting us.';

  @override
  String get messageType => 'Message Type (Suggestion / Bug Report)';

  @override
  String get subjectHint => 'e.g. Issue with Surah Al-Kahf...';

  @override
  String get requiredField => 'This field is required';

  @override
  String get messageText => 'Message Content';

  @override
  String get messageHint => 'Write your message details here...';

  @override
  String get sendBtn => 'Send Message Now';

  @override
  String get sendError => 'Error sending. Check your internet connection.';

  @override
  String get tajweedRulesTitle => 'Colored Tajweed Rules';

  @override
  String get allCategory => 'All';

  @override
  String get enableTajweedMushaf => 'Enable Tajweed Mushaf';

  @override
  String get enableTajweedMushafDesc => 'Show colors to facilitate recitation.';

  @override
  String get tajweedNoteColor =>
      'Note: Colors appear in \'Normal Font\'. Disable Uthmani Font (QCF) from reading settings.';

  @override
  String get searchTajweedHint => 'Search for a Tajweed rule...';

  @override
  String get noResultsFound => 'No results found';

  @override
  String get adhanEnabled => 'Adhan enabled';

  @override
  String get adhanDisabled => 'Adhan disabled';

  @override
  String get stopPreview => 'Stop preview';

  @override
  String get listenAdhan => 'Listen to Adhan';

  @override
  String get adhanAttribution =>
      'Adhan audio from Wikimedia Commons under CC BY-SA 4.0: Andrewler and Atcovi.';

  @override
  String verseFromSurah(String ayah, String surah) {
    return 'Verse $ayah from Surah $surah';
  }

  @override
  String get playFromHere => 'Play from this verse';

  @override
  String get removeBookmark => 'Remove bookmark';

  @override
  String get addBookmark => 'Add bookmark here';

  @override
  String get bookmarkAdded => 'Bookmark added.';

  @override
  String get bookmarkRemoved => 'Bookmark removed from this position.';

  @override
  String get easyTafsir => 'Easy Tafsir (Arabic)';

  @override
  String get translationEnglish => 'Translation (English)';

  @override
  String get shareAyah => 'Share verse';

  @override
  String tafsirOfAyah(String ayah) {
    return 'Tafsir of verse $ayah';
  }

  @override
  String get tafsirNotAvailable => 'Tafsir is not available for this verse.';

  @override
  String get close => 'Close';

  @override
  String get readingSettings => 'Reading Settings';

  @override
  String get useQcfFont => 'Use Uthmani QCF Font';

  @override
  String get qcfFontDesc => 'Pages match the Medina Mushaf appearance';

  @override
  String normalFontSize(String size) {
    return 'Normal font size: $size';
  }
}
