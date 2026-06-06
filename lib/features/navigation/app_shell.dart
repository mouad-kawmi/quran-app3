import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran_app/core/prayer_notification_service.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/adhkar/adhkar_data.dart';
import 'package:quran_app/features/adhkar/adhkar_detail_screen.dart';
import 'package:quran_app/features/adhkar/adhkar_screen.dart';
import 'package:quran_app/features/home/home_screen.dart';
import 'package:quran_app/features/more/more_screen.dart';
import 'package:quran_app/features/quran/quran_search_screen.dart';
import 'package:quran_app/features/quran/surah_list_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const int _tabCount = 5;

  final List<GlobalKey<NavigatorState>> _navigatorKeys =
      List<GlobalKey<NavigatorState>>.generate(
    _tabCount,
    (_) => GlobalKey<NavigatorState>(),
  );

  int _currentIndex = 0;
  StreamSubscription<String>? _notifSub;

  @override
  void initState() {
    super.initState();
    _notifSub = PrayerNotificationService.onNotificationClick.listen((payload) {
      if (payload.startsWith('sunnah:')) {
        final id = payload.split(':')[1];
        if (id.contains('adhkar')) {
          _selectTab(3); // Adhkar tab
          // Allow tab switch to happen first
          Future.delayed(const Duration(milliseconds: 100), () {
            AdhkarModel? targetCategory;
            if (id == 'morning_adhkar') {
              targetCategory = adhkarData.firstWhere((e) => e.title.contains('الصباح'));
            } else if (id == 'evening_adhkar') {
              targetCategory = adhkarData.firstWhere((e) => e.title.contains('المساء'));
            } else if (id == 'sleep_adhkar') {
              targetCategory = adhkarData.firstWhere((e) => e.title.contains('النوم'));
            }
            if (targetCategory != null) {
              final navigator = _navigatorKeys[3].currentState;
              if (navigator != null) {
                // Ensure we don't push multiple times
                navigator.popUntil((route) => route.isFirst);
                navigator.push(MaterialPageRoute(
                  builder: (context) => AdhkarDetailScreen(category: targetCategory!),
                ));
              }
            }
          });
        } else {
          _selectTab(4); // More tab (for Sunnah reminders or other things)
        }
      }
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  void _selectTab(int index) {
    if (index == _currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handleSystemBack() async {
    final navigator = _navigatorKeys[_currentIndex].currentState;
    if (navigator != null && await navigator.maybePop()) {
      return;
    }

    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
      return;
    }

    await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          unawaited(_handleSystemBack());
        },
        child: Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: List<Widget>.generate(_tabCount, _buildTabNavigator),
          ),
          bottomNavigationBar: _buildBottomNav(context),
        ),
      ),
    );
  }

  Widget _buildTabNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => _buildRootScreen(index),
        );
      },
    );
  }

  Widget _buildRootScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(onSelectMainTab: _selectTab);
      case 1:
        return const SurahListScreen();
      case 2:
        return const QuranSearchScreen();
      case 3:
        return const AdhkarScreen();
      case 4:
        return const MoreScreen();
      default:
        return HomeScreen(onSelectMainTab: _selectTab);
    }
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        onTap: _selectTab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.isDark(context)
            ? AppTheme.secondaryColor
            : AppTheme.primaryColor,
        unselectedItemColor: AppTheme.mutedTextColor(context),
        currentIndex: _currentIndex,
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'القرآن',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'البحث',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_rounded),
            label: 'الأذكار',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'المزيد',
          ),
        ],
      ),
    );
  }
}
