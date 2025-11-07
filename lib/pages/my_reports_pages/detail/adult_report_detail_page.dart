import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/detail/shared_report_widgets.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/widgets/report_detail_page.dart';
import 'package:mosquito_alert_app/utils/report_formatter.dart';
import 'package:provider/provider.dart';

class AdultReportDetailPage extends StatefulWidget {
  final Observation observation;

  const AdultReportDetailPage({
    super.key,
    required this.observation,
  });

  @override
  State<AdultReportDetailPage> createState() => _AdultReportDetailPageState();
}

class _AdultReportDetailPageState extends State<AdultReportDetailPage> {
  late ObservationsApi observationsApi;

  @override
  void initState() {
    super.initState();
    _logScreenView();
    _initializeApi();
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance.logSelectContent(
      contentType: 'adult_report',
      itemId: widget.observation.uuid,
    );
  }

  void _initializeApi() {
    MosquitoAlert apiClient =
        Provider.of<MosquitoAlert>(context, listen: false);
    observationsApi = apiClient.getObservationsApi();
  }

  Future<void> _deleteReport({required Observation observation}) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'delete_report',
      parameters: {'report_uuid': observation.uuid},
    );

    try {
      await observationsApi.destroy(uuid: observation.uuid);
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate deletion
      }
    } catch (e) {
      print('Error deleting observation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final observationWidgets = ObservationWidgets(context, widget.observation);
    final String? locationEnvironment =
        observationWidgets.getLocationEnvironment();

    // Build the map only if locationEnvironment is not null
    final extraListTileMap = <IconData, String>{};
    if (locationEnvironment != null) {
      extraListTileMap[Icons.not_listed_location] = locationEnvironment;
    }

    return ReportDetailPage(
      report: widget.observation,
      title: observationWidgets.buildTitleText(),
      onTapDelete: (observation) => _deleteReport(observation: observation),
      extraListTileMap: extraListTileMap,
      topBarBackgroundBuilder: (observation) =>
          ReportDetailWidgets.buildPhotoCarousel(report: observation),
    );
  }
}
