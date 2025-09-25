import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';

class ReportsListSites extends StatefulWidget {
  const ReportsListSites({super.key});

  @override
  State<ReportsListSites> createState() => _ReportsListSitesState();
}

class _ReportsListSitesState extends State<ReportsListSites> {
  @override
  Widget build(BuildContext context) {
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Text(MyLocalizations.of(context, 'no_reports_yet_txt')),
    );
  }
}
