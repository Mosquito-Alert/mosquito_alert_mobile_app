import 'package:flutter/material.dart';
import 'package:mosquito_alert_app/utils/MyLocalizations.dart';
import 'package:mosquito_alert_app/utils/style.dart';

class SmallQuestionOption extends StatelessWidget {
  final bool? selected, disabled;
  final String? text;
  SmallQuestionOption(
    this.text, {
    this.selected,
    this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return selected == null || !selected!
        ? Opacity(
            opacity: disabled == null || !disabled! ? 1.0 : 0.5,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 2,
                    )
                  ]),
              child: Style.body(MyLocalizations.of(context, text),
                  maxLines: 2, textAlign: TextAlign.center),
            ),
          )
        : Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Style.colorPrimary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: Style.body(MyLocalizations.of(context, text),
                      color: Colors.white,
                      maxLines: 3,
                      textAlign: TextAlign.center),
                ),
              ],
            ),
          );
  }
}
