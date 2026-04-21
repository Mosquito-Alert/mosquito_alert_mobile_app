import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/report_detail_field.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/delete_dialog.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_info_list.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_map.dart';
import 'package:mosquito_alert_app/features/reports/presentation/state/report_provider.dart';
import 'package:mosquito_alert_app/features/reports/data/report_repository.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';

class ReportDetailScaffold<TReport extends BaseReportModel>
    extends StatelessWidget {
  final TReport report;
  final ReportProvider<
    TReport,
    ReportRepository<TReport, dynamic, dynamic, dynamic>
  >
  provider;
  final List<ReportDetailField>? extraFields;
  final Widget? topBarBackground;
  final Widget Function()? cardBuilder;

  const ReportDetailScaffold({
    super.key,
    required this.report,
    required this.provider,
    this.extraFields,
    this.topBarBackground,
    this.cardBuilder,
  });

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // prevent dismissing by tapping outside
      builder: (BuildContext context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return Stack(
              children: [
                DeleteDialog(
                  onDelete: () async {
                    setState(() => isDeleting = true);
                    try {
                      await provider.delete(item: report);
                      Navigator.of(context).pop(true);
                    } catch (e) {
                      Navigator.of(context).pop(false);
                    } finally {
                      setState(() => isDeleting = false);
                    }
                  },
                ),
                if (isDeleting)
                  // Spinner overlay when deleting
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              titleSpacing: 0,
              expandedHeight: topBarBackground != null ? 250.0 : 0.0,
              floating: true,
              pinned: true,
              snap: true,
              foregroundColor: Colors.white,
              backgroundColor: Style.colorPrimary,
              leading: BackButton(color: Colors.white),
              actions: report.isOffline
                  ? []
                  : [
                      PopupMenuButton<int>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) async {
                          if (value == 1) {
                            bool? deleted = await _showDeleteDialog(context);
                            if (deleted == true) Navigator.pop(context, true);
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
                title: Text.rich(
                  TextSpan(
                    children: [
                      if (report.isOffline) ...[
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            Icons.cloud_off_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const WidgetSpan(child: SizedBox(width: 8)),
                      ],
                      TextSpan(
                        text: report.getTitle(context),
                        style: TextStyle(
                          fontStyle: report.titleItalicized
                              ? FontStyle.italic
                              : FontStyle.normal,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                background: topBarBackground == null
                    ? null
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          topBarBackground!,
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
                        ],
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: cardBuilder != null
                  ? Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                      ),
                      child: cardBuilder!.call(),
                    )
                  : const SizedBox.shrink(),
            ),
            SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                ReportInfoList<TReport>(
                  report: report,
                  extraFields: extraFields,
                ),
                const Divider(thickness: 0.1),
                ReportMap<TReport>(report: report),
                const SizedBox(height: 20),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
