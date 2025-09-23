import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart' as api;
import 'package:mosquito_alert_app/utils/style.dart';

/// Widget for selecting the environment where biting occurred
class EnvironmentSelector extends StatelessWidget {
  final api.BiteRequestEventEnvironmentEnum? selectedEnvironment;
  final Function(api.BiteRequestEventEnvironmentEnum) onEnvironmentChanged;

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
          api.BiteRequestEventEnvironmentEnum.indoors,
          '(HC) Indoors',
          '(HC) Inside a building, house, office, etc.',
          Icons.home,
        ),
        SizedBox(height: 12),
        _buildOptionTile(
          context,
          api.BiteRequestEventEnvironmentEnum.outdoors,
          '(HC) Outdoors',
          '(HC) Outside in open air, garden, park, etc.',
          Icons.park,
        ),
        SizedBox(height: 12),
        _buildOptionTile(
          context,
          api.BiteRequestEventEnvironmentEnum.vehicle,
          '(HC) In a Vehicle',
          '(HC) Inside a car, bus, train, etc.',
          Icons.directions_car,
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    api.BiteRequestEventEnvironmentEnum environment,
    String title,
    String subtitle,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isSelected ? Style.colorPrimary : Colors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
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
