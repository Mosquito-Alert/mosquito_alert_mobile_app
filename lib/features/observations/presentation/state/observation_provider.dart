import 'package:mosquito_alert_app/features/observations/data/models/observation_report_request.dart';
import 'package:mosquito_alert_app/features/observations/domain/models/observation_report.dart';
import 'package:mosquito_alert_app/features/reports/presentation/state/report_provider.dart';
import 'package:mosquito_alert_app/features/observations/data/observation_repository.dart';

class ObservationProvider
    extends ReportProvider<ObservationReport, ObservationRepository> {
  ObservationProvider({required super.repository});

  Future<ObservationReport> createObservation({
    required ObservationCreateRequest request,
  }) async {
    final newObservation = await repository.create(request: request);
    addItem(newObservation);
    return newObservation;
  }
}
