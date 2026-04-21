import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/report_detail_field.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';

class ReportInfoList<TReport extends BaseReportModel> extends StatelessWidget {
  final TReport report;
  final List<ReportDetailField>? extraFields;

  const ReportInfoList({super.key, required this.report, this.extraFields});

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      if (report.shortId != null)
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            child: Text(
              'ID',
              style: TextStyle(
                color: Style.colorPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(report.shortId!),
        ),
      ListTile(
        leading: Icon(Icons.pin_drop, color: Style.colorPrimary),
        title: FutureBuilder<String>(
          future: report.locationDisplayName,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Text(MyLocalizations.of(context, 'loading') + '...');
            } else {
              final location =
                  snapshot.data ??
                  MyLocalizations.of(context, 'unknown_location');
              return Text(location);
            }
          },
        ),
      ),
      ListTile(
        leading: Icon(Icons.calendar_month, color: Style.colorPrimary),
        title: Text(
          DateFormat.yMMMEd().add_Hm().format(report.createdAtLocal.toLocal()),
        ),
      ),
      // Add extra tiles
      if (extraFields != null)
        ...extraFields!.map((f) {
          return ListTile(
            leading: Icon(f.icon, color: Style.colorPrimary),
            title: Text(f.value),
          );
        }).toList(),
      if (report.tags != null && report.tags!.isNotEmpty)
        ListTile(
          leading: Icon(Icons.sell, color: Style.colorPrimary),
          title: Wrap(
            spacing: 8.0, // space between chips
            runSpacing: 4.0, // space between lines
            children: report.tags!.map((tag) {
              return Chip(label: Text(tag));
            }).toList(),
          ),
        ),
      if (report.note != null && report.note!.isNotEmpty)
        ListTile(
          leading: Icon(Icons.text_snippet, color: Style.colorPrimary),
          title: Text(report.note!),
        ),
    ];

    return Column(children: tiles);
  }
}
