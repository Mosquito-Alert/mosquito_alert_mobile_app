import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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

  // See: https://github.com/hivedb/docs/blob/master/advanced/encrypted_box.md
  const secureStorage = FlutterSecureStorage();
  // if key not exists return null
  final encryptionKeyString = await secureStorage.read(key: 'hive_key');
  if (encryptionKeyString == null) {
    final key = Hive.generateSecureKey();
    await secureStorage.write(key: 'hive_key', value: base64UrlEncode(key));
  }
  final key = await secureStorage.read(key: 'hive_key');
  final encryptionKeyUint8List = base64Url.decode(key!);

  await Future.wait([
    // For AuthRepository offline storage
    Hive.openBox<AuthUser>(
      AuthRepository.itemBoxName,
      encryptionCipher: HiveAesCipher(encryptionKeyUint8List),
    ),
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
  ]);
}
