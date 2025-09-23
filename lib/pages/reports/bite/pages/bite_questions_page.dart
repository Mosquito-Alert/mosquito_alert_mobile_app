import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as api;
import 'package:mosquito_alert_app/pages/reports/bite/models/bite_report_data.dart';
import 'package:mosquito_alert_app/pages/reports/bite/widgets/body_part_selector.dart';
import 'package:mosquito_alert_app/pages/reports/bite/widgets/environment_selector.dart';
import 'package:mosquito_alert_app/pages/reports/bite/widgets/timing_selector.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:provider/provider.dart';

/// Page for collecting bite information: counts, environment, and timing
class BiteQuestionsPage extends StatefulWidget {
  final Function(api.BiteRequestEventEnvironmentEnum) onEnvironmentChanged;
  final Function(api.BiteRequestEventMomentEnum) onTimingChanged;
  final VoidCallback? onNext;
  final VoidCallback onPrevious;
  final bool canProceed;

  const BiteQuestionsPage({
    Key? key,
    required this.onEnvironmentChanged,
    required this.onTimingChanged,
    this.onNext,
    required this.onPrevious,
    required this.canProceed,
  }) : super(key: key);

  @override
  _BiteQuestionsPageState createState() => _BiteQuestionsPageState();
}

class _BiteQuestionsPageState extends State<BiteQuestionsPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<BiteReportData>(
      builder: (context, reportData, child) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                '(HC) Bite Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Visual body part selector
                      const BodyPartSelector(),

                      SizedBox(height: 32),

                      // Environment question
                      Text(
                        MyLocalizations.of(context, "question_4"),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 16),

                      EnvironmentSelector(
                        selectedEnvironment: reportData.eventEnvironment,
                        onEnvironmentChanged: widget.onEnvironmentChanged,
                      ),

                      SizedBox(height: 32),

                      // Timing question
                      Text(
                        '(HC) When did the biting occur?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      SizedBox(height: 16),

                      TimingSelector(
                        selectedTiming: reportData.eventMoment,
                        onTimingChanged: widget.onTimingChanged,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Navigation buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onPrevious,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text('(HC) Back'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: widget.canProceed ? widget.onNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text(
                        MyLocalizations.of(context, 'continue_txt'),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
