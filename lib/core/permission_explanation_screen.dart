import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quran_app/core/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PermissionExplanationType {
  location,
  notifications,
  exactAlarm,
  dnd,
  battery,
}

Future<bool> showPermissionExplanationScreen(
  BuildContext context,
  PermissionExplanationType type,
) async {
  if (await _PermissionExplanationStore.shouldSkip(type)) {
    return true;
  }

  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) {
    return false;
  }

  final accepted = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (context) => PermissionExplanationScreen(type: type),
      fullscreenDialog: true,
    ),
  );
  if (accepted == true) {
    await _PermissionExplanationStore.markSeen(type);
  }
  return accepted == true;
}

class _PermissionExplanationStore {
  static const String _keyPrefix = 'permission_explanation_seen_';

  static Future<bool> shouldSkip(PermissionExplanationType type) async {
    if (type == PermissionExplanationType.location &&
        await _locationAlreadyGranted()) {
      await markSeen(type);
      return true;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(type)) ?? false;
  }

  static Future<void> markSeen(PermissionExplanationType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(type), true);
  }

  static String _key(PermissionExplanationType type) {
    return '$_keyPrefix${type.name}';
  }

  static Future<bool> _locationAlreadyGranted() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}

class PermissionExplanationScreen extends StatelessWidget {
  const PermissionExplanationScreen({
    super.key,
    required this.type,
  });

  final PermissionExplanationType type;

