import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mosquito_alert_app/pages/my_reports_pages/detail/shared_report_widgets.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class ReportDetailPage extends StatelessWidget {
  final dynamic report;
  final Text title;
  final Future<void> Function(dynamic report) onTapDelete;
  final Map<IconData, String>? extraListTileMap;
  final Widget Function(dynamic report)? topBarBackgroundBuilder;
  final Widget Function()? cardBuilder;

  const ReportDetailPage({
    super.key,
    required this.report,
    required this.title,
    required this.onTapDelete,
    this.extraListTileMap,
    this.topBarBackgroundBuilder,
    this.cardBuilder,
  });

  Future<bool?> showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
        context: context,
        barrierDismissible: false, // prevent dismissing by tapping outside
        builder: (BuildContext context) {
          bool isDeleting = false;
          return StatefulBuilder(builder: (context, setState) {
            return Stack(children: [
              AlertDialog(
                title: Text(MyLocalizations.of(context, 'delete_report_title')),
                content: Text(MyLocalizations.of(context, 'delete_report_txt')),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      MyLocalizations.of(context, 'cancel'),
                      style: const TextStyle(color: Colors.black54),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                  ),
                  TextButton(
                    child: Text(
                      MyLocalizations.of(context, 'delete'),
                      style: const TextStyle(color: Colors.red),
                    ),
                    onPressed: () async {
                      setState(() => isDeleting = true);
                      try {
                        await onTapDelete(report);
                        Navigator.of(context).pop(true);
                      } catch (e) {
                        Navigator.of(context).pop(false);
                      }
                    },
                  ),
                ],
              ),
              if (isDeleting)
                // Spinner overlay when deleting
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
            ]);
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final LatLng location = LatLng(
      report.location.point.latitude,
      report.location.point.longitude,
    );
    return Scaffold(
        body: SafeArea(
            top: false,
            child: CustomScrollView(slivers: [
              SliverAppBar(
                titleSpacing: 0,
                expandedHeight: topBarBackgroundBuilder != null ? 250.0 : 0.0,
                floating: true,
                pinned: true,
                snap: true,
                foregroundColor: Colors.white,
                backgroundColor: Style.colorPrimary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  PopupMenuButton<int>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 1) {
                        await showDeleteDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<int>(
                        value: 1,
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              MyLocalizations.of(context, 'delete'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                    title: Text(title.data!,
                        style: title.style?.copyWith(
                              color: Colors.white,
                            ) ??
                            const TextStyle(color: Colors.white)),
                    background: topBarBackgroundBuilder == null
                        ? null
                        : Stack(fit: StackFit.expand, children: [
                            topBarBackgroundBuilder!.call(report),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              height: 80,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.5),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ])),
              ),
              SliverToBoxAdapter(
                  child: cardBuilder != null
                      ? Padding(
                          padding: const EdgeInsets.only(
                              left: 16, right: 16, top: 8),
                          child: cardBuilder!.call())
                      : const SizedBox.shrink()),
              SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        'ID',
                        style: TextStyle(
                          color: Style.colorPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(report.shortId)),
                ListTile(
                  leading: Icon(Icons.pin_drop, color: Style.colorPrimary),
                  title: FutureBuilder<String>(
                    future: ReportUtils.formatLocationWithCity(report),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('(HC) Loading...');
                      } else {
                        final location =
                            snapshot.data ?? '(HC) Unknown location';
                        return Text(location);
                      }
                    },
                  ),
                ),
                ListTile(
                    leading:
                        Icon(Icons.calendar_month, color: Style.colorPrimary),
                    title: Text(DateFormat('EEE, yyyy-MM-dd HH:mm')
                        .format(report.createdAtLocal))),
                // Add extra tiles
                if (extraListTileMap != null)
                  ...extraListTileMap!.entries.map((entry) {
                    return ListTile(
                      leading: Icon(entry.key, color: Style.colorPrimary),
                      title: Text(entry.value),
                    );
                  }).toList(),
                if (report.tags != null && report.tags!.isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.sell, color: Style.colorPrimary),
                    title: Wrap(
                      spacing: 8.0, // space between chips
                      runSpacing: 4.0, // space between lines
                      children: report.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                        );
                      }).toList(),
                    ),
                  ),
                if (report.note != null && report.note!.isNotEmpty)
                  ListTile(
                      leading:
                          Icon(Icons.text_snippet, color: Style.colorPrimary),
                      title: Text(report.note)),
                const Divider(thickness: 0.1),
                Container(
                    height: 300,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GestureDetector(
                      onVerticalDragUpdate:
                          (_) {}, // Absorb vertical drag to prevent scroll
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: location,
                              zoom: 9,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId('report_location'),
                                position: location,
                              ),
                            },
                            gestureRecognizers: {
                              Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                              ),
                            },
                            zoomControlsEnabled: false,
                            zoomGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                          )),
                    )),
                const SizedBox(height: 20),
              ]))
            ])));
  }
}
