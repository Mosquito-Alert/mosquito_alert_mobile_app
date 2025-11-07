import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/pages/reports/bite/widgets/body_part_selector.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:provider/provider.dart';

import '../models/bite_report_data.dart';

/// Page for collecting bite information: counts, environment, and timing
class BiteQuestionsPage extends StatefulWidget {
  final Function(BiteRequestEventEnvironmentEnum?) onEnvironmentChanged;
  final Function(BiteRequestEventMomentEnum) onTimingChanged;
  final VoidCallback? onNext;
  final VoidCallback onPrevious;

  const BiteQuestionsPage({
    Key? key,
    required this.onEnvironmentChanged,
    required this.onTimingChanged,
    this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  _BiteQuestionsPageState createState() => _BiteQuestionsPageState();
}

class _BiteQuestionsPageState extends State<BiteQuestionsPage> {
  @override
  Widget build(BuildContext context) {
    final biteReport = context.watch<BiteReportData>();
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BodyPartSelector(),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: Style.button(
                        MyLocalizations.of(context, 'continue_txt'),
                        biteReport.hasValidBiteCounts ? widget.onNext : null,
                      ),
                    )
                  ],
                ))));
  }
}
