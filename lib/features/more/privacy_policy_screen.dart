import 'package:flutter/material.dart';
import 'package:quran_app/core/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = _PrivacyPolicyText.forLocale(
      Localizations.localeOf(context).languageCode,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          text.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildIntro(context, text),
          const SizedBox(height: 18),
          _buildSection(
            context,
            icon: Icons.location_on_rounded,
            title: text.locationTitle,
            body: text.locationBody,
          ),
          _buildSection(
            context,
            icon: Icons.wifi_rounded,
            title: text.internetTitle,
            body: text.internetBody,
          ),
          _buildSection(
            context,
            icon: Icons.notifications_active_rounded,
            title: text.notificationsTitle,
            body: text.notificationsBody,
          ),
          _buildSection(
            context,
            icon: Icons.mail_rounded,
            title: text.contactTitle,
            body: text.contactBody,
          ),
          _buildSection(
            context,
            icon: Icons.delete_outline_rounded,
            title: text.deletionTitle,
            body: text.deletionBody,
          ),
          _buildSection(
            context,
            icon: Icons.security_rounded,
            title: text.securityTitle,
            body: text.securityBody,
          ),
          const SizedBox(height: 8),
          Text(
            text.updated,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.mutedTextColor(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(BuildContext context, _PrivacyPolicyText text) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.privacy_tip_rounded,
            color: AppTheme.primaryColor,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            text.title,
            style: TextStyle(
              color: AppTheme.primaryTextColor(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text.intro,
            style: TextStyle(
              color: AppTheme.mutedTextColor(context),
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppTheme.isDark(context) ? 0.12 : 0.03,
            ),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: AppTheme.mutedTextColor(context),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyPolicyText {
  const _PrivacyPolicyText({
    required this.title,
    required this.intro,
    required this.locationTitle,
    required this.locationBody,
    required this.internetTitle,
    required this.internetBody,
    required this.notificationsTitle,
    required this.notificationsBody,
    required this.contactTitle,
    required this.contactBody,
    required this.deletionTitle,
    required this.deletionBody,
    required this.securityTitle,
    required this.securityBody,
    required this.updated,
  });

  final String title;
  final String intro;
  final String locationTitle;
  final String locationBody;
  final String internetTitle;
  final String internetBody;
  final String notificationsTitle;
  final String notificationsBody;
  final String contactTitle;
  final String contactBody;
  final String deletionTitle;
  final String deletionBody;
  final String securityTitle;
  final String securityBody;
  final String updated;

  static _PrivacyPolicyText forLocale(String languageCode) {
    return switch (languageCode) {
      'ar' => _ar,
      'fr' => _fr,
      _ => _en,
    };
  }

  static const _ar = _PrivacyPolicyText(
    title: 'سياسة الخصوصية',
    intro:
        'نوضح هنا كيف يستعمل تطبيق نور القرآن الأذونات والبيانات الضرورية لتقديم مواقيت الصلاة، القبلة، الأذان، والتواصل معنا.',
    locationTitle: 'الموقع',
    locationBody:
        'يستعمل التطبيق موقعك لحساب مواقيت الصلاة واتجاه القبلة. داخل المغرب يستعمل أقرب مدينة متاحة في خدمة وزارة الأوقاف عند توفر الإنترنت، وخارج المغرب يستعمل حسابا محليا حسب إحداثياتك. لا نبيع موقعك ولا نستعمله للإعلانات.',
    internetTitle: 'الإنترنت',
    internetBody:
        'يستعمل الاتصال بالإنترنت لجلب مواقيت الصلاة الرسمية من موقع وزارة الأوقاف داخل المغرب، ولإرسال رسائل التواصل عبر Formspree، ولتحميل بعض المحتوى عند طلبك.',
    notificationsTitle: 'التنبيهات والأذان',
    notificationsBody:
        'يستعمل التطبيق التنبيهات والمنبهات الدقيقة لتذكيرك بالأذان في الوقت المناسب. أذونات البطارية وعدم الإزعاج اختيارية وتستعمل فقط لتحسين موثوقية الأذان.',
    contactTitle: 'نموذج التواصل',
    contactBody:
        'عند إرسال رسالة من صفحة تواصل معنا، يتم إرسال عنوان الرسالة ونصها إلى خدمة Formspree حتى نتمكن من قراءة الملاحظة والرد عليها إذا لزم الأمر.',
    deletionTitle: 'حذف البيانات',
    deletionBody:
        'يمكنك طلب حذف الرسائل التي أرسلتها لنا عبر صفحة تواصل معنا أو البريد المخصص للدعم عند توفره في صفحة المتجر.',
    securityTitle: 'التخزين والمشاركة',
    securityBody:
        'يحفظ التطبيق بعض الإعدادات محليا على جهازك مثل آخر موقع محفوظ وإعدادات الأذان. لا نشارك هذه الإعدادات مع أطراف خارجية.',
    updated: 'آخر تحديث: يونيو 2026',
  );

  static const _en = _PrivacyPolicyText(
    title: 'Privacy Policy',
    intro:
        'This page explains how Noor Al-Quran uses permissions and data needed for prayer times, qibla direction, adhan alerts, and contact messages.',
    locationTitle: 'Location',
    locationBody:
        'The app uses your location to calculate prayer times and qibla direction. In Morocco, it uses the nearest available Ministry of Awqaf city when internet is available. Outside Morocco, it calculates locally from your coordinates. We do not sell your location or use it for ads.',
    internetTitle: 'Internet',
    internetBody:
        'Internet access is used to retrieve official Moroccan prayer times from the Ministry of Awqaf, send contact messages through Formspree, and download content when you request it.',
    notificationsTitle: 'Notifications and Adhan',
    notificationsBody:
        'The app uses notifications and exact alarms to remind you of adhan on time. Battery and Do Not Disturb permissions are optional and only improve adhan reliability.',
    contactTitle: 'Contact Form',
    contactBody:
        'When you send a message from Contact Us, the subject and message are sent to Formspree so we can read your feedback and respond if needed.',
    deletionTitle: 'Data Deletion',
    deletionBody:
        'You can request deletion of messages you sent through Contact Us or the support email listed on the store page when available.',
    securityTitle: 'Storage and Sharing',
    securityBody:
        'The app stores some settings locally on your device, such as the last saved location and adhan settings. These settings are not shared with third parties.',
    updated: 'Last updated: June 2026',
  );

  static const _fr = _PrivacyPolicyText(
    title: 'Politique de confidentialité',
    intro:
        'Cette page explique comment Noor Al-Quran utilise les permissions et les données nécessaires aux horaires de prière, à la qibla, à l’adhan et aux messages de contact.',
    locationTitle: 'Position',
    locationBody:
        'L’application utilise votre position pour calculer les horaires de prière et la direction de la qibla. Au Maroc, elle utilise la ville disponible la plus proche du Ministère des Habous quand Internet est disponible. Hors du Maroc, elle calcule localement à partir de vos coordonnées. Nous ne vendons pas votre position et ne l’utilisons pas pour la publicité.',
    internetTitle: 'Internet',
    internetBody:
        'Internet est utilisé pour récupérer les horaires officiels marocains depuis le Ministère des Habous, envoyer les messages de contact via Formspree et télécharger du contenu à votre demande.',
    notificationsTitle: 'Notifications et Adhan',
    notificationsBody:
        'L’application utilise les notifications et les alarmes exactes pour vous rappeler l’adhan à l’heure. Les permissions Batterie et Ne pas déranger sont optionnelles et servent seulement à améliorer la fiabilité de l’adhan.',
    contactTitle: 'Formulaire de contact',
    contactBody:
        'Lorsque vous envoyez un message depuis Nous contacter, le sujet et le message sont envoyés à Formspree afin que nous puissions lire votre retour et répondre si nécessaire.',
    deletionTitle: 'Suppression des données',
    deletionBody:
        'Vous pouvez demander la suppression des messages envoyés via Nous contacter ou via l’adresse de support indiquée sur la page du store lorsqu’elle est disponible.',
    securityTitle: 'Stockage et partage',
    securityBody:
        'L’application conserve certains paramètres localement sur votre appareil, comme la dernière position enregistrée et les réglages de l’adhan. Ces paramètres ne sont pas partagés avec des tiers.',
    updated: 'Dernière mise à jour : juin 2026',
  );
}
