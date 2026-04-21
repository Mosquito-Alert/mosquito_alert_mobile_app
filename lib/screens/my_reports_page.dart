import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/bites/domain/models/bite_report.dart';
import 'package:mosquito_alert_app/features/breeding_sites/domain/models/breeding_site_report.dart';
import 'package:mosquito_alert_app/features/observations/domain/models/observation_report.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_list.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_list_tile.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_list_tile_with_thumbnail.dart';
import 'package:mosquito_alert_app/features/bites/presentation/pages/bite_detail_page.dart';
import 'package:mosquito_alert_app/features/bites/presentation/state/bite_provider.dart';
import 'package:mosquito_alert_app/features/breeding_sites/presentation/pages/breeding_site_detail_page.dart';
import 'package:mosquito_alert_app/features/breeding_sites/presentation/state/breeding_site_provider.dart';
import 'package:mosquito_alert_app/features/observations/presentation/pages/observation_detail_page.dart';
import 'package:mosquito_alert_app/features/observations/presentation/state/observation_provider.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';

import 'package:provider/provider.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({Key? key}) : super(key: key);

  @override
  _MyReportsPageState createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  @override
  void initState() {
    super.initState();
    _logScreenView();
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance.logScreenView(screenName: '/my_reports');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          bottom: TabBar(
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            indicatorColor: Style.colorPrimary,
            labelColor: Colors.black,
            tabs: <Widget>[
              Tab(
                icon: Image.asset(
                  'assets/img/ic_mosquito_report_black.webp',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                text: MyLocalizations.of(context, 'single_mosquito'),
              ),
              Tab(
                icon: Image.asset(
                  'assets/img/ic_bite_report_black.webp',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                text: MyLocalizations.of(context, 'single_bite'),
              ),
              Tab(
                icon: Image.asset(
                  'assets/img/ic_breeding_report_black.webp',
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                text: MyLocalizations.of(context, 'single_breeding_site'),
              ),
            ],
            onTap: (index) async {
              // Log the tab switch event to Firebase Analytics
              const tabNames = ['mosquitoes', 'bites', 'breeding_site'];
              if (index >= 0 && index < tabNames.length) {
                await FirebaseAnalytics.instance.logEvent(
                  name: 'tab_switched',
                  parameters: {'tab_name': tabNames[index]},
                );
              }
            },
          ),
          title: Text(MyLocalizations.of(context, 'your_reports_txt')),
        ),
        body: TabBarView(
          children: [
            ReportList(
              provider: context.watch<ObservationProvider>(),
              tileBuilder: ({required report}) {
                return ReportListTileWithThumbnail<ObservationReport>(
                  report: report,
                  reportDetailPage: ObservationDetailPage(observation: report),
                );
              },
            ),
            ReportList(
              provider: context.watch<BiteProvider>(),
              tileBuilder: ({required report}) {
                return ReportListTile<BiteReport>(
                  report: report,
                  reportDetailPage: BiteDetailPage(bite: report),
                );
              },
            ),
            ReportList(
              provider: context.watch<BreedingSiteProvider>(),
              tileBuilder: ({required report}) {
                return ReportListTileWithThumbnail<BreedingSiteReport>(
                  report: report,
                  reportDetailPage: BreedingSiteDetailPage(
                    breedingSite: report,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
