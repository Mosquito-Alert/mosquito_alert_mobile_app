import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/components/reports_list_bites.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/components/reports_list_widget.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class MyReportsPage extends StatefulWidget {
  const MyReportsPage({Key? key}) : super(key: key);

  @override
  _MyReportsPageState createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  late List<Report> adultReports;
  late List<Report> siteReports;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReports();
    _logScreenView();
  }

  Future<void> _logScreenView() async {
    await FirebaseAnalytics.instance.logScreenView(screenName: '/my_reports');
  }

  void loadReports() async {
    var myReports = await ApiSingleton().getReportsList();

    // Sort the reports by creation_time in descending order
    myReports.sort((a, b) => b.creation_time!
        .compareTo(a.creation_time ?? '1970-01-01T00:00:00.000000Z'));

    setState(() {
      adultReports =
          myReports.where((report) => report.type == 'adult').toList();
      siteReports = myReports.where((report) => report.type == 'site').toList();
      isLoading = false;
    });
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
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  ReportsList(reports: adultReports),
                  ReportsListBites(),
                  ReportsList(reports: siteReports),
                ],
              ),
      ),
    );
  }
}
