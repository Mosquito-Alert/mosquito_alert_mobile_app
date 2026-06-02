import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/core/widgets/common_widgets.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_list_tile.dart';

class ReportListTileWithThumbnail<TReport extends BaseReportModel>
    extends ReportListTile<TReport> {
  ReportListTileWithThumbnail({
    super.key,
    required super.report,
    required super.reportDetailPage,
  }) : super(
         leadingBuilder: (report) => buildThumbnailImage(
           photo: (report as BaseReportWithPhotos).thumbnail,
         ),
       );
}
