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
        _errorMessage = 'تعذر تحديد الموقع. فعّل خدمة الموقع وحاول مرة أخرى.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'القبلة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _buildBody(),
      ),
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
                  location.name,
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
                      ? 'القبلة محسوبة مؤقتاً على الرباط. فعّل خدمة الموقع واضغط تحديث لتحديد مدينتك.'
                      : 'دقة الموقع حوالي ${location.accuracy.toStringAsFixed(0)} متر',
                  style: TextStyle(
                    color: AppTheme.mutedTextColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'تحديث الموقع',
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
        ? 'أنت متجه نحو القبلة'
        : turnAngle > 0
        ? 'استدر يميناً ${absoluteAngle.toStringAsFixed(0)}°'
        : 'استدر يساراً ${absoluteAngle.toStringAsFixed(0)}°';

    final accuracyText = accuracy == null
        ? 'إذا كان السهم يتحرك كثيرا، حرّك الهاتف على شكل 8 لمعايرة البوصلة.'
        : accuracy > 25
        ? 'دقة البوصلة ضعيفة (${accuracy.toStringAsFixed(0)}°). حرّك الهاتف على شكل 8.'
        : 'دقة البوصلة جيدة (${accuracy.toStringAsFixed(0)}°).';

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
            'اتجاه القبلة',
            '${qiblaDirection.toStringAsFixed(1)}°',
          ),
          const SizedBox(height: 10),
          _buildDetailRow('اتجاه الهاتف', '${heading.toStringAsFixed(1)}°'),
          const SizedBox(height: 10),
          _buildDetailRow(
            'إحداثياتك',
            '${location.coordinates.latitude.toStringAsFixed(5)}, ${location.coordinates.longitude.toStringAsFixed(5)}',
          ),
          const SizedBox(height: 10),
          Text(
            'الاتجاه محسوب نحو الكعبة في مكة المكرمة. إذا كانت خدمة الموقع متوقفة فسيتم استعمال الرباط مؤقتاً.',
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
              _errorMessage ?? 'يحتاج التطبيق إلى إذن الموقع لحساب اتجاه القبلة.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loadQibla,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
            TextButton(
              onPressed: Geolocator.openLocationSettings,
              child: const Text('فتح إعدادات الموقع'),
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
            const Text(
              'تعذرت قراءة بوصلة الهاتف.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _qiblaDirection == null
                  ? 'حاول مرة أخرى أو تأكد من وجود مستشعر البوصلة في الهاتف.'
                  : 'اتجاه القبلة من موقعك هو ${_qiblaDirection!.toStringAsFixed(1)}° من الشمال.',
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
            const Text(
              'جار قراءة اتجاه الهاتف...',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'حرّك الهاتف قليلا لمعايرة البوصلة.',
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
