import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/app.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/features/auth/presentation/state/auth_provider.dart';
import 'package:mosquito_alert_app/features/fixes/presentation/state/fixes_provider.dart';
import 'package:mosquito_alert_app/features/fixes/services/tracking_service.dart';
import 'package:mosquito_alert_app/features/notifications/data/firebase_messaging_service.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/state/notification_provider.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/widgets/notification_badge.dart';
import 'package:mosquito_alert_app/features/user/presentation/state/user_provider.dart';
import 'package:mosquito_alert_app/screens/widgets/custom_drawer.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:provider/provider.dart';
import 'package:mosquito_alert_app/features/settings/presentation/pages/settings_page.dart';
import 'package:mosquito_alert_app/screens/home_page.dart';
import 'package:mosquito_alert_app/screens/my_reports_page.dart';
import 'package:mosquito_alert_app/screens/guide_page.dart';
import 'package:mosquito_alert_app/screens/settings_pages/info_page.dart';

class LayoutPage extends StatefulWidget {
  @override
  _LayoutPageState createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> with WidgetsBindingObserver {
  int _selectedDrawerIndex = 0;

  late final NotificationProvider notificationProvider;

  @override
  void initState() {
    super.initState();
    notificationProvider = context.read<NotificationProvider>();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called when app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      notificationProvider.fetchUnreadNotificationsCount();
    }
  }

  void _initialize() async {
    try {
      await _initUser();
      await _initTrackingService();
      await _initNotificationsService();
    } catch (e) {
      // Handle errors if needed
      debugPrint('Initialization error: $e');
    }
  }

  Future<void> _initUser() async {
    final appConfig = await AppConfig.loadConfig();
    if (!appConfig.useAuth) {
      // Requesting permissions on automated tests creates many problems
      // and mocking permission acceptance is difficult on Android and iOS
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userProvider = context.read<UserProvider>();

    if (!authProvider.isAuthenticated) {
      await authProvider.restoreSession();
    }

    if (userProvider.user == null) {
      try {
        await userProvider.fetchUser();
      } catch (_) {
        return;
      }
    }
  }

  Future<void> _initTrackingService() async {
    final fixesProvider = context.read<FixesProvider>();
    final trackingEnabled = await TrackingService.isEnabled;
    if (trackingEnabled) {
      await fixesProvider.enableTracking();
    } else {
      await fixesProvider.disableTracking();
    }
  }

  Future<void> _initNotificationsService() async {
    unawaited(
      Future(() async {
        await notificationProvider.refresh();
      }),
    );
    await FirebaseMessagingService(navigatorKey: navigatorKey).init();
  }

  @override
  Widget build(BuildContext context) {
    UserProvider userProvider = context.watch<UserProvider>();
    AuthProvider authProvider = context.watch<AuthProvider>();

    final drawerItems = <CustomDrawerItem>[
      CustomDrawerItem(
        icon: Icons.home,
        title: MyLocalizations.of(context, 'home_tab'),
        destination: HomePage(),
      ),
      CustomDrawerItem(
        icon: Icons.file_copy,
        title: MyLocalizations.of(context, 'your_reports_txt'),
        destination: MyReportsPage(),
      ),
      CustomDrawerItem(
        icon: Icons.biotech,
        title: MyLocalizations.of(context, 'guide_tab'),
        destination: GuidePage(
          goBackToHomepage: () {
            setState(() {
              _selectedDrawerIndex = 0;
            });
          },
        ),
      ),
      CustomDrawerItem(
        icon: Icons.info,
        title: MyLocalizations.of(context, 'info_tab'),
        destination: InfoPage(),
      ),
      CustomDrawerItem(
        icon: Icons.settings,
        title: MyLocalizations.of(context, 'settings_title'),
        destination: SettingsPage(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Image.asset('assets/img/ic_logo.webp', height: 40),
        actions: <Widget>[NotificationBadge()],
      ),
      drawer: CustomDrawer(
        selectedIndex: _selectedDrawerIndex,
        items: drawerItems,
        onTapChanged: (index) => setState(() {
          _selectedDrawerIndex = index;
        }),
      ),
      onDrawerChanged: (isOpened) async {
        await FirebaseAnalytics.instance.logEvent(
          name: isOpened ? 'drawer_open' : 'drawer_close',
        );
      },
      body: SafeArea(
        child: userProvider.isLoading || authProvider.isLoading
            ? Center(child: CircularProgressIndicator())
            : drawerItems[_selectedDrawerIndex].destination,
      ),
    );
  }
}
