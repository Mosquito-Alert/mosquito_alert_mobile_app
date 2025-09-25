import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
    _initializeApi();
    _loadBiteReports();
  }

  void _initializeApi() {
    MosquitoAlert apiClient =
        Provider.of<MosquitoAlert>(context, listen: false);
    bitesApi = apiClient.getBitesApi();
  }

  Future<void> _loadBiteReports() async {
    try {
      // TODO: Handle pagination like in notifications page with infinite scrolling view
      final response = await bitesApi.listMine();

      final reports = response.data?.results?.toList() ?? [];

      if (mounted) {
        setState(() {
          biteReports = reports;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading bite reports: $e');
      if (mounted) {
        setState(() {
          biteReports = [];
          isLoading = false;
        });
      }
    }
  }

  String _formatCreationTime(Bite report) {
    return DateFormat('yyyy-MM-dd HH:mm').format(report.createdAt.toLocal());
  }

  String _getTitle(BuildContext context, Bite report) {
    final totalBites = _getTotalBiteCount(report.counts);

    if (totalBites == 0) {
      return MyLocalizations.of(context, 'no_bites');
    } else if (totalBites == 1) {
      return '1 ${MyLocalizations.of(context, 'single_bite').toLowerCase()}';
    } else {
      return '$totalBites ${MyLocalizations.of(context, 'plural_bite').toLowerCase()}';
    }
  }

  int _getTotalBiteCount(BiteCounts counts) {
    final head = (counts.head ?? 0).round();
    final chest = (counts.chest ?? 0).round();
    final leftArm = (counts.leftArm ?? 0).round();
    final rightArm = (counts.rightArm ?? 0).round();
    final leftLeg = (counts.leftLeg ?? 0).round();
    final rightLeg = (counts.rightLeg ?? 0).round();

    return head + chest + leftArm + rightArm + leftLeg + rightLeg;
  }

  String _getBiteLocations(BiteCounts counts) {
    final locations = <String>[];

    final bodyParts = [
      {'count': counts.head as num?, 'key': 'bite_report_bodypart_head'},
      {'count': counts.chest as num?, 'key': 'bite_report_bodypart_chest'},
      {'count': counts.leftArm as num?, 'key': 'bite_report_bodypart_leftarm'},
      {
        'count': counts.rightArm as num?,
        'key': 'bite_report_bodypart_rightarm'
      },
      {'count': counts.leftLeg as num?, 'key': 'bite_report_bodypart_leftleg'},
      {
        'count': counts.rightLeg as num?,
        'key': 'bite_report_bodypart_rightleg'
      },
    ];

    for (final part in bodyParts) {
      final count = (part['count'] as num?)?.toInt();
      if (count != null && count > 0) {
        locations.add(MyLocalizations.of(context, part['key'] as String));
      }
    }

    return locations.join(', ');
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
    await FirebaseAnalytics.instance.logSelectContent(
      contentType: 'bite_report',
      itemId: report.uuid,
    );

    await CustomShowModalBottomSheet.customShowModalBottomSheet(
      context: context,
      dismissible: true,
      builder: (BuildContext bc) => _BiteReportDetailSheet(
        report: report,
        onDelete: () => _deleteReport(report),
        formatters: _ReportFormatters(context),
      ),
    );
  }

  Future<void> _deleteReport(Bite report) async {
    await _logReportDeletion(report);
    Navigator.pop(context);

    try {
      await bitesApi.destroy(uuid: report.uuid);
      if (mounted) {
        setState(() {
          biteReports.removeWhere((b) => b.uuid == report.uuid);
        });
      }
    } catch (e) {
      await _showDeleteError();
    }
  }

  Future<void> _logReportDeletion(Bite report) async {
    await FirebaseAnalytics.instance.logEvent(
      name: 'delete_report',
      parameters: {'report_uuid': report.uuid},
    );
  }

  Future<void> _showDeleteError() async {
    await Utils.showAlert(
      MyLocalizations.of(context, 'app_name'),
      MyLocalizations.of(context, 'save_report_ko_txt'),
      context,
    );
  }
}

class _ReportFormatters {
  final BuildContext context;

  _ReportFormatters(this.context);

  String formatTitle(Bite report) {
    final totalBites = _getTotalBiteCount(report.counts);

    if (totalBites == 0) {
      return MyLocalizations.of(context, 'no_bites');
    } else if (totalBites == 1) {
      return '1 ${MyLocalizations.of(context, 'single_bite').toLowerCase()}';
    } else {
      return '$totalBites ${MyLocalizations.of(context, 'plural_bite').toLowerCase()}';
    }
  }

  int _getTotalBiteCount(BiteCounts counts) {
    final head = (counts.head ?? 0).round();
    final chest = (counts.chest ?? 0).round();
    final leftArm = (counts.leftArm ?? 0).round();
    final rightArm = (counts.rightArm ?? 0).round();
    final leftLeg = (counts.leftLeg ?? 0).round();
    final rightLeg = (counts.rightLeg ?? 0).round();

    return head + chest + leftArm + rightArm + leftLeg + rightLeg;
  }

  String formatDetailedDateTime(Bite report) {
    final localTime = report.createdAt.toLocal();
    final dateString =
        DateFormat('EEEE, dd MMMM yyyy', Utils.language.languageCode)
            .format(localTime);
    final timeString = DateFormat.Hms().format(localTime);
    return '$dateString\n${MyLocalizations.of(context, 'at_time_txt')}: $timeString ${MyLocalizations.of(context, 'hours')}';
  }

  String formatLocationCoordinates(Bite report) {
    final point = report.location.point;
    return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  }
}

class _BiteReportDetailSheet extends StatelessWidget {
  final Bite report;
  final VoidCallback onDelete;
  final _ReportFormatters formatters;

  const _BiteReportDetailSheet({
    required this.report,
    required this.onDelete,
    required this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        minHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      decoration: const BoxDecoration(
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
        margin: const EdgeInsets.symmetric(horizontal: 15),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              _ReportMapWidget(report: report),
              const SizedBox(height: 20),
              _ReportHeaderWidget(
                report: report,
                formatters: formatters,
                onDelete: onDelete,
              ),
              const SizedBox(height: 20),
              _ReportLocationWidget(report: report, formatters: formatters),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Divider(),
              ),
              _ReportIdAndBiteDetailsWidget(
                  report: report, formatters: formatters),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportMapWidget extends StatefulWidget {
  final Bite report;

  const _ReportMapWidget({required this.report});

  @override
  State<_ReportMapWidget> createState() => _ReportMapWidgetState();
}

class _ReportMapWidgetState extends State<_ReportMapWidget> {
  @override
  Widget build(BuildContext context) {
    final point = widget.report.location.point;
    final location = LatLng(point.latitude, point.longitude);

    return Container(
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
          initialCameraPosition: CameraPosition(
            target: location,
            zoom: 15.0,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('bite_location'),
              position: location,
              infoWindow: InfoWindow(
                title: MyLocalizations.of(context, 'location'),
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _ReportHeaderWidget extends StatelessWidget {
  final Bite report;
  final _ReportFormatters formatters;
  final VoidCallback onDelete;

  const _ReportHeaderWidget({
    required this.report,
    required this.formatters,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            formatters.formatTitle(report),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
        PopupMenuButton<int>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 1) {
              Utils.showAlertYesNo(
                MyLocalizations.of(context, 'delete_report_title'),
                MyLocalizations.of(context, 'delete_report_txt'),
                onDelete,
                context,
              );
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 1,
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  Text(
                    ' ${MyLocalizations.of(context, 'delete')}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ReportLocationWidget extends StatelessWidget {
  final Bite report;
  final _ReportFormatters formatters;

  const _ReportLocationWidget({
    required this.report,
    required this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Style.titleMedium(
                '${MyLocalizations.of(context, 'registered_location_txt')}:',
                fontSize: 14,
              ),
              const SizedBox(height: 4),
              Style.body(
                '(${formatters.formatLocationCoordinates(report)})',
                fontSize: 12,
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Style.titleMedium(
                MyLocalizations.of(context, 'exact_time_register_txt'),
                fontSize: 14,
              ),
              const SizedBox(height: 4),
              Style.body(
                formatters.formatDetailedDateTime(report),
                fontSize: 12,
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportIdAndBiteDetailsWidget extends StatelessWidget {
  final Bite report;
  final _ReportFormatters formatters;

  const _ReportIdAndBiteDetailsWidget({
    required this.report,
    required this.formatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Report ID
        Row(
          children: [
            Style.titleMedium(
              '${MyLocalizations.of(context, 'identifier_small')}: ',
              fontSize: 14,
            ),
            Style.body(
              report.uuid,
              fontSize: 14,
            ),
          ],
        ),
      ],
    );
  }
}
