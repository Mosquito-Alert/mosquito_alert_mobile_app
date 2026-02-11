import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/app.dart';
import 'package:mosquito_alert_app/app_config.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_service.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_sync_manager.dart';
import 'package:mosquito_alert_app/core/utils/InAppReviewManager.dart';
import 'package:mosquito_alert_app/features/auth/data/auth_repository.dart';
import 'package:mosquito_alert_app/features/bites/data/bite_repository.dart';
import 'package:mosquito_alert_app/features/breeding_sites/data/breeding_site_repository.dart';
import 'package:mosquito_alert_app/features/device/presentation/state/data/device_repository.dart';
import 'package:mosquito_alert_app/features/fixes/data/fixes_repository.dart';
import 'package:mosquito_alert_app/features/fixes/presentation/state/fixes_provider.dart';
import 'package:mosquito_alert_app/features/fixes/services/tracking_service.dart';
import 'package:mosquito_alert_app/features/notifications/data/firebase_messaging_service.dart';
import 'package:mosquito_alert_app/features/observations/data/observation_repository.dart';
import 'package:mosquito_alert_app/features/settings/presentation/state/settings_provider.dart';
import 'package:mosquito_alert_app/features/auth/presentation/state/auth_provider.dart';
import 'package:mosquito_alert_app/features/notifications/presentation/state/notification_provider.dart';
import 'package:mosquito_alert_app/features/notifications/notification_repository.dart';
import 'package:mosquito_alert_app/features/observations/presentation/state/observation_provider.dart';
import 'package:mosquito_alert_app/features/bites/presentation/state/bite_provider.dart';
import 'package:mosquito_alert_app/features/breeding_sites/presentation/state/breeding_site_provider.dart';
import 'package:mosquito_alert_app/features/user/data/user_repository.dart';
import 'package:mosquito_alert_app/hive/hive_service.dart';
import 'package:mosquito_alert_app/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:country_codes/country_codes.dart';

import 'features/user/presentation/state/user_provider.dart';

const String outboxSyncTaskName = "outboxSyncTask";

Future<void> main({String env = 'prod'}) async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await AppConfig.setEnvironment(env);
  final config = await AppConfig.loadConfig();

  try {
    await Firebase.initializeApp();
  } catch (err) {
    print('$err');
  }

  // Initialize Hive
  await initHive();
  // Initialize Outbox
  await OutboxService().init();

  await CountryCodes.init();

  final ApiService apiService = ApiService(baseUrl: config.baseUrl);
  final apiClient = apiService.client;

  final deviceRepository = await DeviceRepository.create(apiClient: apiClient);
  final authRepository = AuthRepository(
    apiClient: apiClient,
    getCurrentDevice: () async {
      return deviceRepository.currentDevice ??
          await deviceRepository.registerCurrentDevice();
    },
  );
  final authProvider = AuthProvider(repository: authRepository);
  await authProvider.restoreSession();

  FirebaseMessagingService.configure(deviceRepository: deviceRepository);

  final userRepository = UserRepository(apiClient: apiClient);
  final userProvider = await UserProvider.create(repository: userRepository);

  if (config.useAuth) {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      outboxSyncTaskName,
      outboxSyncTaskName,
      frequency: const Duration(minutes: 15), // minimum on Android/iOS
    );
  }

  // Initialize repositories
  final observationRepository = ObservationRepository(apiClient: apiClient);
  final biteRepository = BiteRepository(apiClient: apiClient);
  final breedingSiteRepository = BreedingSiteRepository(apiClient: apiClient);
  final fixesRepository = FixesRepository(apiClient: apiClient);

  final syncManager = OutboxSyncManager([
    observationRepository,
    biteRepository,
    breedingSiteRepository,
    fixesRepository,
  ]);

  await TrackingService.configure(repository: fixesRepository);

  InAppReviewManager.configure(
    observationRepository,
    biteRepository,
    breedingSiteRepository,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<MosquitoAlert>.value(value: apiClient),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => NotificationProvider(
            repository: NotificationRepository(apiClient: apiClient),
          ),
        ),
        ChangeNotifierProvider<ObservationProvider>(
          create: (_) => ObservationProvider(repository: observationRepository),
        ),
        ChangeNotifierProvider<BiteProvider>(
          create: (_) => BiteProvider(repository: biteRepository),
        ),
        ChangeNotifierProvider<BreedingSiteProvider>(
          create: (_) =>
              BreedingSiteProvider(repository: breedingSiteRepository),
        ),
        ChangeNotifierProvider<FixesProvider>(create: (_) => FixesProvider()),
      ],
      child: MyApp(syncManager: syncManager),
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

    final config = await AppConfig.loadConfig();

    // Initialize Hive
    await initHive();
    // Initialize Outbox
    await OutboxService().init();

    final ApiService apiService = ApiService(baseUrl: config.baseUrl);
    final apiClient = apiService.client;

    final authRepository = AuthRepository(apiClient: apiClient);
    try {
      await authRepository.restoreSession();
    } catch (_) {
      // Do nothing. There are task that can work offline.
    }

    final fixesRepository = FixesRepository(apiClient: apiClient);

    await TrackingService.configure(repository: fixesRepository);
    // Support 3 possible outcomes:
    // - Future.value(true): task is successful
    // - Future.value(false): task failed and needs to be retried
    // - Future.error(): task failed.

    switch (task) {
      case outboxSyncTaskName:
        final observationRepository = ObservationRepository(
          apiClient: apiClient,
        );
        final biteRepository = BiteRepository(apiClient: apiClient);
        final breedingSiteRepository = BreedingSiteRepository(
          apiClient: apiClient,
        );

        final syncManager = OutboxSyncManager([
          observationRepository,
          biteRepository,
          breedingSiteRepository,
          fixesRepository,
        ]);

        try {
          await syncManager.syncAll();
        } catch (e) {
          return Future.error(e);
        }
        return Future.value(true);
      case 'trackingTask':
        // NOTE: do not use await, it should return a Future value
        try {
          await TrackingService.sendLocationNow();
        } catch (e) {
          return Future.error(e);
        }
        return Future.value(true);
      case 'scheduleDailyTasks':
        try {
          await TrackingService.scheduleDailyTasks();
        } catch (e) {
          return Future.error(e);
        }
        return Future.value(true);
      default:
        // If the task doesn't match, return true as a fallback
        return Future.value(true);
    }
  });
}
