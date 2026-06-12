import json
import os

keys = {
  "contactUsTitle": {"en": "Contact Us", "fr": "Nous contacter", "ar": "تواصل معنا"},
  "contactUsSubtitle": {"en": "Have a suggestion or facing an issue?", "fr": "Vous avez une suggestion ou un problème ?", "ar": "هل لديك اقتراح أو واجهتك مشكلة؟"},
  "contactUsFeedbackDesc": {"en": "We are happy to receive your feedback to improve the app.", "fr": "Nous sommes ravis de recevoir vos commentaires pour améliorer l'application.", "ar": "نسعد باستقبال ملاحظاتك لتطوير التطبيق وتقديم تجربة أفضل."},
  "formspreeError": {"en": "Please configure Formspree URL in code first", "fr": "Veuillez d'abord configurer l'URL Formspree dans le code", "ar": "الرجاء إعداد رابط Formspree في الكود أولاً"},
  "sendSuccess": {"en": "Sent successfully!\nThank you for contacting us.", "fr": "Envoyé avec succès !\nMerci de nous avoir contactés.", "ar": "تم الإرسال بنجاح!\nشكراً لك على تواصلك معنا."},
  "messageType": {"en": "Message Type (Suggestion / Bug Report)", "fr": "Type de message (Suggestion / Rapport de bug)", "ar": "نوع الرسالة (اقتراح / تبليغ عن خطأ)"},
  "subjectHint": {"en": "e.g. Issue with Surah Al-Kahf...", "fr": "ex: Problème avec la sourate Al-Kahf...", "ar": "مثال: مشكلة في تلاوة سورة الكهف..."},
  "requiredField": {"en": "This field is required", "fr": "Ce champ est requis", "ar": "هذا الحقل مطلوب"},
  "messageText": {"en": "Message Content", "fr": "Contenu du message", "ar": "نص الرسالة"},
  "messageHint": {"en": "Write your message details here...", "fr": "Écrivez les détails de votre message ici...", "ar": "اكتب تفاصيل الرسالة هنا..."},
  "sendBtn": {"en": "Send Message Now", "fr": "Envoyer le message maintenant", "ar": "إرسال رسالة الآن"},
  "sendError": {"en": "Error sending. Check your internet connection.", "fr": "Erreur d'envoi. Vérifiez votre connexion Internet.", "ar": "حدث خطأ أثناء الإرسال، تحقق من اتصالك بالإنترنت."},
  "tajweedRulesTitle": {"en": "Colored Tajweed Rules", "fr": "Règles de Tajweed colorées", "ar": "أحكام التجويد الملونة"},
  "allCategory": {"en": "All", "fr": "Tout", "ar": "الكل"},
  "enableTajweedMushaf": {"en": "Enable Tajweed Mushaf", "fr": "Activer le Mushaf de Tajweed", "ar": "تفعيل مصحف التجويد"},
  "enableTajweedMushafDesc": {"en": "Show colors to facilitate recitation.", "fr": "Afficher les couleurs pour faciliter la récitation.", "ar": "إظهار الألوان لتسهيل الترتيل."},
  "tajweedNoteColor": {"en": "Note: Colors appear in 'Normal Font'. Disable Uthmani Font (QCF) from reading settings.", "fr": "Remarque : Les couleurs apparaissent dans la 'Police normale'. Désactivez la police Uthmani (QCF).", "ar": "ملاحظة: الألوان تظهر في \"الخط العادي\". قم بتعطيل الخط العثماني (QCF) من إعدادات القراءة."},
  "searchTajweedHint": {"en": "Search for a Tajweed rule...", "fr": "Rechercher une règle...", "ar": "ابحث عن حكم تجويدي..."},
  "noResultsFound": {"en": "No results found", "fr": "Aucun résultat trouvé", "ar": "لم يتم العثور على نتائج"}
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

print("Updated arbs2!")
