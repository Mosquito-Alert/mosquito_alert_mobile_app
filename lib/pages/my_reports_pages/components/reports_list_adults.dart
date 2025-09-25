import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';

class ReportsListAdults extends StatefulWidget {
  const ReportsListAdults({super.key});

  @override
  State<ReportsListAdults> createState() => _ReportsListAdultsState();
}

class _ReportsListAdultsState extends State<ReportsListAdults> {
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
