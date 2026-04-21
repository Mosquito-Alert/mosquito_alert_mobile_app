import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/features/reports/presentation/pages/report_detail_page.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';

class ReportListTile<TReport extends BaseReportModel> extends StatelessWidget {
  final TReport report;
  final Widget? Function(TReport report)? leadingBuilder;
  final ReportDetailPage<TReport> reportDetailPage;

  const ReportListTile({
    Key? key,
    required this.report,
    required this.reportDetailPage,
    this.leadingBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: report.locationDisplayName,
      builder: (context, snapshot) {
        final subtitle = snapshot.connectionState == ConnectionState.waiting
            ? MyLocalizations.of(context, 'loading') + '...'
            : (snapshot.data ??
                  MyLocalizations.of(context, 'unknown_location'));

        return ListTile(
          title: Text.rich(
            TextSpan(
              children: [
                if (report.isOffline) ...[
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Icon(
                      Icons.cloud_off_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const WidgetSpan(child: SizedBox(width: 8)),
                ],
                TextSpan(
                  text: report.getTitle(context),
                  style: TextStyle(
                    fontStyle: report.titleItalicized
                        ? FontStyle.italic
                        : FontStyle.normal,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          leading: leadingBuilder?.call(report),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => reportDetailPage),
            );
          },
        );
      },
    );
  }
}
