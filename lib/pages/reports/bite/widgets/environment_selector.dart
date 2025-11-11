import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

/// Widget for selecting the environment where biting occurred
class EnvironmentSelector extends StatelessWidget {
  final BiteRequestEventEnvironmentEnum? selectedEnvironment;
  final Function(BiteRequestEventEnvironmentEnum?) onEnvironmentChanged;

  const EnvironmentSelector({
    Key? key,
    this.selectedEnvironment,
    required this.onEnvironmentChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildOptionTile(
          context,
          BiteRequestEventEnvironmentEnum.indoors,
          MyLocalizations.of(context, 'question_13_answer_132'),
          Icons.home,
        ),
        SizedBox(height: 12),
        _buildOptionTile(
          context,
          BiteRequestEventEnvironmentEnum.outdoors,
          MyLocalizations.of(context, 'question_13_answer_133'),
          Icons.park,
        ),
        SizedBox(height: 12),
        _buildOptionTile(
          context,
          BiteRequestEventEnvironmentEnum.vehicle,
          MyLocalizations.of(context, 'question_13_answer_131'),
          Icons.directions_car,
        ),
        SizedBox(height: 12),
        _buildOptionTile(
          context,
          null, // null represents "I don't know"
          MyLocalizations.of(context, 'question_4_answer_44'),
          Icons.help_outline,
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    BiteRequestEventEnvironmentEnum? environment,
    String title,
    IconData icon,
  ) {
    final bool isSelected = selectedEnvironment == environment;

    return GestureDetector(
      onTap: () => onEnvironmentChanged(environment),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Style.colorPrimary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Style.colorPrimary.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Style.colorPrimary.withValues(alpha: 0.1)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? Style.colorPrimary : Colors.grey[600],
                size: 24,
              ),
            ),

            SizedBox(width: 16),

            // Text content
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: isSelected ? Style.colorPrimary : Colors.black,
                ),
              ),
            ),

            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Style.colorPrimary,
                size: 24,
              )
            else
              Icon(
                Icons.radio_button_unchecked,
                color: Colors.grey[400],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
