import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';

class ReportCreationStepIndicator extends StatelessWidget {
  const ReportCreationStepIndicator({super.key, required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: List.generate(tabController.length, (index) {
          final isCompleted = index < tabController.index;
          final isCurrent = index == tabController.index;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? Style.colorPrimary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
