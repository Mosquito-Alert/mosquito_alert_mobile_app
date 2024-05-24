import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/components/reports_list_widget.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';


class MyReportsPage extends StatefulWidget {
  const MyReportsPage({Key? key}) : super(key: key);

  @override
  _MyReportsPageState createState() => _MyReportsPageState();
}

class _MyReportsPageState extends State<MyReportsPage> {
  late List<Report> adultReports;
  late List<Report> biteReports;
  late List<Report> siteReports;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  void loadReports() async {
    var myReports = await ApiSingleton().getReportsList();

    // Sort the reports by creation_time in descending order
    myReports.sort((a, b) => b.creation_time!
        .compareTo(a.creation_time ?? '1970-01-01T00:00:00.000000Z'));

    setState(() {
      adultReports = myReports.where((report) => report.type == 'adult').toList();
      biteReports = myReports.where((report) => report.type == 'bite').toList();
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
            tabs: [
              Tab(
                icon: Image.asset(
                  'assets/img/ic_my_reports_mosquito.png',
                  width: 24,
                  height: 24,
                  filterQuality: FilterQuality.high),
                text: MyLocalizations.of(context, 'single_mosquito')),
              Tab(
                icon: Image.asset(
                  'assets/img/ic_my_reports_bite.png',
                  width: 24,
                  height: 24,
                  filterQuality: FilterQuality.high),
                text: MyLocalizations.of(context, 'single_bite')),
              Tab(
                icon: Image.asset(
                  'assets/img/ic_my_reports_breeding_site.png',
                  width: 24,
                  height: 24,
                  filterQuality: FilterQuality.high),
                text: MyLocalizations.of(context, 'single_breeding_site')),
            ],
          ),
          title: Text(MyLocalizations.of(context, 'your_reports_txt')),
        ),
        body: isLoading ?
          Center(child: CircularProgressIndicator())
          :
          TabBarView(
            children: [
              ReportsList(reports: adultReports),
              ReportsList(reports: biteReports),
              ReportsList(reports: siteReports),
            ],
          ),
      ),
    );
  }
}