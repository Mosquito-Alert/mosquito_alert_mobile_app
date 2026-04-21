import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/core/localizations/MyLocalizations.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';
import 'package:mosquito_alert_app/features/bites/domain/models/body_part.dart';

class BiteStickMan extends StatefulWidget {
  static const int maxBiteCountPerPart = 20;
  final int headBites;
  final int chestBites;
  final int leftHandBites;
  final int rightHandBites;
  final int leftLegBites;
  final int rightLegBites;
  final void Function(BodyPartEnum bodyPart, int newCount)? onChanged;

  const BiteStickMan({
    super.key,
    this.headBites = 0,
    this.chestBites = 0,
    this.leftHandBites = 0,
    this.rightHandBites = 0,
    this.leftLegBites = 0,
    this.rightLegBites = 0,
    this.onChanged,
  });

  @override
  _BiteStickManState createState() => _BiteStickManState();
}

class _BiteStickManState extends State<BiteStickMan> {
  late int headBites;
  late int chestBites;
  late int leftHandBites;
  late int rightHandBites;
  late int leftLegBites;
  late int rightLegBites;

  @override
  void initState() {
    super.initState();
    headBites = widget.headBites;
    chestBites = widget.chestBites;
    leftHandBites = widget.leftHandBites;
    rightHandBites = widget.rightHandBites;
    leftLegBites = widget.leftLegBites;
    rightLegBites = widget.rightLegBites;
  }

