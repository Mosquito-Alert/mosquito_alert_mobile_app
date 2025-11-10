import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/widgets/report_detail_page.dart';
import 'package:mosquito_alert_app/pages/reports/bite/models/bite_report_data.dart';
import 'package:mosquito_alert_app/pages/reports/bite/widgets/body_part_selector.dart';
import 'package:mosquito_alert_app/utils/report_formatter.dart';
import 'package:provider/provider.dart';

class BiteReportDetailPage extends StatefulWidget {
  final Bite bite;

  const BiteReportDetailPage({
    Key? key,
    required this.bite,
  }) : super(key: key);

  @override
  State<BiteReportDetailPage> createState() => _BiteReportDetailPageState();
}

class _BiteReportDetailPageState extends State<BiteReportDetailPage> {
  late BitesApi bitesApi;
  BiteReportData biteReportData = BiteReportData();

  @override
  void initState() {
    super.initState();
    biteReportData.headBites = widget.bite.counts.head ?? 0;
    biteReportData.leftHandBites = widget.bite.counts.leftArm ?? 0;
    biteReportData.rightHandBites = widget.bite.counts.rightArm ?? 0;
    biteReportData.chestBites = widget.bite.counts.chest ?? 0;
    biteReportData.leftLegBites = widget.bite.counts.leftLeg ?? 0;
    biteReportData.rightLegBites = widget.bite.counts.rightLeg ?? 0;
    _logScreenView();
    _initializeApi();
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance.logSelectContent(
      contentType: 'bite_report',
      itemId: widget.bite.uuid,
    );
  }

  void _initializeApi() {
    MosquitoAlert apiClient =
        Provider.of<MosquitoAlert>(context, listen: false);
    bitesApi = apiClient.getBitesApi();
  }

  Future<void> _deleteReport({required Bite bite}) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'delete_report',
      parameters: {'report_uuid': bite.uuid},
    );

    try {
      await bitesApi.destroy(uuid: bite.uuid);
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate deletion
      }
    } catch (e) {
      print('Error deleting bite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final biteWidgets = BiteWidgets(context, widget.bite);
    final String? locationEnvironment = biteWidgets.getLocationEnvironment();
    final String? eventMoment = biteWidgets.getEventMoment();

    final extraListTileMap = <IconData, String>{};
    if (locationEnvironment != null) {
      extraListTileMap[Icons.not_listed_location] = locationEnvironment;
    }
    if (eventMoment != null) {
      extraListTileMap[Icons.av_timer] = eventMoment;
    }

    return ReportDetailPage(
        report: widget.bite,
        title: biteWidgets.buildTitleText(),
        onTapDelete: (bite) => _deleteReport(bite: bite),
        extraListTileMap: extraListTileMap,
        topBarBackgroundBuilder: (report) => LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                    color: Colors.white,
                    child: SafeArea(
                        child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: BodyPartSelector.buildVisualBodySelector(
                          context,
                          biteReportData,
                          isEditable: false,
                        ),
                      ),
                    )));
              },
            ));
  }
}
