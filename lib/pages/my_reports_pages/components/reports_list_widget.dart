import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mosquito_alert_app/api/api.dart';
import 'package:mosquito_alert_app/models/owcampaing.dart';
import 'package:mosquito_alert_app/models/report.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/Utils.dart';
import 'package:mosquito_alert_app/utils/customModalBottomSheet.dart';
import 'package:mosquito_alert_app/utils/style.dart';


class ReportsList extends StatefulWidget {
  ReportsList({Key? key, required this.reports}) : super(key: key);
  final List<Report> reports;

  @override
  _MyReportsListState createState() => _MyReportsListState(reports: reports);
}

class _MyReportsListState extends State<ReportsList> {
  List<Report> reports;
  GoogleMapController? miniMapController;

  _MyReportsListState({required this.reports});

  String formatCreationTime(String? utcTimeString) {
    utcTimeString ??= '1970-01-01 00:00';
    var utcTime = DateTime.parse(utcTimeString);
    var localTime = utcTime.toLocal();
    var formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(localTime);
    
    return formattedTime;
  }

  String getTitle(BuildContext context, Report report){
    switch(report.type) {
      case 'adult':
        return MyLocalizations.of(context, 'single_mosquito');
      case 'bite':
        var response_question_1 = report.responses?.firstWhere(
          (element) => element!.question == 'question_1');

        var numBites = response_question_1?.answer_value;
        if (numBites == null){
          return '0 ${MyLocalizations.of(context, 'plural_bite').toLowerCase()}';
        }
        if (numBites == '1'){
          return '$numBites ${MyLocalizations.of(context, 'single_bite').toLowerCase()}';
        }
        return '$numBites ${MyLocalizations.of(context, 'plural_bite').toLowerCase()}';
      case 'site':
        var response_question_12 = report.responses?.firstWhere(
          (element) => element!.question == 'question_12');
        return MyLocalizations.of(context, response_question_12?.answer);
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: reports.isEmpty
        ? Center(
            child: Text('No reports found.'),
          )
        : 
        ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4.0,
              child: ListTile(    
                leading: reports[index].type == 'bite' ? null :
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.amberAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: reports[index].photos![0].photo ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                  ),
                title: Text(getTitle(context, reports[index])),
                subtitle: RichText(
                  text: TextSpan(
                    children: [
                      if (reports[index].displayCity != null) ...[
                        WidgetSpan(
                          child: Icon(Icons.location_on, size: 16),
                        ),
                        TextSpan(
                          text: ' ${reports[index].displayCity}\n',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      WidgetSpan(
                        child: Icon(Icons.calendar_today, size: 16),
                      ),
                      TextSpan(
                        text: ' ${formatCreationTime(reports[index].creation_time)}',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                isThreeLine: true,
                onTap: () {
                  _reportBottomSheet(reports[index], context);
                },
              ),
            );
          },
        )
    );
  }


  Future<Campaign?> _checkCampaigns(int? country) async {
    List<Campaign> campaignsList = await ApiSingleton().getCampaigns(country);
    var now = DateTime.now().toUtc();
    if (campaignsList.any((element) =>
        DateTime.parse(element.startDate!).isBefore(now) &&
        DateTime.parse(element.endDate!).isAfter(now))) {
      var activeCampaign = campaignsList.firstWhere((element) =>
          DateTime.parse(element.startDate!).isBefore(now) &&
          DateTime.parse(element.endDate!).isAfter(now));
      return activeCampaign;
    }
    return null;
  }

  void _onMiniMapCreated(GoogleMapController controller) async {
    miniMapController = controller;
  }

  void _deleteReport(Report report) async {
    Navigator.pop(context);
    var res = await Utils.deleteReport(report);
    if (res){
      reports.removeWhere((element) => element.report_id == report.report_id);
      setState(() {
        reports = reports;
      });
    } else {
      await Utils.showAlert(
        MyLocalizations.of(context, 'app_name'),
        MyLocalizations.of(context, 'save_report_ko_txt'),
        context,
      );
    }
  }

  void _reportBottomSheet(Report report, BuildContext context) async {
    var hasValidLocation = report.getLocation() != null;
    var location = report.getLocation();
    var campaign = await _checkCampaigns(report.country);
    await CustomShowModalBottomSheet.customShowModalBottomSheet(
      context: context,
      dismissible: true,
      builder: (BuildContext bc) {
        return Container(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              minHeight: MediaQuery.of(context).size.height * 0.55),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              )),
          child: Container(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9),
            margin: EdgeInsets.symmetric(horizontal: 15),
            child: SingleChildScrollView(
              physics: ClampingScrollPhysics(),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      height: 15,
                    ),
                    !hasValidLocation ?
                      Container()
                    :
                      Container(
                        height: MediaQuery.of(context).size.height * 0.25,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: GoogleMap(
                            rotateGesturesEnabled: false,
                            mapToolbarEnabled: false,
                            scrollGesturesEnabled: false,
                            zoomControlsEnabled: false,
                            zoomGesturesEnabled: false,
                            myLocationButtonEnabled: false,
                            onMapCreated: _onMiniMapCreated,
                            initialCameraPosition:   
                              CameraPosition(
                                target: location!,
                                zoom: 15.0,
                              ),  
                            markers: <Marker>{Marker(
                              markerId: MarkerId('marker'),
                              position: location,
                            )},
                          ),
                        ),
                      ),
                    SizedBox(
                      height: 20,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Utils.getTranslatedReportType(context, report.type),
                          style: TextStyle(fontSize: 18),
                        ),
                        PopupMenuButton<int>(
                          icon: Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 1) {
                              Utils.showAlertYesNo(
                                MyLocalizations.of(context, 'delete_report_title'),
                                MyLocalizations.of(context, 'delete_report_txt'), () {
                                  _deleteReport(report);
                                }, context);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 1,
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  Text(' ' + MyLocalizations.of(context, 'delete'), style: TextStyle(color: Colors.red)),
                                ],
                              )
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    report.type != 'adult' || campaign == null
                      ?
                      Container()
                      :
                      Container(
                        padding: EdgeInsets.all(12),
                        color: Colors.orange[50],
                        child: Column(
                          children: [
                            SizedBox(
                              height: 0,
                            ),
                            Row(
                              children: [
                                Expanded(
                                    flex: 3,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Style.body(
                                            MyLocalizations.of(context,
                                                'you_can_send_info_address'),
                                            fontSize: 14,
                                            textAlign: TextAlign.start),
                                        SizedBox(
                                          height: 4,
                                        ),
                                        Style.titleMedium(
                                            campaign.postingAddress,
                                            fontSize: 14),
                                        SizedBox(
                                          height: 4,
                                        ),
                                        Row(
                                          children: [
                                            Style.body(
                                                "${MyLocalizations.of(context, "you_can_send_report_id")}: ",
                                                fontSize: 14,
                                                textAlign:
                                                    TextAlign.start),
                                            SizedBox(
                                              width: 6,
                                            ),
                                            Style.titleMedium(
                                                report.report_id,
                                                fontSize: 14),
                                          ],
                                        )
                                      ],
                                    )),
                                SizedBox(
                                  width: 12,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    report.type == 'adult' && campaign != null
                        ? SizedBox(
                            height: 20,
                          )
                        : Container(),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: !hasValidLocation ?
                            <Widget>[]
                            :
                            <Widget>[
                              Style.titleMedium(
                                MyLocalizations.of(
                                    context, 'registered_location_txt') + ': ',
                                fontSize: 14),
                                Style.body(
                                    '(' + report.getLocation()!.latitude.toStringAsFixed(5) +
                                    ', ' +
                                    report.getLocation()!.longitude.toStringAsFixed(5) + ')',
                                  fontSize: 12),
                                Style.body(
                                    ' ${MyLocalizations.of(context, "near_from_txt")}: ${report.displayCity}',
                                    fontSize: 12),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Style.titleMedium(
                                  MyLocalizations.of(
                                      context, 'exact_time_register_txt'),
                                  fontSize: 14),
                              Style.body(
                                  DateFormat('EEEE, dd MMMM yyyy',
                                          Utils.language.languageCode)
                                      .format(DateTime.parse(
                                          report.creation_time!).toLocal())
                                      .toString(),
                                  fontSize: 12),
                              Style.body(
                                  "${MyLocalizations.of(context, "at_time_txt")}: ${DateFormat.Hms().format(DateTime.parse(report.creation_time!).toLocal())} ${MyLocalizations.of(context, 'hours')}",
                                  fontSize: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Divider(),
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                Style.titleMedium(
                                    MyLocalizations.of(
                                      context, 'identifier_small') + ': ',
                                    fontSize: 14),
                                SizedBox(
                                  height: 4,
                                ),
                                Style.body(report.report_id,
                                    fontSize: 14,
                                    textAlign: TextAlign.center),
                              ],
                            ),
                            SizedBox(
                              height: 12,
                            ),
                          ],
                        ),
                        report.photos != null && report.photos!.isNotEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  SizedBox(
                                    height: 12,
                                  ),
                                  Style.titleMedium(
                                      MyLocalizations.of(
                                          context, 'reported_images_txt'),
                                      fontSize: 14),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Container(
                                    height: 60,
                                    child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: report.photos!.length,
                                        itemBuilder: (context, index) {
                                          return Container(
                                            margin: EdgeInsets.only(right: 5),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: Image.network(
                                                report.photos![index].photo!,
                                                height: 60,
                                                width: 60,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          );
                                        }),
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                ],
                              )
                            : Container(),
                        ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: report.responses!.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        report.responses![index]!.question !=
                                                null
                                            ? Expanded(
                                                flex: 3,
                                                child: Style.titleMedium(
                                                  report.responses![index]!
                                                          .question!
                                                          .startsWith(
                                                              'question')
                                                      ? MyLocalizations.of(
                                                          context,
                                                          report
                                                              .responses![
                                                                  index]!
                                                              .question)
                                                      : report
                                                          .responses![
                                                              index]!
                                                          .question,
                                                  fontSize: 14),
                                              )
                                            : Container(),
                                        Expanded(
                                          flex: 2,
                                          child: Style.body(
                                              report.responses![index]!
                                                          .answer !=
                                                      'N/A'
                                                  ? report.responses![index]!
                                                          .answer!
                                                          .startsWith(
                                                              'question')
                                                      ? MyLocalizations.of(
                                                          context,
                                                          report
                                                              .responses![
                                                                  index]!
                                                              .answer)
                                                      : report
                                                          .responses![index]!
                                                          .answer
                                                  : report.responses![index]!
                                                      .answer_value,
                                              textAlign: TextAlign.end),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                        report.note != null && report.note != 'null'
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    child: Divider(),
                                  ),
                                  Style.titleMedium(
                                      MyLocalizations.of(
                                          context, 'comments_txt'),
                                      fontSize: 14),
                                  Style.body(
                                    report.note,
                                  ),
                                ],
                              )
                            : Container(),
                        SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                  ]),
            ),
          ),
        );
      }
    );
  }
}