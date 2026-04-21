import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:mosquito_alert_app/features/fixes/data/models/fix_request.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as sdk;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/fixes_repository.dart';

class LocationSender {
  final FixesRepository repository;
  final String uuid;

  LocationSender._({required this.repository, required this.uuid});

  static Future<LocationSender> create({
    required FixesRepository repository,
  }) async {
    final uuid = await _loadCoverageUuid();
    return LocationSender._(repository: repository, uuid: uuid);
  }

  static Future<String> _loadCoverageUuid() async {
    var prefs = await SharedPreferences.getInstance();
    String? trackingUuid = prefs.getString('trackingUUID');
    if (trackingUuid == null || trackingUuid.isEmpty) {
      trackingUuid = Uuid().v4();
      await prefs.setString('trackingUUID', trackingUuid);
    }
    return trackingUuid;
  }

  Future<void> sendLocation() async {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    int battery = await Battery().batteryLevel;

    FixCreateRequest request = FixCreateRequest(
      localId: Uuid().v4(),
      coverageUuid: uuid,
      createdAt: DateTime.now().toUtc(),
      point: sdk.FixLocationRequest(
        (p) => p
          ..latitude = pos.latitude
          ..longitude = pos.longitude,
      ),
      power: battery / 100,
    );

    await repository.create(request: request);
  }
}
