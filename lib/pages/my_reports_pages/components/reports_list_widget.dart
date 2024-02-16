import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:intl/intl.dart';

class ReportsList extends StatelessWidget {
  final Function onTap;
  final List<Report> reports;

  ReportsList(this.reports, this.onTap);

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Center(
        child: Style.body(MyLocalizations.of(context, 'no_reports_yet_txt')),
      );
    } else {
      return Container(
        margin: EdgeInsets.only(top: 25),
        child: ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Report reporteItem = List.from(reports)
                      .where((element) =>
                          element.report_id == reports[index].report_id)
                      .toList()[0];
                  onTap(reporteItem);
                },
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: <Widget>[
                        Image.asset(
                          reports[index].type == 'adult'
                              ? 'assets/img/maps/ic_yellow_marker.png'
                              : reports[index].type == 'site'
                                  ? 'assets/img/maps/ic_blue_marker.png'
                                  : 'assets/img/maps/ic_red_marker.png',
                          width: 40,
                        ),
                        Container(height: 60, child: VerticalDivider()),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Style.titleMedium(
                                  Utils.getTranslatedReportType(context, reports[index].type),
                                  fontSize: 14),
                              Style.body(
                                  '${MyLocalizations.of(context, "location_txt")}: ${reports[index].displayCity}'),
                              Style.body(
                                MyLocalizations.of(context, 'at_time_txt')! +
                                ': ' +
                                DateFormat('dd-MM-yyyy HH:mm')
                                  .format(DateTime.parse(
                                      reports[index].creation_time!).toLocal())
                                  .toString(),
                                color: Colors.grey
                              ),
                            ],
                          ),
                        ),
                        reports[index].photos != null && reports[index].photos!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  ApiSingleton.baseUrl +
                                      reports[index].photos![0].photo!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ))
                            : Container(
                                ),
                      ],
                    ),
                  ),
                ),
              );
            }),
      );
    }
  }
}
