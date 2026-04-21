import 'package:mosquito_alert_app/features/bites/data/models/bite_report_request.dart';
import 'package:mosquito_alert_app/features/bites/domain/models/bite_report.dart';
import 'package:mosquito_alert_app/features/reports/presentation/state/report_provider.dart';
import 'package:mosquito_alert_app/features/bites/data/bite_repository.dart';

class BiteProvider extends ReportProvider<BiteReport, BiteRepository> {
  BiteProvider({required super.repository});

  Future<BiteReport> createBite({required BiteCreateRequest request}) async {
    final newBite = await repository.create(request: request);
    addItem(newBite);
    return newBite;
  }
}
