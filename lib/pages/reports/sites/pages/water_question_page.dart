import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

import '../models/breeding_site_report_data.dart';

class WaterQuestionPage extends StatefulWidget {
  final BreedingSiteReportData reportData;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const WaterQuestionPage({
    Key? key,
    required this.reportData,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  _WaterQuestionPageState createState() => _WaterQuestionPageState();
}

class _WaterQuestionPageState extends State<WaterQuestionPage> {
  final List<Map<String, dynamic>> _waterOptions = [
    {
      'value': true,
      'titleKey': 'question_10_answer_101', // Yes
      'description': '(HC) Water is present in the breeding site',
      'icon': Icons.water_drop,
      'color': Colors.blue,
    },
    {
      'value': false,
      'titleKey': 'question_10_answer_102', // No
      'description': '(HC) No water visible in the breeding site',
      'icon': Icons.water_drop_outlined,
      'color': Colors.grey,
    },
  ];

  void _selectWaterStatus(bool hasWater) {
    setState(() {
      widget.reportData.hasWater = hasWater;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image at bottom
        Align(
          alignment: Alignment.bottomCenter,
          child: Image.asset(
            'assets/img/bottoms/breeding_2.webp',
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
          ),
        ),
        // Main content with adjusted padding
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                MyLocalizations.of(context, 'question_10'),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),

              // Subtitle
              Text(
                '(HC) Please indicate if you can see water in the breeding site:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              SizedBox(height: 24),

              // Options
              Expanded(
                child: ListView.builder(
                  itemCount: _waterOptions.length,
                  itemBuilder: (context, index) {
                    final option = _waterOptions[index];
                    final isSelected =
                        widget.reportData.hasWater == option['value'];

                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          _selectWaterStatus(option['value']);
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
                                    SizedBox(height: 4),
                                    Text(
                                      option['description'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
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
