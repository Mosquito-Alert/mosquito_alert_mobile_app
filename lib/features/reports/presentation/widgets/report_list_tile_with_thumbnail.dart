import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/core/widgets/common_widgets.dart';
import 'package:mosquito_alert_app/features/reports/presentation/pages/report_detail_page.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_list_tile.dart';

class ReportListTileWithThumbnail<TReport extends BaseReportModel>
    extends ReportListTile<TReport> {
  ReportListTileWithThumbnail({
    Key? key,
    required TReport report,
    required ReportDetailPage<TReport> reportDetailPage,
  }) : super(
         key: key,
         report: report,
         reportDetailPage: reportDetailPage,
         leadingBuilder: (report) => buildThumbnailImage(
           photo: (report as BaseReportWithPhotos).thumbnail,
         ),
       );
}
