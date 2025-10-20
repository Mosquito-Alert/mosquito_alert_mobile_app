import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/pages/main/drawer_and_header.dart';
import 'package:mosquito_alert_app/providers/auth_provider.dart';
import 'package:mosquito_alert_app/providers/device_provider.dart';
import 'package:mosquito_alert_app/services/api_service.dart';
import 'package:mosquito_alert_app/utils/Application.dart';
import 'package:mosquito_alert_app/utils/BackgroundTracking.dart';
import 'package:mosquito_alert_app/utils/MyLocalizationsDelegate.dart';
import 'package:mosquito_alert_app/utils/ObserverUtils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'providers/user_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main({String env = 'prod'}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await AppConfig.setEnvironment(env);

  try {
    await Firebase.initializeApp();
  } catch (err) {
    print('$err');
  }

  final authProvider = AuthProvider();
  await authProvider.init();

  final ApiService apiService =
      await ApiService.init(authProvider: authProvider);
  final MosquitoAlert apiClient = apiService.client;

  authProvider.setApiClient(apiClient);
  final userProvider = UserProvider(apiClient: apiClient);
  final deviceProvider = await DeviceProvider.create(apiClient: apiClient);

  final appConfig = await AppConfig.loadConfig();
  if (appConfig.useAuth) {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<MosquitoAlert>.value(value: apiClient),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<DeviceProvider>.value(value: deviceProvider),
      ],
      child: MyApp(),
    ),
  );
}

@pragma('vm:entry-point') // Mandatory if the App is using Flutter 3.1+
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp();
    } catch (err) {
      print('$err');
    }

    final authProvider = AuthProvider();
    await authProvider.init();

    final ApiService apiService =
        await ApiService.init(authProvider: authProvider);
    final MosquitoAlert apiClient = apiService.client;

    authProvider.setApiClient(apiClient);

    final userProvider = UserProvider(apiClient: apiClient);
    final deviceProvider = await DeviceProvider.create(apiClient: apiClient);
    String? username = authProvider.username;
    String? password = authProvider.password;
    if (username == null && password == null) {
      return Future.value(
          false); // No user credentials available, cannot proceed
    }
    try {
      await authProvider.login(username: username!, password: password!);
      await userProvider.fetchUser();
    } catch (e) {
      print('Error logging in: $e');
      return Future.value(false); // Login failed, cannot proceed
    }
    try {
      await deviceProvider.registerDevice();
      if (deviceProvider.device != null) {
        await authProvider.setDevice(deviceProvider.device!);
      }
    } catch (e) {
      print('Error registering device: $e');
    }

    BackgroundTracking.configure(apiClient: apiClient);
    // Support 3 possible outcomes:
    // - Future.value(true): task is successful
    // - Future.value(false): task failed and needs to be retried
    // - Future.error(): task failed.

    switch (task) {
      case 'trackingTask':
        // NOTE: do not use await, it should return a Future value
        return BackgroundTracking.sendLocationUpdate();
      case 'scheduleDailyTasks':
        int numTaskAlreadyScheduled =
            inputData?['numTaskAlreadyScheduled'] ?? 0;
        // NOTE: do not use await, it should return a Future value
        return BackgroundTracking.scheduleDailyTrackingTask(
            numScheduledTasks: numTaskAlreadyScheduled);
      default:
        // If the task doesn't match, return true as a fallback
        return Future.value(true);
    }
  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();

  static void setLocale(BuildContext context) {}
}

class _MyAppState extends State<MyApp> {
  MyLocalizationsDelegate _newLocaleDelegate = MyLocalizationsDelegate();

  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: FirebaseAnalytics.instance,
    routeFilter: (route) {
      return route is PageRoute && route.settings.name != '/';
    },
  );

  @override
  void initState() {
    super.initState();

    application.onLocaleChanged = onLocaleChange;
  }

  void onLocaleChange(Locale locale) {
    setState(() {
      _newLocaleDelegate = MyLocalizationsDelegate(newLocale: locale);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport(
        child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Style.colorPrimary,
          brightness: Brightness.light,
          primary: Style.colorPrimary,
          secondary: Style.colorPrimary,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        // Explicitly set component themes to use your primary color
        checkboxTheme: CheckboxThemeData(
          fillColor:
              WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Style.colorPrimary;
            }
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Style.colorPrimary,
            foregroundColor: Colors.white,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Style.colorPrimary,
            side: BorderSide(color: Style.colorPrimary),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Style.colorPrimary,
          ),
        ),
        // Configure text themes to use your primary color
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            color: Style.colorPrimary,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: Style.colorPrimary,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: TextStyle(
            color: Style.colorPrimary,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Style.colorPrimary,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: Style.colorPrimary,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            color: Style.colorPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Override primary color references
        primaryColor: Style.colorPrimary,
        primaryColorDark: Style.colorPrimary,
        primaryColorLight: Style.colorPrimary,
      ),
      navigatorKey: navigatorKey,
      navigatorObservers: <NavigatorObserver>[
        observer,
        ObserverUtils.routeObserver
      ],
      home: MainVC(),
      localizationsDelegates: [
        _newLocaleDelegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: application.supportedLocales(),
    ));
  }
}
