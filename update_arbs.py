import json
import os

keys = {
  "bukhariDeleteTitle": {"en": "Delete Sahih Al-Bukhari", "fr": "Supprimer Sahih Al-Bukhari", "ar": "حذف صحيح البخاري"},
  "bukhariDeleteContent": {"en": "Are you sure you want to delete Sahih Al-Bukhari from your device? You will need internet to download it again.", "fr": "Voulez-vous vraiment supprimer Sahih Al-Bukhari ? Vous aurez besoin d'Internet pour le retélécharger.", "ar": "هل أنت متأكد أنك تريد حذف كتاب صحيح البخاري من جهازك؟ ستحتاج إلى إنترنت لتحميله مرة أخرى."},
  "bukhariNoBooksError": {"en": "No books found in the database. Please ensure the file is downloaded.", "fr": "Aucun livre trouvé. Veuillez vous assurer que le fichier est téléchargé.", "ar": "لم يتم العثور على أي كتب في قاعدة البيانات. تأكد من تحميل الملف."},
  "bukhariDownloading": {"en": "Downloading Sahih Al-Bukhari...", "fr": "Téléchargement de Sahih Al-Bukhari...", "ar": "جاري تحميل صحيح البخاري..."},
  "bukhariDownloadWait": {"en": "Please wait, approximate size is 9MB", "fr": "Veuillez patienter, la taille est d'environ 9 Mo", "ar": "نرجو الانتظار، الحجم التقريبي 9 ميغابايت"},
  "bukhariDescription": {"en": "Contains over 7000 hadiths.\nDownload the book now to browse hadiths offline at any time.", "fr": "Contient plus de 7000 hadiths.\nTéléchargez le livre pour les consulter hors ligne.", "ar": "يحتوي على أكثر من 7000 حديث شريف.\nقم بتحميل الكتاب الآن لتصفح الأحاديث بدون إنترنت في أي وقت."},
  "bukhariDownloadBtn": {"en": "Download Book (9.4MB)", "fr": "Télécharger le livre (9.4 Mo)", "ar": "تحميل الكتاب (9.4MB)"},
  "bukhariHadiths": {"en": "Hadiths: {count}", "fr": "Hadiths : {count}", "ar": "الأحاديث: {count}"},
  "@bukhariHadiths": {"placeholders": {"count": {"type": "int"}}},
  "hadithNumber": {"en": "Hadith No. {number}", "fr": "Hadith No. {number}", "ar": "حديث رقم {number}"},
  "@hadithNumber": {"placeholders": {"number": {"type": "int"}}},
  "bukhariSearchHint": {"en": "Search by hadith number or word...", "fr": "Rechercher par numéro ou par mot...", "ar": "ابحث برقم الحديث أو الكلمة..."},
  "bukhariSearchEmptyText": {"en": "Type a hadith number (e.g. 1) \nor a word to search for", "fr": "Tapez un numéro de hadith (ex. 1)\nou un mot à rechercher", "ar": "اكتب رقم الحديث (مثال: 1) \nأو كلمة للبحث عنها"},
  "bukhariSearchNoResults": {"en": "No results found matching your search", "fr": "Aucun résultat trouvé pour votre recherche", "ar": "لم يتم العثور على نتائج تطابق بحثك"},
  "unknownBook": {"en": "Unknown Book", "fr": "Livre Inconnu", "ar": "كتاب غير معروف"},
  "adhanCompleteSetup": {"en": "Complete Adhan Setup", "fr": "Terminer la configuration de l'Adhan", "ar": "إكمال تفعيل الأذان"},
  "adhanCompleteSetupContent": {"en": "The app will request notifications, exact time, do not disturb limits, and battery exclusions, then reschedule the Adhan.", "fr": "L'application demandera des autorisations pour programmer l'Adhan.", "ar": "سيطلب التطبيق تفعيل التنبيهات والوقت الدقيق وتجاوز عدم الإزعاج واستثناء البطارية، ثم يعيد برمجة الأذان حتى يعمل في وقته."},
  "adhanStartSetup": {"en": "Start Setup", "fr": "Démarrer", "ar": "ابدأ الإعداد"},
  "adhanSoundSet": {"en": "Adhan sound set: {sound}", "fr": "Son d'Adhan défini : {sound}", "ar": "تم اعتماد صوت الأذان: {sound}"},
  "@adhanSoundSet": {"placeholders": {"sound": {"type": "String"}}},
  "adhanSoundPickError": {"en": "Failed to pick audio file. Try again.", "fr": "Impossible de choisir le fichier audio. Réessayez.", "ar": "تعذر اختيار الملف الصوتي. حاول مرة أخرى."},
  "adhanStatusTitle": {"en": "Adhan and Notification Status", "fr": "Statut de l'Adhan et des Notifications", "ar": "حالة الأذان والتنبيهات"},
  "refreshStatus": {"en": "Refresh Status", "fr": "Actualiser le statut", "ar": "تحديث الحالة"},
  "adhanNotificationsPerm": {"en": "Notifications Permission", "fr": "Permission de Notifications", "ar": "إذن التنبيهات"},
  "enabled": {"en": "Enabled", "fr": "Activé", "ar": "مفعّل"},
  "adhanNotificationsPermDesc": {"en": "Required to show Adhan alerts", "fr": "Requis pour afficher les alertes d'Adhan", "ar": "يلزم تفعيله لإظهار تنبيهات الأذان"},
  "adhanExactTimePerm": {"en": "Exact Time Alarms", "fr": "Alarmes à heure exacte", "ar": "التنبيه في الوقت الدقيق"},
  "adhanExactTimeOk": {"en": "Enabled for exact time", "fr": "Activé pour l'heure exacte", "ar": "مفعّل للوقت الدقيق"},
  "adhanExactTimePermDesc": {"en": "Adhan may be delayed if not enabled", "fr": "L'Adhan peut être retardé s'il n'est pas activé", "ar": "قد يتأخر الأذان إذا بقي غير مفعّل"},
  "adhanDndPerm": {"en": "Bypass Do Not Disturb", "fr": "Ignorer Ne pas déranger", "ar": "تجاوز عدم الإزعاج"},
  "allowed": {"en": "Allowed", "fr": "Autorisé", "ar": "مسموح"},
  "adhanDndPermDesc": {"en": "Optional when alarms are muted", "fr": "Optionnel lorsque les alarmes sont en mode muet", "ar": "اختياري عند منع أصوات المنبهات"},
  "adhanBatteryPerm": {"en": "Battery Optimization", "fr": "Optimisation Batterie", "ar": "استثناء البطارية"},
  "adhanBatteryOk": {"en": "Excluded from saving", "fr": "Exclu de l'économie d'énergie", "ar": "مستثنى من التوفير"},
  "adhanBatteryPermDesc": {"en": "Helps Adhan run in the background", "fr": "Aide l'Adhan à s'exécuter en arrière-plan", "ar": "يساعد على استمرار الأذان في الخلفية"},
  "adhanLocationPerm": {"en": "Saved Location", "fr": "Position Enregistrée", "ar": "الموقع المحفوظ"},
  "found": {"en": "Found", "fr": "Trouvé", "ar": "موجود"},
  "adhanLocationPermDesc": {"en": "Open Home to set Prayer times", "fr": "Ouvrez l'Accueil pour définir les heures de prière", "ar": "افتح الرئيسية لتحديد المواقيت"},
  "adhanScheduled": {"en": "Scheduled Alerts", "fr": "Alertes programmées", "ar": "التنبيهات المبرمجة"},
  "adhanScheduledCount": {"en": "{count} alerts", "fr": "{count} alertes", "ar": "{count} تنبيه"},
  "@adhanScheduledCount": {"placeholders": {"count": {"type": "int"}}},
  "adhanScheduledNotYet": {"en": "Alerts not scheduled yet", "fr": "Les alertes ne sont pas encore programmées", "ar": "لم تتم برمجة التنبيهات بعد"},
  "adhanBgTip": {"en": "Adhan works like a background alarm. If Do Not Disturb blocks alarms, enable the bypass permission and reschedule.", "fr": "L'Adhan fonctionne comme une alarme en arrière-plan. Si le mode Ne pas déranger bloque les alarmes, activez le contournement.", "ar": "يعمل الأذان كمنبه في الخلفية. إذا كان وضع عدم الإزعاج يمنع أصوات المنبهات، فعّل إذن تجاوز عدم الإزعاج ثم أعد البرمجة."},
  "enableNotifications": {"en": "Enable Notifications", "fr": "Activer", "ar": "تفعيل التنبيهات"},
  "enableExactAlarm": {"en": "Enable Exact Time", "fr": "Heure exact", "ar": "تفعيل الوقت الدقيق"},
  "bypassDnd": {"en": "Bypass DND", "fr": "Contourner NPD", "ar": "تجاوز عدم الإزعاج"},
  "setupBattery": {"en": "Setup Battery", "fr": "Batterie", "ar": "إعداد البطارية"},
  "rescheduleAdhan": {"en": "Reschedule", "fr": "Reprogrammer", "ar": "إعادة البرمجة"},
  "adhanRescheduleSuccess": {"en": "Adhan schedule updated.", "fr": "Les horaires de l'Adhan ont été mis à jour.", "ar": "تم تحديث برمجة الأذان والتنبيهات."},
  "adhanRescheduleNoLocation": {"en": "No location saved. Open the main page to set prayer times.", "fr": "Aucune position enregistrée. Ouvrez la page principale.", "ar": "لا يوجد موقع محفوظ بعد. افتح الصفحة الرئيسية لتحديد مواقيت الصلاة."},
  "adhanPolicySuccess": {"en": "Permission granted, click Reschedule to update Adhan alerts.", "fr": "Permission accordée, cliquez sur Reprogrammer.", "ar": "بعد منح الإذن، اضغط إعادة البرمجة لتحديث تنبيهات الأذان."},
  "adhanUploadSound": {"en": "Add Adhan from Phone", "fr": "Ajouter un Adhan depuis le téléphone", "ar": "إضافة أذان من الهاتف"},
  "adhanUploadSoundDesc": {"en": "Choose an audio file to use for Adhan", "fr": "Choisissez un fichier audio à utiliser pour l'Adhan", "ar": "اختر ملفا صوتيا ليستعمله التطبيق للأذان"},
  "adhanVolume": {"en": "Adhan Volume", "fr": "Volume de l'Adhan", "ar": "حجم صوت الأذان"},
  "prayersLabel": {"en": "Prayers", "fr": "Prières", "ar": "الصلوات"},
  "adhanPreviewError": {"en": "Failed to play Adhan preview.", "fr": "Impossible de lire l'aperçu de l'Adhan.", "ar": "تعذر تشغيل معاينة الأذان."}
}

base_path = "lib/l10n/"
langs = ["en", "fr", "ar"]

for lang in langs:
    file_path = f"{base_path}app_{lang}.arb"
    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    for key, val in keys.items():
        if key.startswith("@"):
            data[key] = val
        else:
            data[key] = val[lang]
            
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

print("Updated arbs!")
