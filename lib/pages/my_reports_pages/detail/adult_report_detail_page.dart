import 'package:built_collection/built_collection.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/detail/shared_report_widgets.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/widgets/report_detail_page.dart';
import 'package:mosquito_alert_app/pages/settings_pages/campaign_tutorial_page.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/report_formatter.dart';
import 'package:mosquito_alert_app/utils/style.dart';
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
  Campaign? activeCampaign;

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

  void _initializeApi() async {
    MosquitoAlert apiClient =
        Provider.of<MosquitoAlert>(context, listen: false);
    observationsApi = apiClient.getObservationsApi();

    final observationCountry = widget.observation.location.country;
    final observationDateAllowsCampaign =
        DateTime.now().difference(widget.observation.createdAt) <=
            Duration(days: 2);
    if (observationCountry != null && observationDateAllowsCampaign) {
      final _campaignsApi = apiClient.getCampaignsApi();
      final campaignsResponse = await _campaignsApi.list(
        countryId: observationCountry.id,
        isActive: true,
        pageSize: 1,
        orderBy: ['-start_date'].build(),
      );
      setState(() {
        activeCampaign = campaignsResponse.data?.results?.firstOrNull;
      });
    }
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
      cardBuilder: () => activeCampaign != null
          ? Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                              children: [
                                TextSpan(
                                  text: MyLocalizations.of(context,
                                          "alert_campaing_found_title") +
                                      " ",
                                ),
                                TextSpan(
                                  text: widget.observation.shortId,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeCampaign!.postingAddress,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CampaignTutorialPage()),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Style.colorPrimary,
                        ),
                        child: Text(
                          MyLocalizations.of(context, "show_info"),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