  @override
  Widget build(BuildContext context) {
    final text = _PermissionExplanationText.forType(
      type,
      Localizations.localeOf(context).languageCode,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          text.appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  text.icon,
                  color: AppTheme.primaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                text.title,
                style: TextStyle(
                  color: AppTheme.primaryTextColor(context),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                text.body,
                style: TextStyle(
                  color: AppTheme.mutedTextColor(context),
                  fontSize: 16,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.elevatedSurfaceColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  text.note,
                  style: TextStyle(
                    color: AppTheme.mutedTextColor(context),
                    height: 1.45,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check_rounded),
                  label: Text(text.continueLabel),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(text.laterLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionExplanationText {
  const _PermissionExplanationText({
    required this.appBarTitle,
    required this.title,
    required this.body,
    required this.note,
    required this.continueLabel,
    required this.laterLabel,
    required this.icon,
  });

  final String appBarTitle;
  final String title;
  final String body;
  final String note;
  final String continueLabel;
  final String laterLabel;
  final IconData icon;

  static _PermissionExplanationText forType(
    PermissionExplanationType type,
    String languageCode,
  ) {
    return switch (languageCode) {
      'ar' => _arabic(type),
      'fr' => _french(type),
      _ => _english(type),
    };
  }

  static _PermissionExplanationText _arabic(PermissionExplanationType type) {
    const continueLabel = 'متابعة';
    const laterLabel = 'ليس الآن';

    return switch (type) {
      PermissionExplanationType.location => const _PermissionExplanationText(
        appBarTitle: 'إذن الموقع',
        title: 'لماذا نحتاج إلى الموقع؟',
        body: 'لحساب مواقيت الصلاة واتجاه القبلة حسب موقعك.',
        note:
            'يُستعمل الموقع فقط داخل التطبيق لحساب المواقيت والقبلة، ولا نستخدمه للإعلانات أو البيع.',
        continueLabel: continueLabel,
        laterLabel: laterLabel,
        icon: Icons.my_location_rounded,
      ),
      PermissionExplanationType.notifications =>
        const _PermissionExplanationText(
          appBarTitle: 'إذن التنبيهات',
          title: 'لماذا نحتاج إلى التنبيهات؟',
          body: 'لكي يصل الأذان والتنبيهات في الوقت المحدد.',
          note:
              'يمكنك تغيير إعدادات الأذان والتنبيهات لاحقا من صفحة إعدادات الأذان.',
          continueLabel: continueLabel,
          laterLabel: laterLabel,
          icon: Icons.notifications_active_rounded,
        ),
      PermissionExplanationType.exactAlarm => const _PermissionExplanationText(
        appBarTitle: 'إذن الوقت الدقيق',
        title: 'لماذا نحتاج إلى المنبه الدقيق؟',
        body: 'لكي يصل الأذان والتنبيهات في الوقت المحدد.',
        note:
            'بدون هذا الإذن قد تصل التنبيهات متأخرة على بعض الهواتف بسبب توفير الطاقة.',
        continueLabel: continueLabel,
        laterLabel: laterLabel,
        icon: Icons.alarm_on_rounded,
      ),
      PermissionExplanationType.dnd => const _PermissionExplanationText(
        appBarTitle: 'إذن عدم الإزعاج',
        title: 'إذن اختياري للأذان',
        body:
            'إذن اختياري ليساعد الأذان على العمل حتى مع الوضع الصامت أو توفير البطارية.',
        note:
            'إذا بقي هذا الإذن غير مفعّل، سيبقى التطبيق يعمل، لكن قد لا تسمع الأذان عندما يكون الهاتف في الوضع الصامت.',
        continueLabel: continueLabel,
        laterLabel: laterLabel,
        icon: Icons.do_not_disturb_off_rounded,
      ),
      PermissionExplanationType.battery => const _PermissionExplanationText(
        appBarTitle: 'إذن البطارية',
        title: 'إذن اختياري للأذان',
        body:
            'إذن اختياري ليساعد الأذان على العمل حتى مع الوضع الصامت أو توفير البطارية.',
        note:
            'إذا كان توفير البطارية يوقف التطبيق في الخلفية، فقد تتأخر بعض تنبيهات الأذان.',
        continueLabel: continueLabel,
        laterLabel: laterLabel,
        icon: Icons.battery_charging_full_rounded,
      ),
    };
  }

  static _PermissionExplanationText _english(PermissionExplanationType type) {
    const continueLabel = 'Continue';
    const laterLabel = 'Not now';

    return switch (type) {
      PermissionExplanationType.location => const _PermissionExplanationText(
        appBarTitle: 'Location Permission',
        title: 'Why we need location',
        body: 'To calculate prayer times and qibla from your location.',
        note:
            'Location is only used inside the app for prayer times and qibla. We do not use it for ads or sell it.',
        continueLabel: continueLabel,
        laterLabel: laterLabel,
        icon: Icons.my_location_rounded,
      ),
      PermissionExplanationType.notifications =>
        const _PermissionExplanationText(
          appBarTitle: 'Notifications Permission',
          title: 'Why we need notifications',
          body: 'So adhan and reminders arrive on time.',
          note:
              'You can change adhan and reminder settings later from Adhan settings.',
          continueLabel: continueLabel,
          laterLabel: laterLabel,
          icon: Icons.notifications_active_rounded,
        ),
      PermissionExplanationType.exactAlarm => const _PermissionExplanationText(
        appBarTitle: 'Exact Alarm Permission',
        title: 'Why we need exact alarms',
        body: 'So adhan and reminders arrive on time.',
        note:
            'Without this permission, some phones may delay reminders because of battery saving.',
        continueLabel: continueLabel,
        laterLabel: laterLabel,
        icon: Icons.alarm_on_rounded,
      ),
      PermissionExplanationType.dnd => const _PermissionExplanationText(
        appBarTitle: 'Do Not Disturb Access',
        title: 'Optional adhan access',
        body:
            'Optional, so adhan can work even with silent mode or battery saving.',
        note:
            'If this stays off, the app still works, but adhan may not be heard while the phone is silent.',
        continueLabel: continueLabel,
        laterLabel: laterLabel,
        icon: Icons.do_not_disturb_off_rounded,
      ),
      PermissionExplanationType.battery => const _PermissionExplanationText(
        appBarTitle: 'Battery Permission',
        title: 'Optional adhan access',
        body:
            'Optional, so adhan can work even with silent mode or battery saving.',
        note:
            'If battery saving stops the app in the background, some adhan reminders may arrive late.',
        continueLabel: continueLabel,
        laterLabel: laterLabel,
        icon: Icons.battery_charging_full_rounded,
      ),
    };
  }

  static _PermissionExplanationText _french(PermissionExplanationType type) {
    const continueLabel = 'Continuer';
    const laterLabel = 'Plus tard';

    return switch (type) {
      PermissionExplanationType.location => const _PermissionExplanationText(
        appBarTitle: 'Permission de position',
        title: 'Pourquoi la position ?',
        body:
            'Pour calculer les horaires de prière et la qibla selon votre position.',
        note:
            'La position est utilisée uniquement dans l’app pour les horaires et la qibla. Elle n’est pas vendue ni utilisée pour la publicité.',
        continueLabel: continueLabel,
        laterLabel: laterLabel,
        icon: Icons.my_location_rounded,
      ),
      PermissionExplanationType.notifications =>
        const _PermissionExplanationText(
          appBarTitle: 'Permission de notifications',
          title: 'Pourquoi les notifications ?',
          body: 'Pour que l’adhan et les rappels arrivent à l’heure.',
          note:
              'Vous pouvez modifier les réglages plus tard depuis les paramètres de l’adhan.',
          continueLabel: continueLabel,
          laterLabel: laterLabel,
          icon: Icons.notifications_active_rounded,
        ),
      PermissionExplanationType.exactAlarm => const _PermissionExplanationText(
        appBarTitle: 'Permission d’alarme exacte',
        title: 'Pourquoi l’alarme exacte ?',
        body: 'Pour que l’adhan et les rappels arrivent à l’heure.',
        note:
            'Sans cette permission, certains téléphones peuvent retarder les rappels à cause de l’économie de batterie.',
        continueLabel: continueLabel,
        laterLabel: laterLabel,
        icon: Icons.alarm_on_rounded,
      ),
      PermissionExplanationType.dnd => const _PermissionExplanationText(
        appBarTitle: 'Accès Ne pas déranger',
        title: 'Accès optionnel pour l’adhan',
        body:
            'Optionnel, pour que l’adhan fonctionne même en mode silencieux ou économie de batterie.',
        note:
            'Si cette permission reste désactivée, l’app fonctionne quand même, mais l’adhan peut ne pas être audible en mode silencieux.',
        continueLabel: continueLabel,
        laterLabel: laterLabel,
        icon: Icons.do_not_disturb_off_rounded,
      ),
      PermissionExplanationType.battery => const _PermissionExplanationText(
        appBarTitle: 'Permission batterie',
        title: 'Accès optionnel pour l’adhan',
        body:
            'Optionnel, pour que l’adhan fonctionne même en mode silencieux ou économie de batterie.',
        note:
            'Si l’économie de batterie bloque l’app en arrière-plan, certains rappels peuvent arriver en retard.',
        continueLabel: continueLabel,
        laterLabel: laterLabel,
        icon: Icons.battery_charging_full_rounded,
      ),
    };
  }
}
