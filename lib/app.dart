import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_sync_manager.dart';
import 'package:mosquito_alert_app/features/auth/presentation/state/auth_provider.dart';
import 'package:mosquito_alert_app/features/onboarding/data/onboarding_repository.dart';
import 'package:mosquito_alert_app/features/onboarding/presentation/pages/onboarding_flow_page.dart';
import 'package:mosquito_alert_app/features/onboarding/presentation/state/onboarding_provider.dart';
import 'package:mosquito_alert_app/screens/layout_page.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizationsDelegate.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';

import 'features/user/presentation/state/user_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.syncManager});

  final OutboxSyncManager syncManager;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final InternetConnection apiConnection;

  late StreamSubscription<InternetStatus> _apiConnectionSubscription;
  late final AppLifecycleListener _apiConnectionSListener;

  StreamSubscription<InternetStatus> _createApiConnectionSubscription() {
    final apiClient = context.read<MosquitoAlert>();

    return InternetConnection.createInstance(
      useDefaultOptions: false,
      enableStrictCheck: true,
      customCheckOptions: [
        // NOTE: this is dummy, all the logic is in customConnectivityCheck
        InternetCheckOption(uri: Uri.parse(apiClient.dio.options.baseUrl)),
      ],
      customConnectivityCheck: (option) async {
        try {
          final pingApi = apiClient.getPingApi();
          final response = await pingApi.retrieve();

          return InternetCheckResult(
            option: option,
            isSuccess: response.statusCode == 204,
          );
        } catch (e) {
          return InternetCheckResult(option: option, isSuccess: false);
        }
      },
    ).onStatusChange.listen((status) async {
      final authProvider = context.read<AuthProvider>();
      final userProvider = context.read<UserProvider>();
      if (status == InternetStatus.connected) {
        await widget.syncManager.syncAllWithoutAuth();
        if (!authProvider.isAuthenticated) {
          try {
            await authProvider.restoreSession();
          } catch (e) {
            print('Error auto logging in: $e');
            return;
          }
        }
        if (authProvider.isAuthenticated && userProvider.user == null) {
          try {
            await userProvider.fetchUser();
          } catch (e) {
            print('Error fetching user: $e');
          }
        }
        await widget.syncManager.syncAll();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _apiConnectionSubscription = _createApiConnectionSubscription();
    _apiConnectionSListener = AppLifecycleListener(
      onResume: () {
        _apiConnectionSubscription = _createApiConnectionSubscription();
      },
      onPause: () {
        _apiConnectionSubscription.cancel();
      },
    );
  }

  @override
  void dispose() {
    _apiConnectionSubscription.cancel();
    _apiConnectionSListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OnboardingProvider>(
      create: (_) => OnboardingProvider(repository: OnboardingRepository()),
      child: OverlaySupport.global(
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
              fillColor: WidgetStateProperty.resolveWith<Color>((
                Set<WidgetState> states,
              ) {
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
              style: TextButton.styleFrom(foregroundColor: Style.colorPrimary),
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
          navigatorObservers: [
            FirebaseAnalyticsObserver(
              analytics: FirebaseAnalytics.instance,
              routeFilter: (route) {
                return route is PageRoute && route.settings.name != '/';
              },
            ),
          ],
          builder: (context, child) {
            return Expanded(child: child!);
          },
          home: Consumer<OnboardingProvider>(
            builder: (context, onboardingProvider, child) {
              return onboardingProvider.isCompleted
                  ? LayoutPage()
                  : OnboardingFlowPage(
                      onCompleted: () async {
                        final authProvider = context.read<AuthProvider>();
                        await authProvider.createGuestAccount();
                      },
                    );
            },
          ),
          localizationsDelegates: [
            MyLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          locale: context.watch<UserProvider>().locale,
          supportedLocales: MyLocalizations.supportedLocales,
        ),
      ),
    );
  }
}
