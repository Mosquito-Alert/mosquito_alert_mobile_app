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

  Future<bool?> _showDeleteLocalDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
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
                      await provider.deleteLocal(item: report);
                      Navigator.of(context).pop(true);
                    } catch (e) {
                      Navigator.of(context).pop(false);
                    } finally {
                      setState(() => isDeleting = false);
                    }
                  },
                ),
                if (isDeleting)
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
    final syncError = provider.getSyncError(report);
    final hasSyncError = syncError != null;

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
              actions: _buildAppBarActions(context, hasSyncError: hasSyncError),
              flexibleSpace: FlexibleSpaceBar(
                title: Text.rich(
                  TextSpan(
                    children: [
                      if (report.isOffline) ...[
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(
                            hasSyncError
                                ? Icons.error_outline
                                : Icons.cloud_off_outlined,
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
            if (hasSyncError)
              SliverToBoxAdapter(
                child: _SyncErrorBanner(
                  errorMessage: syncError,
                  onRetry: () => _retry(context),
                  onDeleteLocal: () => _deleteLocal(context),
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

  List<Widget> _buildAppBarActions(
    BuildContext context, {
    required bool hasSyncError,
  }) {
    // When a queued create permanently failed, let the user retry or delete
    // the local copy. Pending-but-not-failed offline reports still get no
    // menu (user simply waits for sync).
    if (report.isOffline) {
      if (!hasSyncError) return const [];
      return [
        PopupMenuButton<int>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 0) {
              await _retry(context);
            } else if (value == 1) {
              await _deleteLocal(context);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem<int>(
              value: 0,
              child: Row(
                children: [
                  const Icon(Icons.refresh),
                  const SizedBox(width: 8),
                  Text(MyLocalizations.of(context, 'retry')),
                ],
              ),
            ),
            PopupMenuItem<int>(
              value: 1,
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    MyLocalizations.of(context, 'delete_local_copy'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ],
        ),
      ];
    }
    return [
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
    ];
  }

  Future<void> _retry(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await provider.retrySync(item: report);
      if (!context.mounted) return;
      // If the retry cleared the error, the report may have been replaced by
      // a server-backed copy and this route should refresh.
      final stillHasError = provider.getSyncError(report) != null;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            stillHasError
                ? MyLocalizations.of(context, 'sync_error_retry_failed')
                : MyLocalizations.of(context, 'sync_error_retry_success'),
          ),
          backgroundColor: stillHasError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _deleteLocal(BuildContext context) async {
    final deleted = await _showDeleteLocalDialog(context);
    if (deleted == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }
}

class _SyncErrorBanner extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onDeleteLocal;

  const _SyncErrorBanner({
    required this.errorMessage,
    required this.onRetry,
    required this.onDeleteLocal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  MyLocalizations.of(context, 'sync_error_title'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            MyLocalizations.of(context, 'sync_error_description'),
            style: TextStyle(color: Colors.red.shade900, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            errorMessage,
            style: TextStyle(
              color: Colors.red.shade900,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(MyLocalizations.of(context, 'retry')),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: onDeleteLocal,
                icon: Icon(Icons.delete, size: 18, color: Colors.red.shade700),
                label: Text(
                  MyLocalizations.of(context, 'delete_local_copy'),
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
