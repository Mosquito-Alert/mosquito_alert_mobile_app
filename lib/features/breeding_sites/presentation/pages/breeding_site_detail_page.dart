import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:mosquito_alert_app/features/breeding_sites/domain/models/breeding_site_report.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/photo.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/report_detail_field.dart';
import 'package:mosquito_alert_app/core/widgets/common_widgets.dart';
import 'package:mosquito_alert_app/features/reports/presentation/pages/report_detail_page.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_detail_scaffold.dart';
import 'package:mosquito_alert_app/features/breeding_sites/presentation/state/breeding_site_provider.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:provider/provider.dart';

class BreedingSiteDetailPage extends ReportDetailPage<BreedingSiteReport> {
  const BreedingSiteDetailPage({
    Key? key,
    required BreedingSiteReport breedingSite,
  }) : super(key: key, item: breedingSite);

  @override
  _BreedingSiteDetailPageState createState() => _BreedingSiteDetailPageState();
}

class _BreedingSiteDetailPageState extends State<BreedingSiteDetailPage> {
  late BreedingSiteReport breedingSite;

  @override
  void initState() {
    super.initState();
    breedingSite = widget.item;
    _logScreenView();
  }

  Future<void> _logScreenView() async {
    if (breedingSite.uuid != null) {
      await FirebaseAnalytics.instance.logSelectContent(
        contentType: 'breeding_site_report',
        itemId: breedingSite.uuid!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasWater = breedingSite.hasWater ?? false;
    final bool hasLarvae = breedingSite.hasLarvae ?? false;

    // Build the map only if locationEnvironment is not null
    final extraFields = <ReportDetailField>[
      ReportDetailField(
        icon: Icons.water_drop,
        value: [
          MyLocalizations.of(context, 'question_10'),
          hasWater
              ? MyLocalizations.of(context, 'yes')
              : MyLocalizations.of(context, 'no'),
        ].join(' '),
      ),
      ReportDetailField(
        icon: Icons.grain,
        value: [
          MyLocalizations.of(context, 'question_17'),
          hasLarvae
              ? MyLocalizations.of(context, 'yes')
              : MyLocalizations.of(context, 'no'),
        ].join(' '),
      ),
    ];

    Widget? topBarBackground;
    List<BasePhoto>? photos = breedingSite.photos;
    if (photos != null && photos.isNotEmpty) {
      topBarBackground = buildPhotoCarousel(photos: photos);
    }
    return ReportDetailScaffold<BreedingSiteReport>(
      report: breedingSite,
      provider: context.watch<BreedingSiteProvider>(),
      extraFields: extraFields,
      topBarBackground: topBarBackground,
    );
  }
}
