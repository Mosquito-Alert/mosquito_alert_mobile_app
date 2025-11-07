import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/detail/shared_report_widgets.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/detail/site_report_detail_page.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/widgets/grouped_report_list_view.dart';
import 'package:mosquito_alert_app/utils/report_formatter.dart';
import 'package:provider/provider.dart';

class ReportsListSites extends StatefulWidget {
  const ReportsListSites({super.key});

  @override
  State<ReportsListSites> createState() => _ReportsListSitesState();
}

class _ReportsListSitesState extends State<ReportsListSites> {
  late BreedingSitesApi breedingSitesApi;

  @override
  void initState() {
    super.initState();
    _initializeApi();
  }

  void _initializeApi() {
    MosquitoAlert apiClient =
        Provider.of<MosquitoAlert>(context, listen: false);
    breedingSitesApi = apiClient.getBreedingSitesApi();
  }

  @override
  Widget build(BuildContext context) {
    return GroupedReportListView(
      fetchObjects: (page, pageSize) async {
        return await breedingSitesApi.listMine(
            page: page,
            pageSize: pageSize,
            orderBy: BuiltList<String>(["-created_at"]));
      },
      titleBuilder: (report) {
        return BreedingSiteWidgets(context, report).buildTitleText();
      },
      leadingBuilder: (report) {
        return ReportDetailWidgets.buildLeadingImage(
          report: report,
        );
      },
      onTap: (report, context) async {
        return await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SiteReportDetailPage(breedingSite: report),
          ),
        );
      },
    );
  }
}
