import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/core/utils/style.dart';

class NotificationBanner extends StatelessWidget {
  final String? title;
  final String? message;
  final GestureTapCallback? onTap;

  const NotificationBanner({
    Key? key,
    required this.title,
    required this.message,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: GestureDetector(
          onTap: onTap,
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            elevation: 10,
            child: Container(
              padding: EdgeInsets.all(12),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    children: [
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 6),
                            Style.body(title, maxLines: 1),
                            SizedBox(height: 2),
                            Style.bodySmall(message, maxLines: 2),
                            SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
