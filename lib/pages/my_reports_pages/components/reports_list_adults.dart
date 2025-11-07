import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/detail/adult_report_detail_page.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/detail/shared_report_widgets.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/widgets/grouped_report_list_view.dart';
import 'package:mosquito_alert_app/utils/report_formatter.dart';
import 'package:provider/provider.dart';

class ReportsListAdults extends StatefulWidget {
  const ReportsListAdults({super.key});

  @override
  State<ReportsListAdults> createState() => _ReportsListAdultsState();
}

class _ReportsListAdultsState extends State<ReportsListAdults> {
  late ObservationsApi observationsApi;

  @override
  void initState() {
    super.initState();
    _initializeApi();
  }

  void _initializeApi() {
    MosquitoAlert apiClient =
        Provider.of<MosquitoAlert>(context, listen: false);
    observationsApi = apiClient.getObservationsApi();
  }

  @override
  Widget build(BuildContext context) {
    return GroupedReportListView(
      fetchObjects: (page, pageSize) async {
        return await observationsApi.listMine(
            page: page,
            pageSize: pageSize,
            orderBy: BuiltList<String>(["-created_at"]));
      },
      titleBuilder: (report) {
        return ObservationWidgets(context, report).buildTitleText();
      },
      leadingBuilder: (report) => ReportDetailWidgets.buildLeadingImage(
        report: report,
      ),
      onTap: (report, context) async {
        // Handle tap on each report
        return await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdultReportDetailPage(observation: report),
          ),
        );
      },
    );
  }
}
