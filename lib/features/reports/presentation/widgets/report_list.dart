import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:infinite_scroll_pagination/src/defaults/first_page_exception_indicator.dart';
import 'package:mosquito_alert_app/features/reports/domain/models/base_report.dart';
import 'package:mosquito_alert_app/features/reports/presentation/widgets/report_list_tile.dart';
import 'package:mosquito_alert_app/features/reports/presentation/state/report_provider.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';

class ReportList<TReport extends BaseReportModel> extends StatefulWidget {
  final ReportProvider<TReport, dynamic> provider;
  final ReportListTile<TReport> Function({required dynamic report}) tileBuilder;

  const ReportList({
    super.key,
    required this.provider,
    required this.tileBuilder,
  });

  @override
  _ReportList createState() => _ReportList();
}

class SectionHeader {
  final DateTime date;

  SectionHeader(this.date);

  String get formattedDate => DateFormat.yMMMMd().format(date);
}

class _ReportList<TReport extends BaseReportModel>
    extends State<ReportList<TReport>> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.provider.loadedInitial == false) {
        widget.provider.loadInitial();
      }
    });
  }

  List<Object> _addHeaders(List<TReport> objects) {
    if (objects.isEmpty) return [];

    // Group items by date
    final List<Object> itemsWithHeaders = [];
    DateTime? lastDate;
    for (var item in objects) {
      final createdAt = item.createdAtLocal.toLocal();
      final currentDate = DateTime(
        createdAt.year,
        createdAt.month,
        createdAt.day,
      );
      // NOTE: assuming items are sorted by createdAt descending
      if (lastDate == null || currentDate.isBefore(lastDate)) {
        itemsWithHeaders.add(SectionHeader(currentDate));
        lastDate = currentDate;
      }
      itemsWithHeaders.add(item as Object);
    }
    return itemsWithHeaders;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => widget.provider.refresh(),
      child: PagedListView<int, Object>.separated(
        state: PagingState(
          pages: [_addHeaders(widget.provider.items)],
          keys: [1],
          hasNextPage: widget.provider.hasMore,
          isLoading: widget.provider.isLoading,
          error: widget.provider.error,
        ),
        fetchNextPage: widget.provider.loadMore,
        builderDelegate: PagedChildBuilderDelegate<Object>(
          noItemsFoundIndicatorBuilder: (context) =>
              FirstPageExceptionIndicator(
                title: MyLocalizations.of(context, 'no_reports_yet_txt'),
              ),
          itemBuilder: (context, item, index) {
            if (item is SectionHeader) {
              return Container(
                color: Colors.grey[200],
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 8,
                  ),
                  child: Text(
                    item.formattedDate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            } else if (item is TReport) {
              return widget.tileBuilder(report: item);
            } else {
              return const SizedBox.shrink(); // Fallback for unknown types
            }
          },
        ),
        separatorBuilder: (context, index) =>
            const Divider(thickness: 0.2, height: 1, color: Colors.grey),
      ),
    );
  }
}
