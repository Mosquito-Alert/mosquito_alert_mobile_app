import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/customModalBottomSheet.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:provider/provider.dart';

class ReportsListBites extends StatefulWidget {
  const ReportsListBites({super.key});

  @override
  State<ReportsListBites> createState() => _ReportsListBitesState();
}

class _ReportsListBitesState extends State<ReportsListBites> {
  List<Bite> biteReports = [];
  bool isLoading = true;
  late BitesApi bitesApi;

  @override
  void initState() {
    super.initState();
    MosquitoAlert apiClient =
        Provider.of<MosquitoAlert>(context, listen: false);
    bitesApi = apiClient.getBitesApi();
    _loadBiteReports();
  }

  Future<void> _loadBiteReports() async {
    try {
      // TODO: Handle pagination like in notifications page with infinite scrolling view
      final response = await bitesApi.listMine();

      final reports = response.data?.results?.toList() ?? [];

      setState(() {
        biteReports = reports;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading bite reports: $e');
      setState(() {
        biteReports = [];
        isLoading = false;
      });
    }
  }

  String _formatCreationTime(Bite report) {
    return DateFormat('yyyy-MM-dd HH:mm').format(report.createdAt.toLocal());
  }

  String _getTitle(BuildContext context, Bite report) {
    int totalBites = 0;
    final counts = report.counts;
    totalBites += (counts.head ?? 0);
    totalBites += (counts.chest ?? 0);
    totalBites += (counts.leftArm ?? 0);
    totalBites += (counts.rightArm ?? 0);
    totalBites += (counts.leftLeg ?? 0);
    totalBites += (counts.rightLeg ?? 0);

    if (totalBites == 0) {
      return MyLocalizations.of(context, 'no_bites');
    } else if (totalBites == 1) {
      return '1 ${MyLocalizations.of(context, 'single_bite').toLowerCase()}';
    } else {
      return '$totalBites ${MyLocalizations.of(context, 'plural_bite').toLowerCase()}';
    }
  }

  String _getBiteLocations(BiteCounts counts) {
    List<String> locations = [];
    if ((counts.head ?? 0) > 0)
      locations.add(MyLocalizations.of(context, 'bite_report_bodypart_head'));
    if ((counts.chest ?? 0) > 0)
      locations.add(MyLocalizations.of(context, 'bite_report_bodypart_chest'));
    if ((counts.leftArm ?? 0) > 0)
      locations
          .add(MyLocalizations.of(context, 'bite_report_bodypart_leftarm'));
    if ((counts.rightArm ?? 0) > 0)
      locations
          .add(MyLocalizations.of(context, 'bite_report_bodypart_rightarm'));
    if ((counts.leftLeg ?? 0) > 0)
      locations
          .add(MyLocalizations.of(context, 'bite_report_bodypart_leftleg'));
    if ((counts.rightLeg ?? 0) > 0)
      locations
          .add(MyLocalizations.of(context, 'bite_report_bodypart_rightleg'));

    return locations.isEmpty
        ? MyLocalizations.of(context, 'unknown')
        : locations.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Style.colorPrimary),
        ),
      );
    }

    if (biteReports.isEmpty) {
      return Center(
        child: Text(MyLocalizations.of(context, 'no_reports_yet_txt')),
      );
    }

    return ListView.builder(
      itemCount: biteReports.length,
      itemBuilder: (context, index) {
        final report = biteReports[index];
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 4.0,
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            title: Text(_getTitle(context, report)),
            subtitle: RichText(
              text: TextSpan(
                children: [
                  ...[
                    const WidgetSpan(
                      child: Icon(Icons.place_outlined,
                          size: 16, color: Colors.grey),
                    ),
                    TextSpan(
                      text: ' ${_getBiteLocations(report.counts)}\n',
                      style: const TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                  const WidgetSpan(
                    child: Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey),
                  ),
                  TextSpan(
                    text: ' ${_formatCreationTime(report)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            isThreeLine: true,
            onTap: () => _reportBottomSheet(report, context),
          ),
        );
      },
    );
  }

  void _reportBottomSheet(Bite report, BuildContext context) async {
    // TODO: After adult and sites are created, move to some Utils file
    await FirebaseAnalytics.instance
        .logSelectContent(contentType: 'bite_report', itemId: report.uuid);

    await CustomShowModalBottomSheet.customShowModalBottomSheet(
      context: context,
      dismissible: true,
      builder: (BuildContext bc) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
            minHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            margin: EdgeInsets.symmetric(horizontal: 15),
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTitle(context, report),
                        style: TextStyle(fontSize: 18),
                      ),
                      PopupMenuButton<int>(
                        icon: Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 1) {
                            Utils.showAlertYesNo(
                              MyLocalizations.of(
                                  context, 'delete_report_title'),
                              MyLocalizations.of(context, 'delete_report_txt'),
                              () async {
                                await _deleteReport(report);
                              },
                              context,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 1,
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                Text(
                                  ' ${MyLocalizations.of(context, 'delete')}',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Style.titleMedium(
                              MyLocalizations.of(
                                  context, 'exact_time_register_txt'),
                              fontSize: 14,
                            ),
                            Style.body(
                              DateFormat('EEEE, dd MMMM yyyy',
                                      Utils.language.languageCode)
                                  .format(report.createdAt.toLocal()),
                              fontSize: 12,
                            ),
                            Style.body(
                              "${MyLocalizations.of(context, 'at_time_txt')}: ${DateFormat.Hms().format(report.createdAt.toLocal())} ${MyLocalizations.of(context, 'hours')}",
                              fontSize: 12,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(),
                  ),
                  ...[
                    Style.titleMedium(
                      MyLocalizations.of(context, 'bite_locations'),
                      fontSize: 14,
                    ),
                    SizedBox(height: 10),
                    Style.body(_getBiteLocations(report.counts)),
                  ],
                  if (report.eventEnvironment != null) ...[
                    SizedBox(height: 20),
                    Style.titleMedium(
                      MyLocalizations.of(context, 'environment'),
                      fontSize: 14,
                    ),
                    SizedBox(height: 10),
                    Style.body(report.eventEnvironment.toString()),
                  ],
                  if (report.eventMoment != null) ...[
                    SizedBox(height: 20),
                    Style.titleMedium(
                      MyLocalizations.of(context, 'moment'),
                      fontSize: 14,
                    ),
                    SizedBox(height: 10),
                    Style.body(report.eventMoment.toString()),
                  ],
                  if (report.note?.isNotEmpty ?? false) ...[
                    SizedBox(height: 20),
                    Style.titleMedium(
                      MyLocalizations.of(context, 'notes'),
                      fontSize: 14,
                    ),
                    SizedBox(height: 10),
                    Style.body(report.note!),
                  ],
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteReport(Bite report) async {
    // TODO: After adult and sites are created, move to some Utils file
    await FirebaseAnalytics.instance.logEvent(
      name: 'delete_report',
      parameters: {'report_uuid': report.uuid},
    );
    Navigator.pop(context);

    try {
      await bitesApi.destroy(uuid: report.uuid);
      setState(() {
        biteReports.removeWhere((b) => b.uuid == report.uuid);
      });
    } catch (e) {
      await Utils.showAlert(
        MyLocalizations.of(context, 'app_name'),
        MyLocalizations.of(context, 'save_report_ko_txt'),
        context,
      );
    }
  }
}
