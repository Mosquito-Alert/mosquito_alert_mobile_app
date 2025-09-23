import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:provider/provider.dart';

import '../models/bite_report_data.dart';

class BodyPartSelector extends StatelessWidget {
  const BodyPartSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BiteReportData>(
      builder: (context, data, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              MyLocalizations.of(context, 'question_2'),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildVisualBodySelector(context, data),
            const SizedBox(height: 24),
            _buildBiteSummary(context, data),
          ],
        );
      },
    );
  }

  Widget _buildVisualBodySelector(BuildContext context, BiteReportData data) {
    return Center(
      child: Container(
        width: 320,
        height: 480,
        child: Stack(
          children: [
            // Base body image - centered and properly sized
            Positioned.fill(
              child: Image.asset(
                'assets/img/ic_full_body_off.webp',
                fit: BoxFit.contain,
              ),
            ),

            // Clickable regions using relative coordinates (0.0 to 1.0)
            // Format: Rect.fromLTWH(left, top, width, height)
            // All values are percentages of container (320x480)

            _buildBodyPartOverlay(
              context,
              data,
              'head',
              data.headBites,
              (value) => data.headBites = value,
              const Rect.fromLTWH(0.35, 0.05, 0.3, 0.15),
            ),
            _buildBodyPartOverlay(
              context,
              data,
              'chest',
              data.chestBites,
              (value) => data.chestBites = value,
              const Rect.fromLTWH(0.375, 0.25, 0.25, 0.3),
            ),
            _buildBodyPartOverlay(
              context,
              data,
              'left_hand',
              data.leftHandBites,
              (value) => data.leftHandBites = value,
              const Rect.fromLTWH(0.05, 0.3, 0.25, 0.2),
            ),
            _buildBodyPartOverlay(
              context,
              data,
              'right_hand',
              data.rightHandBites,
              (value) => data.rightHandBites = value,
              const Rect.fromLTWH(0.75, 0.3, 0.25, 0.2),
            ),
            _buildBodyPartOverlay(
              context,
              data,
              'left_leg',
              data.leftLegBites,
              (value) => data.leftLegBites = value,
              const Rect.fromLTWH(0.25, 0.55, 0.25, 0.4),
            ),
            _buildBodyPartOverlay(
              context,
              data,
              'right_leg',
              data.rightLegBites,
              (value) => data.rightLegBites = value,
              const Rect.fromLTWH(0.5, 0.55, 0.25, 0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyPartOverlay(
    BuildContext context,
    BiteReportData data,
    String bodyPart,
    int biteCount,
    Function(int) onChanged,
    Rect relativeRect,
  ) {
    return Positioned(
      left: relativeRect.left * 320, // Updated to match new container width
      top: relativeRect.top * 480, // Updated to match new container height
      width: relativeRect.width * 320,
      height: relativeRect.height * 480,
      child: GestureDetector(
        onTap: () =>
            _showBodyPartDialog(context, bodyPart, biteCount, onChanged),
        child: Container(
          decoration: BoxDecoration(
            // More visible borders for debugging positioning
            color: biteCount > 0
                ? Colors.red.withValues(alpha: 0.15)
                : Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: biteCount > 0
                    ? Colors.red.withValues(alpha: 0.6)
                    : Colors.blue.withValues(alpha: 0.4),
                width: 2),
          ),
          child: Stack(
            children: [
              // Subtle tap indicator when no bites
              if (biteCount == 0)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.touch_app,
                      color: Colors.blue.withValues(alpha: 0.3),
                      size: 16,
                    ),
                  ),
                ),
              // Show bite count badge if there are bites
              if (biteCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$biteCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBodyPartDialog(
    BuildContext context,
    String bodyPart,
    int currentCount,
    Function(int) onChanged,
  ) {
    String displayName = bodyPart
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempCount = currentCount;
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  _getBodyPartIcon(bodyPart),
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(width: 8),
                Text('$displayName Bites'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'How many bites on your ${displayName.toLowerCase()}?',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Enhanced counter with better UX
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Decrease button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: tempCount > 0
                              ? () {
                                  setState(() {
                                    tempCount--;
                                  });
                                }
                              : null,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: tempCount > 0
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.remove,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),

                      // Count display
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: tempCount > 0
                              ? Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tempCount > 0
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '$tempCount',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: tempCount > 0
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),

                      // Increase button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: tempCount < 20
                              ? () {
                                  setState(() {
                                    tempCount++;
                                  });
                                }
                              : null,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: tempCount < 20
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey[300],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (tempCount >= 20)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Maximum 20 bites per body part',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              Style.button(
                'Save',
                () {
                  onChanged(tempCount);
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
      },
    );
  }

  IconData _getBodyPartIcon(String bodyPart) {
    switch (bodyPart) {
      case 'head':
        return Icons.face;
      case 'chest':
        return Icons.accessibility_new;
      case 'left_hand':
      case 'right_hand':
        return Icons.front_hand;
      case 'left_leg':
      case 'right_leg':
        return Icons.directions_walk;
      default:
        return Icons.touch_app;
    }
  }

  Widget _buildBiteSummary(BuildContext context, BiteReportData data) {
    final totalBites = data.headBites +
        data.chestBites +
        data.leftHandBites +
        data.rightHandBites +
        data.leftLegBites +
        data.rightLegBites;

    if (totalBites == 0) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.touch_app,
              color: Colors.blue[600],
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tap on body parts above to report bites',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Total bites card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[400]!, Colors.red[600]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bug_report,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'Total bites: $totalBites',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Individual bite breakdown
        Text(
          'Breakdown by body part:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),

        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (data.headBites > 0)
              _buildBiteChip('Head', data.headBites, Icons.face),
            if (data.chestBites > 0)
              _buildBiteChip('Chest', data.chestBites, Icons.accessibility_new),
            if (data.leftHandBites > 0)
              _buildBiteChip('Left Hand', data.leftHandBites, Icons.front_hand),
            if (data.rightHandBites > 0)
              _buildBiteChip(
                  'Right Hand', data.rightHandBites, Icons.front_hand),
            if (data.leftLegBites > 0)
              _buildBiteChip(
                  'Left Leg', data.leftLegBites, Icons.directions_walk),
            if (data.rightLegBites > 0)
              _buildBiteChip(
                  'Right Leg', data.rightLegBites, Icons.directions_walk),
          ],
        ),
      ],
    );
  }

  Widget _buildBiteChip(String label, int count, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.red[700],
          ),
          SizedBox(width: 4),
          Text(
            '$label: $count',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
