import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/detail/bite_report_detail_page.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/widgets/grouped_report_list_view.dart';
import 'package:mosquito_alert_app/utils/report_formatter.dart';
import 'package:provider/provider.dart';

class ReportsListBites extends StatefulWidget {
  const ReportsListBites({super.key});

  @override
  State<ReportsListBites> createState() => _ReportsListBitesState();
}

class _ReportsListBitesState extends State<ReportsListBites> {
  late BitesApi bitesApi;

  @override
  void initState() {
    super.initState();
    _initializeApi();
  }

  void _initializeApi() {
    MosquitoAlert apiClient =
        Provider.of<MosquitoAlert>(context, listen: false);
    bitesApi = apiClient.getBitesApi();
  }

  @override
  Widget build(BuildContext context) {
    return GroupedReportListView(
      fetchObjects: (page, pageSize) async {
        return await bitesApi.listMine(
            page: page,
            pageSize: pageSize,
            orderBy: BuiltList<String>(["-created_at"]));
      },
      titleBuilder: (report) {
        return BiteWidgets(context, report).buildTitleText();
      },
      onTap: (report, context) async {
        return await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BiteReportDetailPage(bite: report),
          ),
        );
      },
    );
  }
}
