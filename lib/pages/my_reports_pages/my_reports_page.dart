import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/components/reports_list_adults.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/components/reports_list_bites.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/components/reports_list_sites.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

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
                        filterQuality: FilterQuality.high),
                    text: MyLocalizations.of(context, 'single_mosquito')),
                Tab(
                    icon: Image.asset('assets/img/ic_bite_report_black.webp',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high),
                    text: MyLocalizations.of(context, 'single_bite')),
                Tab(
                    icon: Image.asset(
                        'assets/img/ic_breeding_report_black.webp',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high),
                    text: MyLocalizations.of(context, 'single_breeding_site')),
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
              }),
          title: Text(MyLocalizations.of(context, 'your_reports_txt')),
        ),
        body: const TabBarView(
          children: [
            ReportsListAdults(),
            ReportsListBites(),
            ReportsListSites(),
          ],
        ),
      ),
    );
  }
}
