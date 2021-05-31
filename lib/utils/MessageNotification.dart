import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'style.dart';

class MessageNotification extends StatelessWidget {
  final String title;
  final String message;
  final GestureTapCallback onTap;

  const MessageNotification(
      {Key key, @required this.title, @required this.message, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        child: GestureDetector(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            elevation: 10,
            child: Container(
              padding: EdgeInsets.all(12),
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 6,
                            ),
                            Style.body(title, maxLines: 1),
                            SizedBox(
                              height: 2,
                            ),
                            Style.bodySmall(message, maxLines: 2),
                            SizedBox(
                              height: 6,
                            ),
                          ],
                        ),
                      )
                    ],
                  )
                ],
              ),
              decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Theme.of(context).backgroundColor, width: 0.5)),
            ),
          ),
          onTap: onTap,
        ),
        padding: EdgeInsets.all(8),
      ),
    );
  }
}
