import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/features/auth/data/auth_repository.dart';
import 'package:mosquito_alert_app/features/auth/domain/models/auth_user.dart';
import 'package:mosquito_alert_app/features/bites/data/bite_repository.dart';
import 'package:mosquito_alert_app/features/bites/domain/models/bite_report.dart';
import 'package:mosquito_alert_app/features/breeding_sites/data/breeding_site_repository.dart';
import 'package:mosquito_alert_app/features/breeding_sites/domain/models/breeding_site_report.dart';
import 'package:mosquito_alert_app/features/fixes/data/fixes_repository.dart';
import 'package:mosquito_alert_app/features/fixes/domain/models/fix.dart';
import 'package:mosquito_alert_app/features/observations/data/observation_repository.dart';
import 'package:mosquito_alert_app/features/observations/domain/models/observation_report.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_backoff.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_sync_error.dart';
import 'package:mosquito_alert_app/features/user/data/user_repository.dart';
import 'package:mosquito_alert_app/hive/hive_adapters.dart';
import 'package:mosquito_alert_app/hive/hive_registrar.g.dart';

Future<void> initHive() async {
  await Hive.initFlutter();

  Hive
    ..registerAdapter(BiteCountsAdapter())
    ..registerAdapter(BiteEventEnvironmentEnumAdapter())
    ..registerAdapter(BiteEventMomentEnumAdapter())
    ..registerAdapter(LocationAdapter())
    ..registerAdapter(ObservationEventEnvironmentEnumAdapter())
    ..registerAdapter(ObservationEventMomentEnumAdapter())
    ..registerAdapter(BreedingSiteSiteTypeEnumAdapter())
    ..registerAdapter(FixLocationAdapter())
    ..registerAdapter(UserAdapter())
    ..registerAdapters();

  await Future.wait([
    // For AuthRepository offline storage
    Hive.openBox<AuthUser>(AuthRepository.itemBoxName),
    // For ObservationRepository offline storage
    Hive.openBox<ObservationReport>(ObservationRepository.itemBoxName),
    // For BiteRepository offline storage
    Hive.openBox<BiteReport>(BiteRepository.itemBoxName),
    // For BreedingSiteRepository offline storage
    Hive.openBox<BreedingSiteReport>(BreedingSiteRepository.itemBoxName),
    // For FixRepository offline storage
    Hive.openBox<FixModel>(FixesRepository.itemBoxName),
    // For UserRepository offline storage
    Hive.openBox<User>(UserRepository.itemBoxName),
    // For OutboxErrorStore: permanent per-item sync error messages
    OutboxErrorStore.init(),
    // For OutboxBackoffStore: next-attempt timestamps for retryable failures
    OutboxBackoffStore.init(),
  ]);
}
