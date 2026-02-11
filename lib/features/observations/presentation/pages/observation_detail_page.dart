import 'package:built_collection/built_collection.dart';
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mosquito_alert_app/features/observations/domain/models/observation_report.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/report_detail_field.dart';
import 'package:mosquito_alert_app/core/widgets/common_widgets.dart';
import 'package:mosquito_alert_app/features/reports/presentation/pages/report_detail_page.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_detail_scaffold.dart';
import 'package:mosquito_alert_app/features/observations/presentation/state/observation_provider.dart';
import 'package:mosquito_alert_app/features/observations/presentation/widgets/campaign_card.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:provider/provider.dart';

class ObservationDetailPage extends ReportDetailPage<ObservationReport> {
  const ObservationDetailPage({
    Key? key,
    required ObservationReport observation,
  }) : super(key: key, item: observation);

  @override
  _ObservationDetailPageState createState() => _ObservationDetailPageState();
}

class _ObservationDetailPageState extends State<ObservationDetailPage> {
  Campaign? activeCampaign;
  late ObservationReport observation;

  @override
  void initState() {
    super.initState();
    observation = widget.item;
    _logScreenView();
    _initializeApi();
  }

  Future<void> _logScreenView() async {
    if (observation.uuid != null) {
      await FirebaseAnalytics.instance.logSelectContent(
        contentType: 'adult_report',
        itemId: observation.uuid!,
      );
    }
  }

  void _initializeApi() async {
    MosquitoAlert apiClient = Provider.of<MosquitoAlert>(
      context,
      listen: false,
    );

    final observationCountry = observation.location.country;
    final observationDateAllowsCampaign =
        DateTime.now().difference(observation.createdAt) <= Duration(days: 2);
    if (observationCountry != null && observationDateAllowsCampaign) {
      final _campaignsApi = apiClient.getCampaignsApi();
      final campaignsResponse = await _campaignsApi.list(
        countryId: observationCountry.id,
        isActive: true,
        pageSize: 1,
        orderBy: ['-start_date'].build(),
      );
      setState(() {
        activeCampaign = campaignsResponse.data?.results.firstOrNull;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? locationEnvironment = observation.getLocalizedEnvironment(
      context,
    );
    // Build the map only if locationEnvironment is not null
    final extraFields = <ReportDetailField>[];
    if (locationEnvironment != null) {
      extraFields.add(
        ReportDetailField(
          icon: Icons.not_listed_location,
          value: locationEnvironment,
        ),
      );
    }

    Widget? topBarBackground;
    List<BasePhoto>? photos = observation.photos;
    if (photos != null && photos.isNotEmpty) {
      topBarBackground = buildPhotoCarousel(photos: photos);
    }
    return ReportDetailScaffold<ObservationReport>(
      report: observation,
      provider: context.watch<ObservationProvider>(),
      extraFields: extraFields,
      topBarBackground: topBarBackground,
      cardBuilder: () => activeCampaign != null
          ? CampaignCard(campaign: activeCampaign!, observation: observation)
          : const SizedBox.shrink(),
    );
  }
}
