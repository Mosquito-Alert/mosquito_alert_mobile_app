import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

import '../models/adult_report_data.dart';

class EnvironmentQuestionPage extends StatefulWidget {
  final AdultReportData reportData;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const EnvironmentQuestionPage({
    Key? key,
    required this.reportData,
    required this.onNext,
    required this.onPrevious,
  }) : super(key: key);

  @override
  _EnvironmentQuestionPageState createState() =>
      _EnvironmentQuestionPageState();
}

class _EnvironmentQuestionPageState extends State<EnvironmentQuestionPage> {
  final List<Map<String, dynamic>> _environmentOptions = [
    {
      'value': 'vehicle',
      'titleKey': 'question_4_answer_41',
      'description': '(HC) Car, bus, train, or any other vehicle',
      'icon': Icons.directions_car,
    },
    {
      'value': 'indoors',
      'titleKey': 'question_4_answer_42',
      'description': '(HC) House, office, shop, or any indoor space',
      'icon': Icons.home,
    },
    {
      'value': 'outdoors',
      'titleKey': 'question_4_answer_43',
      'description': '(HC) Garden, park, street, or any outdoor space',
      'icon': Icons.park,
    },
  ];

  void _selectOption(String value) {
    setState(() {
      widget.reportData.environmentAnswer = value;
    });
  }

  bool get _canProceed => widget.reportData.environmentAnswer != null;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.quiz, color: Style.colorPrimary),
                      SizedBox(width: 8),
                      Text(
                        'Environment Question',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    MyLocalizations.of(context, "question_13"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '(HC) This information helps researchers understand mosquito behavior and habitat preferences.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Options
          Expanded(
            child: ListView.builder(
              itemCount: _environmentOptions.length,
              itemBuilder: (context, index) {
                final option = _environmentOptions[index];
                final isSelected =
                    widget.reportData.environmentAnswer == option['value'];

                return Card(
                  margin: EdgeInsets.only(bottom: 12),
                  elevation: isSelected ? 4 : 1,
                  child: InkWell(
                    onTap: () => _selectOption(option['value']),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(color: Style.colorPrimary, width: 2)
                            : Border.all(color: Colors.grey[300]!, width: 1),
                        color: isSelected
                            ? Style.colorPrimary.withValues(alpha: 0.05)
                            : Colors.white,
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Style.colorPrimary
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              option['icon'],
                              color:
                                  isSelected ? Colors.white : Colors.grey[600],
                              size: 24,
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Style.colorPrimary
                                        : Colors.black,
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
                            Icon(
                              Icons.check_circle,
                              color: Style.colorPrimary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Navigation buttons
          SizedBox(
            width: double.infinity,
            child: Style.button(
              MyLocalizations.of(context, 'continue_txt'),
              _canProceed ? widget.onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}
