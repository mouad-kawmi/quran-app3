import 'dart:math';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quran_app/core/prayer_service.dart';
import 'package:quran_app/core/theme.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  String _t(String key, [Map<String, String>? params]) {
    final lang = Localizations.localeOf(context).languageCode;
    String text = lang == 'ar'
        ? _arStrings[key] ?? key
        : (lang == 'en' ? _enStrings[key] ?? key : _frStrings[key] ?? key);
    if (params != null) {
      params.forEach((k, v) => text = text.replaceAll('{$k}', v));
    }
    return text;
  }

  static const _arStrings = {
    'qibla': 'القبلة',
    'location_error': 'تعذر تحديد الموقع. فعّل خدمة الموقع وحاول مرة أخرى.',
    'fallback_location': 'القبلة محسوبة مؤقتاً على الرباط. فعّل خدمة الموقع واضغط تحديث لتحديد مدينتك.',
    'accuracy': 'دقة الموقع حوالي {m} متر',
    'refresh': 'تحديث الموقع',
    'aligned': 'أنت متجه نحو القبلة',
    'turn_right': 'استدر يميناً {deg}°',
    'turn_left': 'استدر يساراً {deg}°',
    'calibrate': 'إذا كان السهم يتحرك كثيرا، حرّك الهاتف على شكل 8 لمعايرة البوصلة.',
    'poor_accuracy': 'دقة البوصلة ضعيفة ({deg}°). حرّك الهاتف على شكل 8.',
    'good_accuracy': 'دقة البوصلة جيدة ({deg}°).',
    'qibla_dir': 'اتجاه القبلة',
    'phone_dir': 'اتجاه الهاتف',
    'your_coord': 'إحداثياتك',
    'calc_notice': 'الاتجاه محسوب نحو الكعبة في مكة المكرمة. إذا كانت خدمة الموقع متوقفة فسيتم استعمال الرباط مؤقتاً.',
    'perm_needed': 'يحتاج التطبيق إلى إذن الموقع لحساب اتجاه القبلة.',
    'open_settings': 'فتح إعدادات الموقع',
    'no_compass': 'تعذرت قراءة بوصلة الهاتف.',
    'no_compass_desc': 'حاول مرة أخرى أو تأكد من وجود مستشعر البوصلة في الهاتف.',
    'qibla_from_location': 'اتجاه القبلة من موقعك هو {deg}° من الشمال.',
    'reading_compass': 'جار قراءة اتجاه الهاتف...',
    'move_phone': 'حرّك الهاتف قليلا لمعايرة البوصلة.',
    'retry': 'إعادة المحاولة',
  };

  static const _enStrings = {
    'qibla': 'Qibla',
    'location_error': 'Could not get location. Enable location services and try again.',
    'fallback_location': 'Qibla temporarily calculated for Rabat. Enable location and refresh to use your city.',
    'accuracy': 'Location accuracy: ~{m} meters',
    'refresh': 'Refresh location',
    'aligned': 'You are facing the Qibla',
    'turn_right': 'Turn right {deg}°',
    'turn_left': 'Turn left {deg}°',
    'calibrate': 'If the arrow is unstable, wave your phone in a figure 8 to calibrate.',
    'poor_accuracy': 'Poor compass accuracy ({deg}°). Wave phone in figure 8.',
    'good_accuracy': 'Good compass accuracy ({deg}°).',
    'qibla_dir': 'Qibla direction',
    'phone_dir': 'Phone direction',
    'your_coord': 'Your coordinates',
    'calc_notice': 'Direction calculated towards Kaaba in Mecca. If location is disabled, Rabat is used temporarily.',
    'perm_needed': 'App requires location permission to calculate Qibla direction.',
    'open_settings': 'Open Location Settings',
    'no_compass': 'Could not read phone compass.',
    'no_compass_desc': 'Try again or ensure your device has a compass sensor.',
    'qibla_from_location': 'Qibla direction from your location is {deg}° from North.',
    'reading_compass': 'Reading phone direction...',
    'move_phone': 'Move your phone slightly to calibrate the compass.',
    'retry': 'Try Again',
  };

  static const _frStrings = {
    'qibla': 'Qibla',
    'location_error': 'Impossible d\'obtenir la position. Activez la localisation et réessayez.',
    'fallback_location': 'Qibla temporairement calculée pour Rabat. Activez la localisation et actualisez.',
    'accuracy': 'Précision : ~{m} mètres',
    'refresh': 'Actualiser la position',
    'aligned': 'Vous faites face à la Qibla',
    'turn_right': 'Tournez à droite {deg}°',
    'turn_left': 'Tournez à gauche {deg}°',
    'calibrate': 'Si la flèche est instable, faites des 8 pour calibrer.',
    'poor_accuracy': 'Boussole faible ({deg}°). Faites des 8 avec le téléphone.',
    'good_accuracy': 'Boussole précise ({deg}°).',
    'qibla_dir': 'Direction de la Qibla',
    'phone_dir': 'Direction du téléphone',
    'your_coord': 'Vos coordonnées',
    'calc_notice': 'Direction calculée vers la Kaaba. Si la localisation est désactivée, Rabat est utilisée.',
    'perm_needed': 'L\'application nécessite l\'accès à la position pour calculer la Qibla.',
    'open_settings': 'Ouvrir les paramètres',
    'no_compass': 'Impossible de lire la boussole.',
    'no_compass_desc': 'Réessayez ou vérifiez que votre appareil a un capteur boussole.',
    'qibla_from_location': 'La Qibla depuis votre position est à {deg}° du Nord.',
    'reading_compass': 'Lecture de la direction...',
    'move_phone': 'Bougez légèrement votre téléphone pour calibrer la boussole.',
    'retry': 'Réessayer',
  };
  PrayerLocation? _location;
  double? _qiblaDirection;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQibla();
  }

  Future<void> _loadQibla() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final location = await PrayerService.getBestAvailableLocation();
      final qibla = Qibla(location.coordinates);
      if (!mounted) return;

      setState(() {
        _location = location;
        _qiblaDirection = qibla.direction;
        _isLoading = false;
      });
    } on PrayerLocationException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _t('location_error');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _t('qibla'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _qiblaDirection == null || _location == null) {
      return _buildErrorState();
    }

    final compassStream = FlutterCompass.events;
    if (compassStream == null) {
      return _buildNoSensorState();
    }

    return StreamBuilder<CompassEvent>(
      stream: compassStream,
      builder: (context, snapshot) {
        final heading = snapshot.data?.heading;

        if (snapshot.hasError) {
          return _buildNoSensorState();
        }

        if (heading == null) {
          return _buildWaitingForCompass();
        }

        final qiblaDirection = _qiblaDirection!;
        final turnAngle = _signedAngleDifference(qiblaDirection, heading);
        final accuracy = snapshot.data?.accuracy;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildLocationCard(),
              const SizedBox(height: 24),
              _buildCompass(turnAngle),
              const SizedBox(height: 24),
              _buildStatusCard(turnAngle, accuracy),
              const SizedBox(height: 16),
              _buildDirectionDetails(heading, qiblaDirection),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationCard() {
    final location = _location!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppTheme.isDark(context) ? 0.16 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  PrayerService.getLocalizedCityName(context, location.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location.isFallback
                      ? _t('fallback_location')
                      : _t('accuracy', {'m': location.accuracy.toStringAsFixed(0)}),
                  style: TextStyle(
                    color: AppTheme.mutedTextColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _t('refresh'),
            onPressed: _loadQibla,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildCompass(double turnAngle) {
    return SizedBox(
      width: 310,
      height: 310,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 300,
            height: 300,
              decoration: BoxDecoration(
              color: AppTheme.elevatedSurfaceColor(context),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: AppTheme.isDark(context) ? 0.24 : 0.06,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),
          for (var i = 0; i < 72; i++)
            Transform.rotate(
              angle: i * 5 * pi / 180,
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: i % 6 == 0 ? 3 : 1.5,
                  height: i % 6 == 0 ? 18 : 9,
                  margin: const EdgeInsets.only(top: 14),
                  color: i % 18 == 0
                      ? AppTheme.primaryColor
                      : Colors.grey.withValues(alpha: 0.35),
                ),
              ),
            ),
          const Positioned(
            top: 42,
            child: Text(
              'N',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Transform.rotate(
            angle: turnAngle * pi / 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mosque_rounded,
                  color: AppTheme.secondaryColor,
                  size: 48,
                ),
                Container(
                  width: 6,
                  height: 105,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                    gradient: LinearGradient(
                      colors: [AppTheme.secondaryColor, Colors.transparent],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(double turnAngle, double? accuracy) {
    final absoluteAngle = turnAngle.abs();
    final isAligned = absoluteAngle <= 5;
    final directionText = isAligned
        ? _t('aligned')
        : turnAngle > 0
        ? _t('turn_right', {'deg': absoluteAngle.toStringAsFixed(0)})
        : _t('turn_left', {'deg': absoluteAngle.toStringAsFixed(0)});

    final accuracyText = accuracy == null
        ? _t('calibrate')
        : accuracy > 25
        ? _t('poor_accuracy', {'deg': accuracy.toStringAsFixed(0)})
        : _t('good_accuracy', {'deg': accuracy.toStringAsFixed(0)});

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isAligned
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isAligned
              ? Colors.green.withValues(alpha: 0.25)
              : Colors.orange.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isAligned ? Icons.check_circle_rounded : Icons.explore_rounded,
            color: isAligned ? Colors.green : Colors.orange,
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            directionText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isAligned ? Colors.green[800] : Colors.orange[900],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            accuracyText,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.mutedTextColor(context), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionDetails(double heading, double qiblaDirection) {
    final location = _location!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            _t('qibla_dir'),
            '${qiblaDirection.toStringAsFixed(1)}°',
          ),
          const SizedBox(height: 10),
          _buildDetailRow(_t('phone_dir'), '${heading.toStringAsFixed(1)}°'),
          const SizedBox(height: 10),
          _buildDetailRow(
            _t('your_coord'),
            '${location.coordinates.latitude.toStringAsFixed(5)}, ${location.coordinates.longitude.toStringAsFixed(5)}',
          ),
          const SizedBox(height: 10),
          Text(
            _t('calc_notice'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.mutedTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.mutedTextColor(context))),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              color: AppTheme.primaryTextColor(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_rounded,
              size: 76,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? _t('perm_needed'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadQibla,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(_t('retry')),
            ),
            TextButton(
              onPressed: Geolocator.openLocationSettings,
              child: Text(_t('open_settings')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSensorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_off_rounded, size: 76, color: Colors.grey),
            const SizedBox(height: 20),
            Text(
              _t('no_compass'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _qiblaDirection == null
                  ? _t('no_compass_desc')
                  : _t('qibla_from_location', {'deg': _qiblaDirection!.toStringAsFixed(1)}),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingForCompass() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _t('reading_compass'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _t('move_phone'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  double _signedAngleDifference(double target, double heading) {
    return (target - heading + 540) % 360 - 180;
  }
}
