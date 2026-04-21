import 'package:mosquito_alert_app/features/breeding_sites/data/models/breeding_site_report_request.dart';
import 'package:mosquito_alert_app/features/breeding_sites/domain/models/breeding_site_report.dart';
import 'package:mosquito_alert_app/features/reports/presentation/state/report_provider.dart';
import 'package:mosquito_alert_app/features/breeding_sites/data/breeding_site_repository.dart';

class BreedingSiteProvider
    extends ReportProvider<BreedingSiteReport, BreedingSiteRepository> {
  BreedingSiteProvider({required super.repository});

  Future<BreedingSiteReport> createBreedingSite({
    required BreedingSiteCreateRequest request,
  }) async {
    final newBreedingSite = await repository.create(request: request);
    addItem(newBreedingSite);
    return newBreedingSite;
  }
}
