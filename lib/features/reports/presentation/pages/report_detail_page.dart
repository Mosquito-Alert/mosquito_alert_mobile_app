import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';

abstract class ReportDetailPage<TReport extends BaseReportModel>
    extends StatefulWidget {
  final TReport item;

  const ReportDetailPage({super.key, required this.item});
}
