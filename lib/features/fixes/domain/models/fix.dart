import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/core/outbox/outbox_offline_model.dart';
import 'package:mosquito_alert_app/features/fixes/data/models/fix_request.dart';

class FixModel extends OfflineModel {
  final String coverageUuid;
  final DateTime createdAt;
  final DateTime? sentAt;
  final FixLocation point;
  final double? power;

  FixModel({
    required this.coverageUuid,
    required this.createdAt,
    this.sentAt,
    required this.point,
    this.power,
    super.localId,
  });

  factory FixModel.fromCreateRequest(FixCreateRequest request) {
    return FixModel(
      coverageUuid: request.coverageUuid,
      createdAt: request.createdAt,
      point: FixLocation(
        (p) => p
          ..latitude = request.point.latitude
          ..longitude = request.point.longitude,
      ),
      power: request.power,
      localId: request.localId,
    );
  }
}
