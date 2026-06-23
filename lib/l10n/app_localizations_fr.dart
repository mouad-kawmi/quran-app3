// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Noor Al-Quran';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get french => 'Français';

  @override
  String get themeMode => 'Thème';

  @override
  String get lightTheme => 'Mode Clair';

  @override
  String get darkTheme => 'Mode Sombre';

  @override
  String get systemTheme => 'Système';

  @override
  String get more => 'Plus';

  @override
  String get home => 'Accueil';

  @override
  String get quran => 'Coran';

  @override
  String get search => 'Recherche';

  @override
  String get adhkar => 'Adhkar';

  @override
  String get adhkarDesc => 'Citadelle du Musulman';

  @override
  String get quranDesc => 'Récitation & Traduction';

  @override
  String get detectingLocation => 'Détection en cours';

  @override
  String get retry => 'Réessayer';

  @override
  String get appSubtitle => 'Votre compagnon dans la méditation du Saint Coran';

  @override
  String get currentAdhan => 'Adhan Actuel';

  @override
  String get nextPrayer => 'Prochaine Prière';

  @override
  String get elapsedSinceAdhan => 'Écoulé';

  @override
  String get remainingForAdhan => 'Restant';

  @override
  String get locationErrorHint =>
      'Une erreur est survenue avec la position. Réessayez.';

  @override
  String get adhanNeedsSetup => 'Finalisez la Configuration';

  @override
  String get adhanNeedsSetupDesc =>
      'Activez les notifications, l\'heure exacte et l\'optimisation de batterie une fois pour profiter de l\'Adhan en arrière-plan.';

  @override
  String get notifications => 'Notifications';

  @override
  String get exactTime => 'Heure Exacte';

  @override
  String get doNotDisturb => 'Ne Pas Déranger';

  @override
  String get battery => 'Batterie';

  @override
  String get location => 'Position';

  @override
  String get scheduling => 'Programmation';

  @override
  String get completeSetup => 'Compléter';

  @override
  String get mainServices => 'Services Principaux';

  @override
  String get continueReading => 'Continuer la lecture';

  @override
  String get fullList => 'Liste Complète';

  @override
  String get ayahOfTheDay => 'Verset du Jour';

  @override
  String get share => 'Partager';

  @override
  String get khatmaProgress => 'Progression & Plan du Jour';

  @override
  String get surahList => 'Index';

  @override
  String get allSurahs => 'Toutes les sourates du Coran';

  @override
  String get newKhatma => 'Nouvelle Khatma';

  @override
  String get startOrganizedReading => 'Commencer une lecture organisée';

  @override
  String get determineQibla => 'Déterminer la direction de la prière';

  @override
  String khatmaState(int percent, int page) {
    return '$percent% . Page $page';
  }

  @override
  String get setupAdhanNow => 'Configurer l\'Adhan';

  @override
  String get later => 'Plus tard';

  @override
  String get religiousTools => 'Outils Religieux';

  @override
  String get continueKhatma => 'Continuer la Khatma';

  @override
  String get startKhatma => 'Démarrez la Khatma';

  @override
  String get khatmaCompleted => 'Khatma terminée';

  @override
  String khatmaDayAndPage(int day, int page) {
    return 'Jour $day • Page $page';
  }

  @override
  String get chooseKhatmaPlan => 'Choisir le plan de Khatma';

  @override
  String khatmaPagesRead(int count) {
    return '$count/604 pages lues';
  }

  @override
  String get khatmaDaysOptions => '15, 30 ou 60 jours';

  @override
  String get openPosition => 'Ouvrir';

  @override
  String get choosePlan => 'Choisir un plan';

  @override
  String get lastRead => 'Dernière lecture';

  @override
  String get startReading => 'Commencer à lire';

  @override
  String surahName(String name) {
    return 'Sourate $name';
  }

  @override
  String get chooseSurahFromList => 'Choisissez une Sourate';

  @override
  String stoppedAtAyah(int ayah) {
    return 'Arrêté au Verset $ayah';
  }

  @override
  String get prayerTimes => 'Heures de Prière';

  @override
  String get prayerTimesDesc => 'Toutes les heures de Fajr à Isha';

  @override
  String get qibla => 'Qibla';

  @override
  String get qiblaDesc => 'Déterminer la direction de la Mecque';

  @override
  String get khatma => 'Khatma';

  @override
  String get khatmaDesc => '15, 30 ou 60 jours avec suivi des pages';

  @override
  String get downloadedAudio => 'Audios Téléchargés';

  @override
  String get downloadedAudioDesc => 'Sourates téléchargées (hors ligne)';

  @override
  String get asmaUlHusna => 'Asma Ul Husna';

  @override
  String get asmaUlHusnaDesc => 'Parcourez les 99 noms d\'Allah';

  @override
  String get sunnahReminders => 'Rappels de la Sunna';

  @override
  String get sunnahRemindersDesc => 'Rappels pour Kahf, Mulk, Adhkar et Jeûne';

  @override
  String get sahihBukhari => 'Sahih Al-Bukhari';

  @override
  String get sahihBukhariDesc => 'Hadiths Prophétiques';

  @override
  String get adhan => 'Adhan';

  @override
  String get adhanDesc => 'Choisir le son et les prières';

  @override
  String get tajweedRules => 'Règles de Tajwid Colorées';

  @override
  String get tajweedRulesDesc => 'Apprendre le Tajwid et gérer les couleurs';

  @override
  String get fontSize => 'Taille de Police';

  @override
  String currentSize(String size) {
    return 'Taille actuelle : $size';
  }

  @override
  String get chooseFontSize =>
      'Choisissez une taille pour le Coran et les textes.';

  @override
  String get small => 'Petit';

  @override
  String get large => 'Grand';

  @override
  String get medium => 'Moyen';

  @override
  String get normal => 'Normal';

  @override
  String get resetToNormalSize => 'Réinitialiser la taille';

  @override
  String get aboutApp => 'À Propos';

  @override
  String get contactUs => 'Contactez-nous';

  @override
  String get contactUsDesc => 'Signaler un bug ou faire une suggestion';

  @override
  String get exactlyAboutApp => 'Détails';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get shareApp => 'Partager l\'application';

  @override
  String get shareAppDesc => 'Partagez le bien avec vos amis';

  @override
  String get shareAppMsg =>
      'Essayez l\'application Noor Al-Quran pour le Saint Coran, les heures de prière, les adhkar et la Qibla.';

  @override
  String dhikrCount(int count) {
    return '$count dhikr';
  }

  @override
  String get resetAll => 'Réinitialiser tout';

  @override
  String get resetItem => 'Réinitialiser';

  @override
  String get tapToRepeat => 'Appuyer pour répéter';

  @override
  String repetitions(int count) {
    return 'Répétitions : $count';
  }

  @override
  String get prayerTimesError =>
      'Impossible de récupérer les horaires. Réessayez.';

  @override
  String officialSource(String name) {
    return 'Source officielle : $name';
  }

  @override
  String get officialSourceNote =>
      'Les horaires proviennent du Ministère des Awqaf lorsque la connexion est disponible.';

  @override
  String get fallbackSourceNote =>
      'Connexion impossible avec le site du ministère, calcul local utilisé temporairement.';

  @override
  String get refresh => 'Actualiser';

  @override
  String get quranSurahs => 'Sourates du Coran';

  @override
  String get downloadedAudioTooltip => 'Audio téléchargé';

  @override
  String get indexTooltip => 'Index';

  @override
  String get bookmarksTooltip => 'Signets';

  @override
  String get searchTooltip => 'Recherche';

  @override
  String ayahCount(int count) {
    return '$count versets';
  }

  @override
  String get quranIndex => 'Index du Coran';

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
    return 'Débute à la Sourate $surah • Verset $ayah • Page $page';
  }

  @override
  String hizbFromPage(int page, String surah) {
    return 'De la page $page • Sourate $surah';
  }

  @override
  String get searchInQuran => 'Rechercher dans le Coran';

  @override
  String get searchHint => 'Tapez un mot à rechercher...';

  @override
  String get results => 'Résultats';

  @override
  String resultCount(int count) {
    return '$count résultat(s)';
  }

  @override
  String get searchEmptyTitle => 'Recherchez n\'importe quel mot';

  @override
  String get searchEmptySubtitle =>
      'La recherche fonctionne hors ligne et couvre tous les versets.';

  @override
  String get searchNoResultsTitle => 'Aucun résultat trouvé';

  @override
  String get searchNoResultsSubtitle =>
      'Essayez un autre mot ou enlevez les diacritiques.';

  @override
  String page(int n) {
    return 'p.$n';
  }

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerDhuhr => 'Dhouhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get prayerSunrise => 'Lever du soleil';

  @override
  String get fallbackCityName => 'Rabat';

  @override
  String get fallbackLocationNotice =>
      'Les horaires de prière sont calculés pour Rabat. Activez le service de localisation et appuyez sur l\'icône de localisation pour définir votre ville.';

  @override
  String get storedLocationNotice =>
      'Les horaires de prière sont calculés pour le dernier emplacement enregistré. L\'application fonctionne sans service de localisation ni Internet.';

  @override
  String get unavailableLocationNotice =>
      'Les horaires de prière sont basés sur le dernier emplacement enregistré car le service de localisation n\'est pas disponible maintenant. L\'application fonctionne sans Internet.';

  @override
  String get locationServiceDisabled =>
      'Activez le service de localisation pour calculer les horaires de prière pour votre ville.';

  @override
  String get locationPermissionNeeded =>
      'L\'application a besoin de la permission de localisation pour afficher les horaires de prière corrects.';

  @override
  String get locationPermissionDenied =>
      'La permission de localisation est définitivement refusée. Ouvrez les paramètres du téléphone et activez la permission pour cette application.';

  @override
  String get locationTimeoutError =>
      'Impossible d\'obtenir la localisation maintenant. Activez le service de localisation et réessayez.';

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
  String get wordTranslation => 'Traduction (Saheeh International)';

  @override
  String get play => 'Lecture';

  @override
  String get interpretation => 'Interprétation';

  @override
  String get deleteAudioTitle => 'Supprimer l\'audio ?';

  @override
  String deleteAudioContent(String surah, String reciter) {
    return 'L\'audio de la sourate $surah par $reciter sera supprimé de l\'appareil.';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get noDownloadedAudioTitle => 'Aucun audio téléchargé';

  @override
  String get noDownloadedAudioDesc =>
      'Ouvrez une sourate et appuyez sur le bouton de téléchargement à côté du lecteur, et il apparaîtra ici pour une écoute hors ligne.';

  @override
  String get openSurah => 'Ouvrir la sourate';

  @override
  String get deleteAudio => 'Supprimer l\'audio';

  @override
  String get asmaUlHusnaAyah =>
      'C\'est à Allah qu\'appartiennent les noms les plus beaux. Invoquez-Le par ces noms.';

  @override
  String get asmaUlHusnaAyahRef => '— Sourate Al-A\'raf : 180';

  @override
  String get searchNameHint => 'Rechercher un nom...';

  @override
  String get meaningAndSignificance => 'Signification et implications';

  @override
  String get asmaUlHusnaDhikrTip =>
      'Il est recommandé de mentionner fréquemment ce nom dans l\'invocation et la glorification car il rapproche d\'Allah.';

  @override
  String get bukhariDeleteTitle => 'Supprimer Sahih Al-Bukhari';

  @override
  String get bukhariDeleteContent =>
      'Voulez-vous vraiment supprimer Sahih Al-Bukhari ? Vous aurez besoin d\'Internet pour le retélécharger.';

  @override
  String get bukhariNoBooksError =>
      'Aucun livre trouvé. Veuillez vous assurer que le fichier est téléchargé.';

  @override
  String get bukhariDownloading => 'Téléchargement de Sahih Al-Bukhari...';

  @override
  String get bukhariDownloadWait =>
      'Veuillez patienter, la taille est d\'environ 9 Mo';

  @override
  String get bukhariDescription =>
      'Contient plus de 7000 hadiths.\nTéléchargez le livre pour les consulter hors ligne.';

  @override
  String get bukhariDownloadBtn => 'Télécharger le livre (9.4 Mo)';

  @override
  String bukhariHadiths(int count) {
    return 'Hadiths : $count';
  }

  @override
  String hadithNumber(int number) {
    return 'Hadith No. $number';
  }

  @override
  String get bukhariSearchHint => 'Rechercher par numéro ou par mot...';

  @override
  String get bukhariSearchEmptyText =>
      'Tapez un numéro de hadith (ex. 1)\nou un mot à rechercher';

  @override
  String get bukhariSearchNoResults =>
      'Aucun résultat trouvé pour votre recherche';

  @override
  String get unknownBook => 'Livre Inconnu';

  @override
  String get adhanCompleteSetup => 'Terminer la configuration de l\'Adhan';

  @override
  String get adhanCompleteSetupContent =>
      'L\'application demandera des autorisations pour programmer l\'Adhan.';

  @override
  String get adhanStartSetup => 'Démarrer';

  @override
  String adhanSoundSet(String sound) {
    return 'Son d\'Adhan défini : $sound';
  }

  @override
  String get adhanSoundPickError =>
      'Impossible de choisir le fichier audio. Réessayez.';

  @override
  String get adhanStatusTitle => 'Statut de l\'Adhan et des Notifications';

  @override
  String get refreshStatus => 'Actualiser le statut';

  @override
  String get adhanNotificationsPerm => 'Permission de Notifications';

  @override
  String get enabled => 'Activé';

  @override
  String get adhanNotificationsPermDesc =>
      'Requis pour afficher les alertes d\'Adhan';

  @override
  String get adhanExactTimePerm => 'Alarmes à heure exacte';

  @override
  String get adhanExactTimeOk => 'Activé pour l\'heure exacte';

  @override
  String get adhanExactTimePermDesc =>
      'L\'Adhan peut être retardé s\'il n\'est pas activé';

  @override
  String get adhanDndPerm => 'Ignorer Ne pas déranger';

  @override
  String get allowed => 'Autorisé';

  @override
  String get adhanDndPermDesc =>
      'Optionnel lorsque les alarmes sont en mode muet';

  @override
  String get adhanBatteryPerm => 'Optimisation Batterie';

  @override
  String get adhanBatteryOk => 'Exclu de l\'économie d\'énergie';

  @override
  String get adhanBatteryPermDesc =>
      'Aide l\'Adhan à s\'exécuter en arrière-plan';

  @override
  String get adhanLocationPerm => 'Position Enregistrée';

  @override
  String get found => 'Trouvé';

  @override
  String get adhanLocationPermDesc =>
      'Ouvrez l\'Accueil pour définir les heures de prière';

  @override
  String get adhanScheduled => 'Alertes programmées';

  @override
  String adhanScheduledCount(int count) {
    return '$count alertes';
  }

  @override
  String get adhanScheduledNotYet =>
      'Les alertes ne sont pas encore programmées';

  @override
  String get adhanBgTip =>
      'L\'Adhan fonctionne comme une alarme en arrière-plan. Si le mode Ne pas déranger bloque les alarmes, activez le contournement.';

  @override
  String get enableNotifications => 'Activer';

  @override
  String get enableExactAlarm => 'Heure exact';

  @override
  String get bypassDnd => 'Contourner NPD';

  @override
  String get setupBattery => 'Batterie';

  @override
  String get rescheduleAdhan => 'Reprogrammer';

  @override
  String get adhanRescheduleSuccess =>
      'Les horaires de l\'Adhan ont été mis à jour.';

  @override
  String get adhanRescheduleNoLocation =>
      'Aucune position enregistrée. Ouvrez la page principale.';

  @override
  String get adhanPolicySuccess =>
      'Permission accordée, cliquez sur Reprogrammer.';

  @override
  String get adhanUploadSound => 'Ajouter un Adhan depuis le téléphone';

  @override
  String get adhanUploadSoundDesc =>
      'Choisissez un fichier audio à utiliser pour l\'Adhan';

  @override
  String get adhanVolume => 'Volume de l\'Adhan';

  @override
  String get prayersLabel => 'Prières';

  @override
  String get adhanPreviewError => 'Impossible de lire l\'aperçu de l\'Adhan.';

  @override
  String get contactUsTitle => 'Nous contacter';

  @override
  String get contactUsSubtitle => 'Vous avez une suggestion ou un problème ?';

  @override
  String get contactUsFeedbackDesc =>
      'Nous sommes ravis de recevoir vos commentaires pour améliorer l\'application.';

  @override
  String get formspreeError =>
      'Veuillez d\'abord configurer l\'URL Formspree dans le code';

  @override
  String get sendSuccess =>
      'Envoyé avec succès !\nMerci de nous avoir contactés.';

  @override
  String get messageType => 'Type de message (Suggestion / Rapport de bug)';

  @override
  String get subjectHint => 'ex: Problème avec la sourate Al-Kahf...';

  @override
  String get requiredField => 'Ce champ est requis';

  @override
  String get messageText => 'Contenu du message';

  @override
  String get messageHint => 'Écrivez les détails de votre message ici...';

  @override
  String get sendBtn => 'Envoyer le message maintenant';

  @override
  String get sendError => 'Erreur d\'envoi. Vérifiez votre connexion Internet.';

  @override
  String get tajweedRulesTitle => 'Règles de Tajweed colorées';

  @override
  String get allCategory => 'Tout';

  @override
  String get enableTajweedMushaf => 'Activer le Mushaf de Tajweed';

  @override
  String get enableTajweedMushafDesc =>
      'Afficher les couleurs pour faciliter la récitation.';

  @override
  String get tajweedNoteColor =>
      'Remarque : Les couleurs apparaissent dans la \'Police normale\'. Désactivez la police Uthmani (QCF).';

  @override
  String get searchTajweedHint => 'Rechercher une règle...';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get adhanEnabled => 'Adhan activé';

  @override
  String get adhanDisabled => 'Adhan désactivé';

  @override
  String get stopPreview => 'Arrêter l\'aperçu';

  @override
  String get listenAdhan => 'Écouter l\'Adhan';

  @override
  String get adhanAttribution =>
      'Sons d\'Adhan de Wikimedia Commons sous licence CC BY-SA 4.0 : Andrewler et Atcovi.';

  @override
  String verseFromSurah(String ayah, String surah) {
    return 'Verset $ayah de la sourate $surah';
  }

  @override
  String get playFromHere => 'Jouer à partir de ce verset';

  @override
  String get removeBookmark => 'Supprimer le signet';

  @override
  String get addBookmark => 'Ajouter un signet ici';

  @override
  String get bookmarkAdded => 'Signet ajouté.';

  @override
  String get bookmarkRemoved => 'Signet supprimé de cette position.';

  @override
  String get easyTafsir => 'Tafsir Simplifié (Arabe)';

  @override
  String get translationEnglish => 'Traduction (Anglais)';

  @override
  String get shareAyah => 'Partager le verset';

  @override
  String tafsirOfAyah(String ayah) {
    return 'Tafsir du verset $ayah';
  }

  @override
  String get tafsirNotAvailable =>
      'Le Tafsir n\'est pas disponible pour ce verset.';

  @override
  String get close => 'Fermer';

  @override
  String get readingSettings => 'Paramètres de lecture';

  @override
  String get useQcfFont => 'Utiliser la police Othmani QCF';

  @override
  String get qcfFontDesc => 'La mise en page correspond au Mushaf de Médine';

  @override
  String normalFontSize(String size) {
    return 'Taille de police normale : $size';
  }
}
