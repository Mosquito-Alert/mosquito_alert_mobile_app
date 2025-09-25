import 'package:flutter/material.dart';
import 'package:mosquito_alert/mosquito_alert.dart';
import 'package:mosquito_alert_app/utils/style.dart';

/// Widget for selecting when the biting occurred
class TimingSelector extends StatelessWidget {
  final BiteRequestEventMomentEnum? selectedTiming;
  final Function(BiteRequestEventMomentEnum) onTimingChanged;

  const TimingSelector({
    Key? key,
    this.selectedTiming,
    required this.onTimingChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildOptionTile(
          context,
          BiteRequestEventMomentEnum.now,
          '(HC) Right now / Just happened',
          '(HC) The biting is happening now or just occurred',
          Icons.access_time,
        ),
        SizedBox(height: 12),
        _buildOptionTile(
          context,
          BiteRequestEventMomentEnum.lastMorning,
          '(HC) Yesterday morning',
          '(HC) Between 6:00 AM - 12:00 PM yesterday',
          Icons.wb_sunny,
        ),
        SizedBox(height: 12),
        _buildOptionTile(
          context,
          BiteRequestEventMomentEnum.lastMidday,
          '(HC) Yesterday midday',
          '(HC) Between 12:00 PM - 6:00 PM yesterday',
          Icons.wb_sunny_outlined,
        ),
        SizedBox(height: 12),
        _buildOptionTile(
          context,
          BiteRequestEventMomentEnum.lastAfternoon,
          '(HC) Yesterday afternoon',
          '(HC) Between 6:00 PM - 9:00 PM yesterday',
          Icons.wb_twilight,
        ),
        SizedBox(height: 12),
        _buildOptionTile(
          context,
          BiteRequestEventMomentEnum.lastNight,
          '(HC) Last night',
          '(HC) Between 9:00 PM yesterday - 6:00 AM today',
          Icons.nightlight_round,
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    BiteRequestEventMomentEnum timing,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final bool isSelected = selectedTiming == timing;

    return GestureDetector(
      onTap: () => onTimingChanged(timing),
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
