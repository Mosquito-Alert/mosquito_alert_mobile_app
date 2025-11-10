import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';
import 'package:provider/provider.dart';

import '../models/bite_report_data.dart';

class BodyPartSelector extends StatelessWidget {
  final maxBiteCountPerPart = 20;

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
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            buildVisualBodySelector(context, data,
                maxBiteCountPerPart: maxBiteCountPerPart),
          ],
        );
      },
    );
  }

  static Widget buildVisualBodySelector(
      BuildContext context, BiteReportData data,
      {int maxBiteCountPerPart = 20, bool isEditable = true}) {
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
              maxBiteCountPerPart,
              isEditable,
              (value) => data.headBites = value,
              const Rect.fromLTWH(0.35, 0.05, 0.3, 0.15),
            ),
            _buildBodyPartOverlay(
              context,
              data,
              'chest',
              data.chestBites,
              maxBiteCountPerPart,
              isEditable,
              (value) => data.chestBites = value,
              const Rect.fromLTWH(0.375, 0.25, 0.25, 0.3),
            ),
            _buildBodyPartOverlay(
              context,
              data,
              'left_hand',
              data.leftHandBites,
              maxBiteCountPerPart,
              isEditable,
              (value) => data.leftHandBites = value,
              const Rect.fromLTWH(0.05, 0.3, 0.25, 0.2),
            ),
            _buildBodyPartOverlay(
              context,
              data,
              'right_hand',
              data.rightHandBites,
              maxBiteCountPerPart,
              isEditable,
              (value) => data.rightHandBites = value,
              const Rect.fromLTWH(0.75, 0.3, 0.25, 0.2),
            ),
            _buildBodyPartOverlay(
              context,
              data,
              'left_leg',
              data.leftLegBites,
              maxBiteCountPerPart,
              isEditable,
              (value) => data.leftLegBites = value,
              const Rect.fromLTWH(0.25, 0.55, 0.25, 0.4),
            ),
            _buildBodyPartOverlay(
              context,
              data,
              'right_leg',
              data.rightLegBites,
              maxBiteCountPerPart,
              isEditable,
              (value) => data.rightLegBites = value,
              const Rect.fromLTWH(0.5, 0.55, 0.25, 0.4),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildBodyPartOverlay(
    BuildContext context,
    BiteReportData data,
    String bodyPart,
    int biteCount,
    int maxAllowedBite,
    bool isEditable,
    Function(int) onChanged,
    Rect relativeRect,
  ) {
    return Positioned(
      left: relativeRect.left * 320, // Updated to match new container width
      top: relativeRect.top * 480, // Updated to match new container height
      width: relativeRect.width * 320,
      height: relativeRect.height * 480,
      child: GestureDetector(
        onTap: () => isEditable
            ? _showBodyPartDialog(
                context, bodyPart, biteCount, maxAllowedBite, onChanged)
            : null,
        child: Container(
          decoration: BoxDecoration(
            // More visible borders for debugging positioning
            color: biteCount > 0
                ? Style.colorPrimary.withValues(alpha: 0.15)
                : isEditable
                    ? Colors.blue.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: biteCount > 0
                    ? Style.colorPrimary.withValues(alpha: 0.6)
                    : isEditable
                        ? Colors.blue.withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.4),
                width: 2),
          ),
          child: Stack(
            children: [
              // Subtle tap indicator when no bites
              if (isEditable && biteCount == 0)
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
                  right: 2,
                  child: Container(
                    constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Style.colorPrimary,
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

  static void _showBodyPartDialog(
    BuildContext context,
    String bodyPart,
    int currentCount,
    int maxAllowedBite,
    Function(int) onChanged,
  ) {
    String displayName = _getBodyPartTranslation(context, bodyPart);

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
                Text(displayName),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '(HC) How many bites on your ${displayName.toLowerCase()}?',
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
                          onTap: tempCount < maxAllowedBite
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
                              color: tempCount < maxAllowedBite
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

                if (tempCount >= maxAllowedBite)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '(HC) Maximum $maxAllowedBite bites per body part',
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
                child: Text(MyLocalizations.of(context, 'cancel')),
              ),
              Style.button(
                MyLocalizations.of(context, 'save'),
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

  static IconData _getBodyPartIcon(String bodyPart) {
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

  static String _getBodyPartTranslation(BuildContext context, String bodyPart) {
    switch (bodyPart) {
      case 'head':
        return MyLocalizations.of(context, 'bite_report_bodypart_head');
      case 'chest':
        return MyLocalizations.of(context, 'question_2_answer_24');
      case 'left_hand':
        return MyLocalizations.of(context, 'bite_report_bodypart_leftarm');
      case 'right_hand':
        return MyLocalizations.of(context, 'bite_report_bodypart_rightarm');
      case 'left_leg':
        return MyLocalizations.of(context, 'bite_report_bodypart_leftleg');
      case 'right_leg':
        return MyLocalizations.of(context, 'bite_report_bodypart_rightleg');
      default:
        return '(HC) ${bodyPart.replaceAll('_', ' ')}';
    }
  }
}
