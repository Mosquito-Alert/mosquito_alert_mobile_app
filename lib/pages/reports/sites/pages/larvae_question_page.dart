import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

import '../models/breeding_site_report_data.dart';

class LarvaeQuestionPage extends StatefulWidget {
  final BreedingSiteReportData reportData;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const LarvaeQuestionPage({
    Key? key,
    required this.reportData,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  _LarvaeQuestionPageState createState() => _LarvaeQuestionPageState();
}

class _LarvaeQuestionPageState extends State<LarvaeQuestionPage> {
  void _selectLarvaeStatus(bool hasLarvae) {
    setState(() {
      widget.reportData.hasLarvae = hasLarvae;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> _larvaeOptions = [
      {
        'value': true,
        'titleKey': 'question_10_answer_101', // Yes
        'icon': Icons.bug_report,
        'color': Colors.red,
      },
      {
        'value': false,
        'titleKey': 'question_10_answer_102', // No
        'icon': Icons.bug_report_outlined,
        'color': Colors.grey,
      },
    ];
    return Stack(
      children: [
        // Background image at bottom, undistorted
        Align(
          alignment: Alignment.bottomCenter,
          child: Image.asset(
            'assets/img/bottoms/breeding_3.webp',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
          ),
        ),
        // Main content
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                MyLocalizations.of(context, 'question_17'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 24),

              // Options
              Expanded(
                child: ListView.builder(
                  itemCount: _larvaeOptions.length,
                  itemBuilder: (context, index) {
                    final option = _larvaeOptions[index];
                    final isSelected =
                        widget.reportData.hasLarvae == option['value'];

                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          _selectLarvaeStatus(option['value']);
                          // Auto-proceed to next step after selection
                          widget.onNext();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Style.colorPrimary
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isSelected
                                ? Style.colorPrimary.withValues(alpha: 0.1)
                                : Colors.white,
                          ),
                          child: Row(
                            children: [
                              // Icon
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: option['color'].withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  option['icon'],
                                  size: 32,
                                  color: option['color'],
                                ),
                              ),

                              SizedBox(width: 16),

                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      MyLocalizations.of(
                                          context, option['titleKey']),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Style.colorPrimary
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Selection indicator
                              if (isSelected)
                                Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Style.colorPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