  @override
  Widget build(BuildContext context) {
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
              relativeRect: const Rect.fromLTWH(0.35, 0.05, 0.3, 0.15),
              count: headBites,
              onTap: widget.onChanged != null
                  ? () {
                      _showBodyPartDialog(
                        bodyPart: BodyPartEnum.head,
                        count: headBites,
                        onSave: (newCount) {
                          setState(() {
                            headBites = newCount;
                          });
                          widget.onChanged?.call(BodyPartEnum.head, newCount);
                        },
                      );
                    }
                  : null,
            ),
            _buildBodyPartOverlay(
              relativeRect: const Rect.fromLTWH(0.375, 0.25, 0.25, 0.3),
              count: chestBites,
              onTap: widget.onChanged != null
                  ? () {
                      _showBodyPartDialog(
                        bodyPart: BodyPartEnum.chest,
                        count: chestBites,
                        onSave: (newCount) {
                          setState(() {
                            chestBites = newCount;
                          });
                          widget.onChanged?.call(BodyPartEnum.chest, newCount);
                        },
                      );
                    }
                  : null,
            ),
            _buildBodyPartOverlay(
              relativeRect: const Rect.fromLTWH(0.05, 0.3, 0.25, 0.2),
              count: leftHandBites,
              onTap: widget.onChanged != null
                  ? () {
                      _showBodyPartDialog(
                        bodyPart: BodyPartEnum.leftHand,
                        count: leftHandBites,
                        onSave: (newCount) {
                          setState(() {
                            leftHandBites = newCount;
                          });
                          widget.onChanged?.call(
                            BodyPartEnum.leftHand,
                            newCount,
                          );
                        },
                      );
                    }
                  : null,
            ),
            _buildBodyPartOverlay(
              relativeRect: const Rect.fromLTWH(0.75, 0.3, 0.25, 0.2),
              count: rightHandBites,
              onTap: widget.onChanged != null
                  ? () {
                      _showBodyPartDialog(
                        bodyPart: BodyPartEnum.rightHand,
                        count: rightHandBites,
                        onSave: (newCount) {
                          setState(() {
                            rightHandBites = newCount;
                          });
                          widget.onChanged?.call(
                            BodyPartEnum.rightHand,
                            newCount,
                          );
                        },
                      );
                    }
                  : null,
            ),
            _buildBodyPartOverlay(
              relativeRect: const Rect.fromLTWH(0.25, 0.55, 0.25, 0.4),
              count: leftLegBites,
              onTap: widget.onChanged != null
                  ? () {
                      _showBodyPartDialog(
                        bodyPart: BodyPartEnum.leftLeg,
                        count: leftLegBites,
                        onSave: (newCount) {
                          setState(() {
                            leftLegBites = newCount;
                          });
                          widget.onChanged?.call(
                            BodyPartEnum.leftLeg,
                            newCount,
                          );
                        },
                      );
                    }
                  : null,
            ),
            _buildBodyPartOverlay(
              relativeRect: const Rect.fromLTWH(0.5, 0.55, 0.25, 0.4),
              count: rightLegBites,
              onTap: widget.onChanged != null
                  ? () {
                      _showBodyPartDialog(
                        bodyPart: BodyPartEnum.rightLeg,
                        count: rightLegBites,
                        onSave: (newCount) {
                          setState(() {
                            rightLegBites = newCount;
                          });
                          widget.onChanged?.call(
                            BodyPartEnum.rightLeg,
                            newCount,
                          );
                        },
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyPartOverlay({
    required Rect relativeRect,
    required int count,
    VoidCallback? onTap,
  }) {
    // TODO: use FractionallySizedBox for better responsiveness
    return Positioned(
      left: relativeRect.left * 320, // Updated to match new container width
      top: relativeRect.top * 480, // Updated to match new container height
      width: relativeRect.width * 320,
      height: relativeRect.height * 480,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            // More visible borders for debugging positioning
            color: count > 0
                ? Style.colorPrimary.withValues(alpha: 0.15)
                : onTap != null
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: count > 0
                  ? Style.colorPrimary.withValues(alpha: 0.6)
                  : onTap != null
                  ? Colors.blue.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Stack(
            children: [
              // Subtle tap indicator when no bites
              if (onTap != null && count == 0)
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
              if (count > 0)
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
                      '$count',
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

  void _showBodyPartDialog({
    required BodyPartEnum bodyPart,
    required int count,
    required void Function(int newCount) onSave,
  }) {
    String displayName = _getBodyPartTranslation(bodyPart: bodyPart);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int tempCount = count;
        return StatefulBuilder(
          builder: (context, setState) {
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
                    MyLocalizations.of(
                      context,
                      'indicate_number_mosquito_bites',
                    ),
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
                                ? Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1)
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
                            onTap: tempCount < BiteStickMan.maxBiteCountPerPart
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
                                color:
                                    tempCount < BiteStickMan.maxBiteCountPerPart
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

                  if (tempCount >= BiteStickMan.maxBiteCountPerPart)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        MyLocalizations.of(
                          context,
                          'reached_maximum_allowed_mosquito_bites',
                        ),
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(MyLocalizations.of(context, 'cancel')),
                ),
                FilledButton(
                  onPressed: () {
                    onSave(tempCount);
                    Navigator.of(context).pop();
                  },
                  child: Text(MyLocalizations.of(context, 'save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getBodyPartIcon(BodyPartEnum bodyPart) {
    switch (bodyPart) {
      case BodyPartEnum.head:
        return Icons.face;
      case BodyPartEnum.chest:
        return Icons.accessibility_new;
      case BodyPartEnum.leftHand:
      case BodyPartEnum.rightHand:
        return Icons.front_hand;
      case BodyPartEnum.leftLeg:
      case BodyPartEnum.rightLeg:
        return Icons.directions_walk;
    }
  }

  String _getBodyPartTranslation({required BodyPartEnum bodyPart}) {
    switch (bodyPart) {
      case BodyPartEnum.head:
        return MyLocalizations.of(context, 'bite_report_bodypart_head');
      case BodyPartEnum.chest:
        return MyLocalizations.of(context, 'question_2_answer_24');
      case BodyPartEnum.leftHand:
        return MyLocalizations.of(context, 'bite_report_bodypart_leftarm');
      case BodyPartEnum.rightHand:
        return MyLocalizations.of(context, 'bite_report_bodypart_rightarm');
      case BodyPartEnum.leftLeg:
        return MyLocalizations.of(context, 'bite_report_bodypart_leftleg');
      case BodyPartEnum.rightLeg:
        return MyLocalizations.of(context, 'bite_report_bodypart_rightleg');
    }
  }
}
